from sqlalchemy import Column, Integer, String, Numeric, Text, DateTime, ForeignKey, JSON
from sqlalchemy.orm import relationship
from datetime import datetime, timezone
from app.database import Base

RETURN_WINDOW_DAYS = 5
RETURN_KINDS = ["return", "exchange"]   # exchange = the same item again (wrong size or defective)
# requested → approved (Shiprocket return order created) → pickup_scheduled (courier assigned) → picked_up
# → received (back at the store) → completed (refund sent / replacement shipped); or rejected / cancelled
RETURN_STATUSES = ["requested", "approved", "pickup_scheduled", "picked_up", "received", "completed", "rejected", "cancelled"]
OPEN_RETURN_STATUSES = ["requested", "approved", "pickup_scheduled", "picked_up", "received"]


class ReturnRequest(Base):
    __tablename__ = "return_requests"

    id = Column(Integer, primary_key=True, index=True, autoincrement=True)
    order_id = Column(Integer, ForeignKey("orders.id", ondelete="CASCADE"), nullable=False, index=True)
    kind = Column(String(20), nullable=False)
    items = Column(JSON, nullable=False)          # [{order_item_id, product_name, quantity, unit_price}]
    reason = Column(String(100), nullable=False)
    comment = Column(Text, nullable=True)
    status = Column(String(20), default="requested", nullable=False, index=True)
    admin_note = Column(String(300), nullable=True)   # e.g. why it was rejected
    refund_amount = Column(Numeric(12, 2), nullable=True)   # items only; the delivery charge isn't refunded
    refund_reference = Column(String(100), nullable=True)
    # Reverse pickup from the customer (Shiprocket return order)
    return_sr_order_id = Column(String(30), nullable=True)
    return_shipment_id = Column(String(30), nullable=True)
    return_awb = Column(String(40), nullable=True, index=True)
    return_courier = Column(String(100), nullable=True)
    return_tracking = Column(String(60), nullable=True)
    # Replacement sent for an exchange
    repl_sr_order_id = Column(String(30), nullable=True)
    repl_shipment_id = Column(String(30), nullable=True)
    repl_awb = Column(String(40), nullable=True, index=True)
    repl_courier = Column(String(100), nullable=True)
    repl_label_url = Column(String(512), nullable=True)
    repl_tracking = Column(String(60), nullable=True)
    created_at = Column(DateTime(timezone=True), default=lambda: datetime.now(timezone.utc))
    updated_at = Column(DateTime(timezone=True), default=lambda: datetime.now(timezone.utc), onupdate=lambda: datetime.now(timezone.utc))
    approved_at = Column(DateTime(timezone=True), nullable=True)
    picked_up_at = Column(DateTime(timezone=True), nullable=True)
    received_at = Column(DateTime(timezone=True), nullable=True)
    completed_at = Column(DateTime(timezone=True), nullable=True)

    order = relationship("Order", back_populates="returns")
