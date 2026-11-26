"""Sending email through Resend (https://resend.com/docs/api-reference).

Nothing here may break a customer action: every send catches its own errors and logs them.
Without RESEND_API_KEY, emails are logged and skipped (local development, tests).
"""
import logging
from typing import Optional

import httpx

from app.config import settings

log = logging.getLogger("nirmalmart.email")
API = "https://api.resend.com"


def enabled() -> bool:
    return bool(settings.RESEND_API_KEY)


def _payload(to: str, subject: str, html: str, text: str, sender: Optional[str], headers: Optional[dict]) -> dict:
    body = {
        "from": sender or settings.EMAIL_FROM,
        "to": [to],
        "subject": subject,
        "html": html,
        "text": text,
        "reply_to": settings.EMAIL_REPLY_TO,
    }
    if headers:
        body["headers"] = headers
    return body


def send(to: str, subject: str, html: str, text: str, sender: Optional[str] = None, headers: Optional[dict] = None) -> bool:
    """One email. Returns True if Resend accepted it."""
    if not enabled():
        log.info("email skipped (no RESEND_API_KEY): %s → %s", subject, to)
        return False
    try:
        r = httpx.post(f"{API}/emails", json=_payload(to, subject, html, text, sender, headers),
                       headers={"Authorization": f"Bearer {settings.RESEND_API_KEY}"}, timeout=20)
        if r.status_code >= 300:
            log.warning("email to %s failed: %s %s", to, r.status_code, r.text[:300])
            return False
        return True
    except Exception as e:  # network, timeout…
        log.warning("email to %s failed: %s", to, e)
        return False


def send_batch(messages: list[dict]) -> tuple[int, Optional[str]]:
    """Up to 100 emails in one call (Resend batch). Each item: to, subject, html, text, sender, headers.
    Returns (how many were accepted, error message or None)."""
    if not messages:
        return 0, None
    if not enabled():
        log.info("batch of %d skipped (no RESEND_API_KEY)", len(messages))
        return 0, "Email sending isn’t set up (RESEND_API_KEY missing)"
    body = [_payload(m["to"], m["subject"], m["html"], m["text"], m.get("sender"), m.get("headers")) for m in messages]
    try:
        r = httpx.post(f"{API}/emails/batch", json=body,
                       headers={"Authorization": f"Bearer {settings.RESEND_API_KEY}"}, timeout=60)
        if r.status_code >= 300:
            msg = r.json().get("message") if r.headers.get("content-type", "").startswith("application/json") else r.text
            log.warning("batch failed: %s %s", r.status_code, str(msg)[:300])
            return 0, str(msg)[:300] or f"Resend error {r.status_code}"
        return len(body), None
    except Exception as e:
        log.warning("batch failed: %s", e)
        return 0, str(e)
