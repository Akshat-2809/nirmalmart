from datetime import datetime, timezone

from sqlalchemy import Boolean, Column, DateTime, ForeignKey, Integer, String

from app.database import Base


class Device(Base):
    """A phone with the app installed that can get push notifications (Firebase token).
    user_id is set while someone is signed in on it, so order updates reach only their own phones."""
    __tablename__ = "devices"

    id = Column(Integer, primary_key=True, autoincrement=True)
    token = Column(String(400), unique=True, nullable=False)
    user_id = Column(Integer, ForeignKey("users.id", ondelete="SET NULL"), nullable=True, index=True)
    platform = Column(String(10), nullable=False, default="android")
    lang = Column(String(5), nullable=False, default="en")
    orders = Column(Boolean, nullable=False, default=True)   # order and return updates
    offers = Column(Boolean, nullable=False, default=True)   # offer notifications from the admin panel
    created_at = Column(DateTime(timezone=True), default=lambda: datetime.now(timezone.utc))
    updated_at = Column(DateTime(timezone=True), default=lambda: datetime.now(timezone.utc))
