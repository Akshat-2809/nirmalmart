"""Offers by email: the website footer's sign-up box, unsubscribe links, and the admin list."""
import csv
import io
import secrets
import time
from collections import defaultdict, deque
from datetime import datetime, timezone
from typing import Literal

from fastapi import APIRouter, Depends, HTTPException, Request, status
from fastapi.responses import StreamingResponse
from pydantic import BaseModel, EmailStr
from sqlalchemy.orm import Session

from app.database import get_db
from app.models.subscriber import Subscriber
from app.services.auth import require_admin

router = APIRouter(prefix="/api/newsletter", tags=["Newsletter"])
admin_router = APIRouter(prefix="/api/admin/subscribers", tags=["Admin"], dependencies=[Depends(require_admin)])


class SubscribeIn(BaseModel):
    email: EmailStr
    source: Literal["website", "app"] = "website"


class UnsubscribeIn(BaseModel):
    token: str


# A few sign-ups per address per 10 minutes is plenty for a person; this stops bots filling the list.
# In memory is fine: the API runs as a single instance.
_WINDOW, _MAX = 600, 5
_hits: dict = defaultdict(deque)


def _client_ip(request: Request) -> str:
    fwd = request.headers.get("x-forwarded-for")
    return fwd.split(",")[0].strip() if fwd else (request.client.host if request.client else "?")


def _too_many(ip: str) -> bool:
    now = time.monotonic()
    q = _hits[ip]
    while q and now - q[0] > _WINDOW:
        q.popleft()
    if len(q) >= _MAX:
        return True
    q.append(now)
    return False


@router.post("/subscribe")
def subscribe(body: SubscribeIn, request: Request, db: Session = Depends(get_db)):
    if _too_many(_client_ip(request)):
        raise HTTPException(status.HTTP_429_TOO_MANY_REQUESTS, "Too many attempts — please try again in a few minutes")
    email = body.email.strip().lower()
    sub = db.query(Subscriber).filter(Subscriber.email == email).first()
    if sub and sub.unsubscribed_at is None:
        return {"status": "already", "message": "You’re already subscribed"}
    if sub:  # coming back after unsubscribing
        sub.unsubscribed_at = None
        sub.source = body.source
    else:
        db.add(Subscriber(email=email, source=body.source, token=secrets.token_urlsafe(32)))
    db.commit()
    return {"status": "subscribed", "message": "You’re subscribed! We’ll send you offers and new arrivals."}


@router.post("/unsubscribe")
def unsubscribe(body: UnsubscribeIn, db: Session = Depends(get_db)):
    sub = db.query(Subscriber).filter(Subscriber.token == body.token).first()
    if not sub:
        raise HTTPException(status.HTTP_404_NOT_FOUND, "This unsubscribe link isn’t valid")
    if sub.unsubscribed_at is None:
        sub.unsubscribed_at = datetime.now(timezone.utc)
        db.commit()
    return {"status": "unsubscribed", "email": sub.email}


def _rows(db: Session, include_unsubscribed: bool):
    q = db.query(Subscriber)
    if not include_unsubscribed:
        q = q.filter(Subscriber.unsubscribed_at.is_(None))
    return q.order_by(Subscriber.created_at.desc()).all()


@admin_router.get("")
def list_subscribers(include_unsubscribed: bool = False, db: Session = Depends(get_db)):
    rows = _rows(db, include_unsubscribed)
    active = db.query(Subscriber).filter(Subscriber.unsubscribed_at.is_(None)).count()
    return {
        "active": active,
        "unsubscribed": db.query(Subscriber).count() - active,
        "items": [{"id": s.id, "email": s.email, "source": s.source, "created_at": s.created_at,
                   "unsubscribed_at": s.unsubscribed_at} for s in rows],
    }


@admin_router.get("/export")
def export_subscribers(db: Session = Depends(get_db)):
    """CSV of active subscribers, ready to import into an email tool (Brevo, Mailchimp…).
    The unsubscribe link column goes into each email so people can leave the list."""
    buf = io.StringIO()
    w = csv.writer(buf)
    w.writerow(["email", "subscribed_on", "source", "unsubscribe_link"])
    for s in _rows(db, include_unsubscribed=False):
        w.writerow([s.email, s.created_at.date().isoformat() if s.created_at else "", s.source,
                    f"https://www.nirmalmart.in/unsubscribe?token={s.token}"])
    name = f"nirmalmart-subscribers-{datetime.now(timezone.utc).date().isoformat()}.csv"
    return StreamingResponse(iter([buf.getvalue()]), media_type="text/csv",
                             headers={"Content-Disposition": f'attachment; filename="{name}"'})
