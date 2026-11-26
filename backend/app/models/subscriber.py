from datetime import datetime, timezone

from sqlalchemy import Column, DateTime, Integer, String

from app.database import Base


class Subscriber(Base):
    """Someone who asked for offers by email (website footer). Unsubscribing keeps the row, marked."""
    __tablename__ = "newsletter_subscribers"

    id = Column(Integer, primary_key=True, autoincrement=True)
    email = Column(String(255), unique=True, index=True, nullable=False)
    source = Column(String(30), nullable=False, default="website")  # where they signed up
    token = Column(String(64), unique=True, nullable=False)  # for the unsubscribe link in each email
    created_at = Column(DateTime(timezone=True), default=lambda: datetime.now(timezone.utc))
    unsubscribed_at = Column(DateTime(timezone=True), nullable=True)
