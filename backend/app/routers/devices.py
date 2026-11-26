"""The app registers its push-notification token here (signed in or not), with the person's
choices from Settings → Notifications. Signing out re-registers without a login, so order
updates stop reaching that phone."""
from datetime import datetime, timezone
from typing import Literal, Optional

from fastapi import APIRouter, Depends
from pydantic import BaseModel, Field
from sqlalchemy.orm import Session

from app.database import get_db
from app.models.device import Device
from app.models.user import User
from app.services.auth import get_optional_user

router = APIRouter(prefix="/api/devices", tags=["Notifications"])


class DeviceIn(BaseModel):
    token: str = Field(..., min_length=20, max_length=400)
    platform: Literal["android", "ios"] = "android"
    lang: Literal["en", "mr"] = "en"
    orders: bool = True
    offers: bool = True


class TokenIn(BaseModel):
    token: str = Field(..., min_length=20, max_length=400)


@router.post("")
def register(body: DeviceIn, db: Session = Depends(get_db), user: Optional[User] = Depends(get_optional_user)):
    d = db.query(Device).filter(Device.token == body.token).first()
    if not d:
        d = Device(token=body.token)
        db.add(d)
    d.user_id = user.id if user else None
    d.platform, d.lang, d.orders, d.offers = body.platform, body.lang, body.orders, body.offers
    d.updated_at = datetime.now(timezone.utc)
    db.commit()
    return {"ok": True}


@router.post("/remove")
def remove(body: TokenIn, db: Session = Depends(get_db)):
    db.query(Device).filter(Device.token == body.token).delete(synchronize_session=False)
    db.commit()
    return {"ok": True}
