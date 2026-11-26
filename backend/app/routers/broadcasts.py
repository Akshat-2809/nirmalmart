"""Offer emails to subscribers, written and sent from the admin panel."""
import threading
from datetime import datetime, timezone
from typing import Optional

from fastapi import APIRouter, Depends, HTTPException, status
from pydantic import BaseModel, EmailStr, Field, HttpUrl
from sqlalchemy.orm import Session

from app.config import settings
from app.database import get_db
from app.models.broadcast import Broadcast
from app.models.subscriber import Subscriber
from app.services import email, email_templates as tpl
from app.services.auth import require_admin

router = APIRouter(prefix="/api/admin/broadcasts", tags=["Admin"], dependencies=[Depends(require_admin)])

# True in tests: send straight away instead of on a thread
RUN_INLINE = False
BATCH = 100  # Resend's batch limit


class BroadcastIn(BaseModel):
    subject: str = Field(..., min_length=3, max_length=150)
    heading: Optional[str] = Field(None, max_length=150)
    message: str = Field(..., min_length=3, max_length=5000)
    button_text: Optional[str] = Field(None, max_length=40)
    button_url: Optional[HttpUrl] = None


class TestIn(BroadcastIn):
    to: EmailStr


def _unsub_url(token: str) -> str:
    return f"{settings.SITE_URL}/unsubscribe?token={token}"


def _message(b: BroadcastIn, unsub: str) -> tuple:
    return tpl.broadcast(b.subject, b.heading or b.subject, b.message, b.button_text, str(b.button_url) if b.button_url else None, unsub)


def _row(b: Broadcast) -> dict:
    return {k: getattr(b, k) for k in ("id", "subject", "heading", "message", "button_text", "button_url", "status",
                                       "recipients", "sent", "error", "created_at", "finished_at")}


@router.get("")
def history(db: Session = Depends(get_db)):
    active = db.query(Subscriber).filter(Subscriber.unsubscribed_at.is_(None)).count()
    rows = db.query(Broadcast).order_by(Broadcast.created_at.desc()).limit(50).all()
    return {"subscribers": active, "email_ready": email.enabled(), "items": [_row(b) for b in rows]}


@router.post("/preview")
def preview(body: BroadcastIn):
    subject, html, _ = _message(body, _unsub_url("preview"))
    return {"subject": subject, "html": html}


@router.post("/test")
def send_test(body: TestIn):
    if not email.enabled():
        raise HTTPException(status.HTTP_400_BAD_REQUEST, "Email sending isn’t set up yet (RESEND_API_KEY)")
    subject, html, text = _message(body, _unsub_url("test"))
    if not email.send(body.to, f"[Test] {subject}", html, text, sender=settings.EMAIL_PROMO_FROM):
        raise HTTPException(status.HTTP_502_BAD_GATEWAY, "Resend didn’t accept the email — check the domain is verified")
    return {"message": f"Test sent to {body.to}"}


@router.post("", status_code=status.HTTP_202_ACCEPTED)
def send_to_all(body: BroadcastIn, db: Session = Depends(get_db)):
    if not email.enabled():
        raise HTTPException(status.HTTP_400_BAD_REQUEST, "Email sending isn’t set up yet (RESEND_API_KEY)")
    subs = db.query(Subscriber).filter(Subscriber.unsubscribed_at.is_(None)).all()
    if not subs:
        raise HTTPException(status.HTTP_400_BAD_REQUEST, "There are no subscribers yet")
    b = Broadcast(subject=body.subject, heading=body.heading, message=body.message, button_text=body.button_text,
                  button_url=str(body.button_url) if body.button_url else None, recipients=len(subs))
    db.add(b)
    db.commit()
    people = [(s.email, s.token) for s in subs]
    if RUN_INLINE:
        _send(b.id, body, people)
    else:
        threading.Thread(target=_send, args=(b.id, body, people), daemon=True).start()
    db.refresh(b)
    return _row(b)


def _send(broadcast_id: int, body: BroadcastIn, people: list) -> None:
    from app.database import SessionLocal
    sent, error = 0, None
    for i in range(0, len(people), BATCH):
        batch = []
        for address, token in people[i:i + BATCH]:
            subject, html, text = _message(body, _unsub_url(token))
            batch.append({"to": address, "subject": subject, "html": html, "text": text, "sender": settings.EMAIL_PROMO_FROM,
                          # lets Gmail and others show their own "Unsubscribe" button
                          "headers": {"List-Unsubscribe": f"<{_unsub_url(token)}>"}})
        ok, err = email.send_batch(batch)
        sent += ok
        if err:
            error = err
            break  # e.g. the daily limit: stop, keep the count
    db = SessionLocal()
    try:
        b = db.get(Broadcast, broadcast_id)
        b.sent = sent
        b.error = error
        b.status = "sent" if sent == len(people) else ("partial" if sent else "failed")
        b.finished_at = datetime.now(timezone.utc)
        db.commit()
    finally:
        db.close()
