from sqlalchemy import Column, String, JSON
from app.database import Base


class StoreSetting(Base):
    """Small store-wide switches the owner controls from the admin panel (key → JSON value)."""
    __tablename__ = "store_settings"

    key = Column(String(64), primary_key=True)
    value = Column(JSON, nullable=False)
