from datetime import datetime, timezone

from sqlalchemy import Column, DateTime, Integer, String, Text

from app.database import Base


class Broadcast(Base):
    """An offer email sent to subscribers from the admin panel (kept as a history)."""
    __tablename__ = "broadcasts"

    id = Column(Integer, primary_key=True, autoincrement=True)
    subject = Column(String(150), nullable=False)
    heading = Column(String(150), nullable=True)
    message = Column(Text, nullable=False)
    button_text = Column(String(40), nullable=True)
    button_url = Column(String(500), nullable=True)
    status = Column(String(20), nullable=False, default="sending")  # sending, sent, partial, failed
    recipients = Column(Integer, nullable=False, default=0)
    sent = Column(Integer, nullable=False, default=0)
    error = Column(String(300), nullable=True)
    created_at = Column(DateTime(timezone=True), default=lambda: datetime.now(timezone.utc))
    finished_at = Column(DateTime(timezone=True), nullable=True)
