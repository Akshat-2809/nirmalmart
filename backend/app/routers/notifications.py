"""Offer notifications to app users, written and sent from the admin panel."""
import threading
from datetime import datetime, timezone
from typing import Optional
from urllib.parse import urlsplit

from fastapi import APIRouter, Depends, HTTPException, status
from pydantic import BaseModel, EmailStr, Field, field_validator
from sqlalchemy.orm import Session

from app.database import get_db
from app.models.device import Device
from app.models.push_broadcast import PushBroadcast
from app.models.user import User
from app.services import push
from app.services.auth import require_admin

router = APIRouter(prefix="/api/admin/notifications", tags=["Admin"], dependencies=[Depends(require_admin)])

# True in tests: send straight away instead of on a thread
RUN_INLINE = False

# app pages a notification may open (same paths as the website)
_PAGES = ("/shop", "/product/", "/search", "/wishlist", "/bag", "/help/")


def app_route(link: Optional[str]) -> Optional[str]:
    """A website link (https://www.nirmalmart.in/product/x) or path (/shop?category=y) → the app page.
    Raises ValueError for anything the app can't open."""
    link = (link or "").strip()
    if not link:
        return None
    if not link.startswith("/"):
        u = urlsplit(link if "://" in link else f"https://{link}")
        if u.hostname not in ("nirmalmart.in", "www.nirmalmart.in", "nirmalmart.vercel.app"):
            raise ValueError("Use a link from nirmalmart.in (a product, category or search page)")
        link = (u.path or "/") + (f"?{u.query}" if u.query else "")
    if link.startswith("//"):
        raise ValueError("That link can’t be opened in the app")
    if link in ("/", "") or link.startswith(_PAGES):
        return link
    raise ValueError("The app can open the home page, shop, a category, a product, search, the wishlist or the bag")


class NotificationIn(BaseModel):
    title: str = Field(..., min_length=3, max_length=65)
    body: str = Field(..., min_length=3, max_length=240)
    link: Optional[str] = Field(None, max_length=300)

    @field_validator("link")
    @classmethod
    def _link(cls, v):
        return app_route(v)


class TestIn(NotificationIn):
    to: Optional[EmailStr] = None  # whose phones; empty = the admin's own


def _row(b: PushBroadcast) -> dict:
    return {k: getattr(b, k) for k in ("id", "title", "body", "link", "status", "recipients", "sent", "error",
                                       "created_at", "finished_at")}


@router.get("")
def history(db: Session = Depends(get_db), admin: User = Depends(require_admin)):
    rows = db.query(PushBroadcast).order_by(PushBroadcast.created_at.desc()).limit(50).all()
    return {
        "ready": push.enabled(),
        "devices": db.query(Device).filter(Device.offers.is_(True)).count(),
        "all_devices": db.query(Device).count(),
        "my_devices": db.query(Device).filter(Device.user_id == admin.id).count(),
        "items": [_row(b) for b in rows],
    }


@router.post("/test")
def send_test(body: TestIn, db: Session = Depends(get_db), admin: User = Depends(require_admin)):
    if not push.enabled():
        raise HTTPException(status.HTTP_400_BAD_REQUEST, "Notifications aren’t set up yet (FIREBASE_SERVICE_ACCOUNT)")
    user = admin
    if body.to:
        user = db.query(User).filter(User.email == body.to.lower()).first()
        if not user:
            raise HTTPException(status.HTTP_404_NOT_FOUND, "No account with that email")
    tokens = [d.token for d in db.query(Device).filter(Device.user_id == user.id).all()]
    if not tokens:
        raise HTTPException(status.HTTP_400_BAD_REQUEST,
                            f"No phone is signed in to {user.email} in the app yet — sign in on the app first")
    sent, err = push.send_many(tokens, body.title, body.body, body.link, channel=push.OFFERS_CHANNEL)
    if not sent:
        raise HTTPException(status.HTTP_502_BAD_GATEWAY, f"Firebase didn’t accept it: {err or 'unknown error'}")
    return {"message": f"Test sent to {sent} phone{'s' if sent != 1 else ''} of {user.email}"}


@router.post("", status_code=status.HTTP_202_ACCEPTED)
def send_to_all(body: NotificationIn, db: Session = Depends(get_db)):
    if not push.enabled():
        raise HTTPException(status.HTTP_400_BAD_REQUEST, "Notifications aren’t set up yet (FIREBASE_SERVICE_ACCOUNT)")
    tokens = [t for (t,) in db.query(Device.token).filter(Device.offers.is_(True)).all()]
    if not tokens:
        raise HTTPException(status.HTTP_400_BAD_REQUEST, "No app users have offers turned on yet")
    b = PushBroadcast(title=body.title, body=body.body, link=body.link, recipients=len(tokens))
    db.add(b)
    db.commit()
    if RUN_INLINE:
        _send(b.id, body, tokens)
    else:
        threading.Thread(target=_send, args=(b.id, body, tokens), daemon=True).start()
    db.refresh(b)
    return _row(b)


def _send(broadcast_id: int, body: NotificationIn, tokens: list) -> None:
    from app.database import SessionLocal
    sent, error = 0, None
    for i in range(0, len(tokens), 200):
        ok, err = push.send_many(tokens[i:i + 200], body.title, body.body, body.link, channel=push.OFFERS_CHANNEL)
        sent += ok
        error = err or error
    db = SessionLocal()
    try:
        b = db.get(PushBroadcast, broadcast_id)
        b.sent, b.error = sent, error
        b.status = "sent" if sent == len(tokens) else ("partial" if sent else "failed")
        b.finished_at = datetime.now(timezone.utc)
        db.commit()
    finally:
        db.close()
