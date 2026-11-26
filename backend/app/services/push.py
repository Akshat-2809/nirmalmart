"""Push notifications to the app through Firebase Cloud Messaging (HTTP v1 API).

The service-account JSON (Render env FIREBASE_SERVICE_ACCOUNT) signs a short-lived Google access
token; each phone gets its own request. Phones that uninstalled the app are forgotten automatically.
Without the setting nothing is sent and the shop works as before.
"""
import json
import logging
import threading
import time
from concurrent.futures import ThreadPoolExecutor
from typing import Iterable, Optional

import httpx
from jose import jwt

from app.config import settings

log = logging.getLogger("nirmalmart.push")
SCOPE = "https://www.googleapis.com/auth/firebase.messaging"

# Android notification channels (created by the app): order updates ring, offers are quieter
ORDERS_CHANNEL = "orders"
OFFERS_CHANNEL = "offers"

_lock = threading.Lock()
_cached = {"token": None, "exp": 0.0}


def _account() -> Optional[dict]:
    raw = (settings.FIREBASE_SERVICE_ACCOUNT or "").strip()
    if not raw:
        return None
    try:
        acc = json.loads(raw)
        return acc if acc.get("private_key") and acc.get("client_email") and acc.get("project_id") else None
    except ValueError:
        log.error("FIREBASE_SERVICE_ACCOUNT is not valid JSON")
        return None


def enabled() -> bool:
    return _account() is not None


def _access_token(acc: dict) -> str:
    with _lock:
        if _cached["token"] and _cached["exp"] - 120 > time.time():
            return _cached["token"]
        now = int(time.time())
        token_uri = acc.get("token_uri", "https://oauth2.googleapis.com/token")
        assertion = jwt.encode({"iss": acc["client_email"], "scope": SCOPE, "aud": token_uri, "iat": now, "exp": now + 3600},
                               acc["private_key"], algorithm="RS256", headers={"kid": acc.get("private_key_id", "")})
        r = httpx.post(token_uri, data={"grant_type": "urn:ietf:params:oauth:grant-type:jwt-bearer", "assertion": assertion},
                       timeout=15)
        r.raise_for_status()
        body = r.json()
        _cached["token"], _cached["exp"] = body["access_token"], now + int(body.get("expires_in", 3600))
        return _cached["token"]


def send(token: str, title: str, body: str, route: Optional[str] = None, channel: str = ORDERS_CHANNEL,
         tag: Optional[str] = None) -> str:
    """'ok', 'gone' (the app was uninstalled: forget this phone) or 'error: …'"""
    acc = _account()
    if not acc:
        log.info("Push skipped (no FIREBASE_SERVICE_ACCOUNT): %s", title)
        return "error: notifications aren’t set up"
    note = {"channel_id": channel}
    if tag:
        note["tag"] = tag  # a newer update for the same order replaces the older one
    message = {
        "token": token,
        "notification": {"title": title, "body": body},
        "data": {"route": route or "/"},
        "android": {"priority": "high" if channel == ORDERS_CHANNEL else "normal", "notification": note},
    }
    try:
        r = httpx.post(f"https://fcm.googleapis.com/v1/projects/{acc['project_id']}/messages:send",
                       headers={"Authorization": f"Bearer {_access_token(acc)}"}, json={"message": message}, timeout=15)
    except Exception as e:  # network trouble: never break the caller
        log.warning("Push failed: %s", e)
        return f"error: {e}"[:300]
    if r.status_code == 200:
        return "ok"
    try:
        err = r.json().get("error", {})
    except ValueError:
        err = {}
    codes = {d.get("errorCode") for d in err.get("details", []) if isinstance(d, dict)}
    msg = err.get("message", r.text[:200])
    if r.status_code == 404 or "UNREGISTERED" in codes or (r.status_code == 400 and "registration token" in msg.lower()):
        return "gone"
    log.warning("Push rejected (%s): %s", r.status_code, msg)
    return f"error: {msg}"[:300]


def send_many(tokens: Iterable[str], title: str, body: str, route: Optional[str] = None,
              channel: str = ORDERS_CHANNEL, tag: Optional[str] = None) -> tuple:
    """Sends to several phones in parallel and forgets uninstalled ones. Returns (sent, last_error)."""
    tokens = list(dict.fromkeys(tokens))
    if not tokens:
        return 0, None
    with ThreadPoolExecutor(max_workers=min(8, len(tokens))) as pool:
        results = list(pool.map(lambda t: (t, send(t, title, body, route, channel, tag)), tokens))
    gone = [t for t, res in results if res == "gone"]
    if gone:
        forget(gone)
    errors = [res for _, res in results if res.startswith("error")]
    return sum(1 for _, res in results if res == "ok"), (errors[-1][7:] if errors else None)


def forget(tokens: list) -> None:
    from app.database import SessionLocal
    from app.models.device import Device
    db = SessionLocal()
    try:
        db.query(Device).filter(Device.token.in_(tokens)).delete(synchronize_session=False)
        db.commit()
    finally:
        db.close()
