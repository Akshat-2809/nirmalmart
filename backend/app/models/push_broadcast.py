from datetime import datetime, timezone

from sqlalchemy import Column, DateTime, Integer, String

from app.database import Base


class PushBroadcast(Base):
    """An offer notification sent to app users from the admin panel (kept as a history)."""
    __tablename__ = "push_broadcasts"

    id = Column(Integer, primary_key=True, autoincrement=True)
    title = Column(String(65), nullable=False)
    body = Column(String(240), nullable=False)
    link = Column(String(300), nullable=True)   # app page to open, e.g. /product/steel-bottle
    status = Column(String(20), nullable=False, default="sending")  # sending, sent, partial, failed
    recipients = Column(Integer, nullable=False, default=0)
    sent = Column(Integer, nullable=False, default=0)
    error = Column(String(300), nullable=True)
    created_at = Column(DateTime(timezone=True), default=lambda: datetime.now(timezone.utc))
    finished_at = Column(DateTime(timezone=True), nullable=True)
