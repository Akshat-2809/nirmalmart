"""Forgot password: a one-time link by email, valid for 1 hour."""
import hashlib
import secrets
import threading
import time
from collections import defaultdict, deque
from datetime import datetime, timedelta, timezone

from fastapi import HTTPException, Request, status
from sqlalchemy.orm import Session

from app.config import settings
from app.models.password_reset import PasswordReset
from app.models.user import User
from app.services import email, email_templates as tpl
from app.services.auth import hash_password

LINK_LIFETIME = timedelta(hours=1)

# True in tests: send straight away instead of on a thread
RUN_INLINE = False

_WINDOW, _MAX = 600, 5   # 5 requests per address per 10 minutes
_hits: dict = defaultdict(deque)


def too_many(request: Request) -> bool:
    fwd = request.headers.get("x-forwarded-for")
    ip = fwd.split(",")[0].strip() if fwd else (request.client.host if request.client else "?")
    now, q = time.monotonic(), _hits[ip]
    while q and now - q[0] > _WINDOW:
        q.popleft()
    if len(q) >= _MAX:
        return True
    q.append(now)
    return False


def _hash(token: str) -> str:
    return hashlib.sha256(token.encode()).hexdigest()


def start_reset(db: Session, address: str) -> None:
    user = db.query(User).filter(User.email == address.strip().lower(), User.is_active.is_(True)).first()
    if not user:
        return  # same answer either way
    # only the newest link works
    db.query(PasswordReset).filter(PasswordReset.user_id == user.id, PasswordReset.used_at.is_(None)).delete()
    token = secrets.token_urlsafe(32)
    db.add(PasswordReset(user_id=user.id, token_hash=_hash(token), expires_at=datetime.now(timezone.utc) + LINK_LIFETIME))
    db.commit()
    subject, html, text = tpl.password_reset(user, f"{settings.SITE_URL}/reset-password?token={token}")
    to = user.email
    if RUN_INLINE:
        email.send(to, subject, html, text)
    else:  # don't make the answer slower for real accounts (it would show which emails exist)
        threading.Thread(target=email.send, args=(to, subject, html, text), daemon=True).start()


def finish_reset(db: Session, token: str, new_password: str) -> None:
    row = db.query(PasswordReset).filter(PasswordReset.token_hash == _hash(token)).first()
    now = datetime.now(timezone.utc)
    expires = row.expires_at if row and row.expires_at.tzinfo else (row.expires_at.replace(tzinfo=timezone.utc) if row else None)
    if not row or row.used_at is not None or expires < now:
        raise HTTPException(status.HTTP_400_BAD_REQUEST, "This reset link has expired or was already used. Please ask for a new one.")
    user = db.get(User, row.user_id)
    if not user or not user.is_active:
        raise HTTPException(status.HTTP_400_BAD_REQUEST, "This reset link is no longer valid")
    user.password_hash = hash_password(new_password)
    row.used_at = now
    db.query(PasswordReset).filter(PasswordReset.user_id == user.id, PasswordReset.id != row.id).delete()
    db.commit()
