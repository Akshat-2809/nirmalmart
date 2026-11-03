"""Returns and exchanges, Amazon-style: within RETURN_WINDOW_DAYS of delivery the customer asks to return
(refund of the items, not the delivery charge) or exchange (the same item again, for a wrong size or a defect).
Shiprocket collects the parcel from the customer; the admin refunds by UPI or ships the replacement."""
from datetime import datetime, timedelta, timezone
from typing import Optional
from fastapi import HTTPException, status
from sqlalchemy.orm import Session
from app.models.order import Order
from app.models.return_request import ReturnRequest, RETURN_WINDOW_DAYS
from app.schemas.order import ReturnCreate
from app.services import shiprocket
from app.services.pricing import to_money

CUSTOMER_CANCELLABLE = {"requested", "approved", "pickup_scheduled"}


def return_deadline(order: Order) -> Optional[datetime]:
    if order.status != "delivered":
        return None
    delivered = order.delivered_at or order.updated_at   # orders delivered before delivery dates were kept
    if delivered.tzinfo is None:
        delivered = delivered.replace(tzinfo=timezone.utc)
    return delivered + timedelta(days=RETURN_WINDOW_DAYS)


def _already_requested(order: Order) -> dict:
    """Units per order item that are in a return/exchange that isn't rejected or cancelled"""
    taken = {}
    for r in order.returns:
        if r.status in ("rejected", "cancelled"):
            continue
        for x in r.items:
            taken[x["order_item_id"]] = taken.get(x["order_item_id"], 0) + x["quantity"]
    return taken


def create_return(db: Session, order: Order, body: ReturnCreate) -> ReturnRequest:
    deadline = return_deadline(order)
    if not deadline:
        raise HTTPException(status.HTTP_400_BAD_REQUEST, "Only delivered orders can be returned or exchanged")
    if datetime.now(timezone.utc) > deadline:
        raise HTTPException(status.HTTP_400_BAD_REQUEST, f"The {RETURN_WINDOW_DAYS}-day return window for this order has closed")
    by_id = {i.id: i for i in order.items}
    taken = _already_requested(order)
    lines, seen = [], set()
    for x in body.items:
        item = by_id.get(x.order_item_id)
        if not item or x.order_item_id in seen:
            raise HTTPException(status.HTTP_400_BAD_REQUEST, "Choose items from this order")
        seen.add(x.order_item_id)
        left = item.quantity - taken.get(item.id, 0)
        if x.quantity > left:
            raise HTTPException(status.HTTP_400_BAD_REQUEST,
                                f"Only {left} of {item.product_name} can still be returned" if left else f"{item.product_name} already has a return request")
        lines.append({"order_item_id": item.id, "product_name": item.product_name, "product_image": item.product_image,
                      "quantity": x.quantity, "unit_price": float(item.unit_price)})
    ret = ReturnRequest(
        order_id=order.id, kind=body.kind, items=lines, reason=body.reason.strip(),
        comment=(body.comment or "").strip() or None, status="requested",
        refund_amount=to_money(sum(l["unit_price"] * l["quantity"] for l in lines)) if body.kind == "return" else None,
    )
    db.add(ret)
    db.commit()
    return ret


def _get(db: Session, return_id: int, order_id: int) -> ReturnRequest:
    ret = db.query(ReturnRequest).filter(ReturnRequest.id == return_id, ReturnRequest.order_id == order_id).first()
    if not ret:
        raise HTTPException(status.HTTP_404_NOT_FOUND, "Return request not found")
    return ret


def cancel_by_customer(db: Session, order: Order, return_id: int) -> None:
    ret = _get(db, return_id, order.id)
    if ret.status not in CUSTOMER_CANCELLABLE:
        raise HTTPException(status.HTTP_400_BAD_REQUEST, "This request can no longer be cancelled; the courier already has the parcel")
    try:
        shiprocket.cancel_return_pickup(db, ret)
    except shiprocket.ShiprocketError:
        raise HTTPException(status.HTTP_400_BAD_REQUEST, "We couldn't cancel the courier pickup just now. Please try again in a few minutes.")
    ret.status = "cancelled"
    db.commit()


def _require(ret: ReturnRequest, allowed: set, action: str):
    if ret.status not in allowed:
        raise HTTPException(status.HTTP_400_BAD_REQUEST, f"Can't {action} a request that is {ret.status.replace('_', ' ')}")


def approve(db: Session, order: Order, return_id: int, pkg: dict) -> None:
    """Approve and book the Shiprocket reverse pickup (retrying is safe if a step failed)."""
    ret = _get(db, return_id, order.id)
    _require(ret, {"requested", "approved"}, "approve")
    if ret.status == "requested":
        ret.status = "approved"
        ret.approved_at = datetime.now(timezone.utc)
        db.commit()
    shiprocket.book_return_pickup(db, order, ret, pkg)


def reject(db: Session, order: Order, return_id: int, note: Optional[str]) -> None:
    ret = _get(db, return_id, order.id)
    _require(ret, {"requested", "approved", "pickup_scheduled"}, "reject")
    try:
        shiprocket.cancel_return_pickup(db, ret)
    except shiprocket.ShiprocketError as e:
        raise HTTPException(status.HTTP_502_BAD_GATEWAY, f"Couldn't cancel the return pickup in Shiprocket: {e}")
    ret.status = "rejected"
    ret.admin_note = (note or "").strip()[:300] or None
    db.commit()


def mark(db: Session, order: Order, return_id: int, new_status: str) -> None:
    """Manual progress, for when the courier's update hasn't arrived"""
    ret = _get(db, return_id, order.id)
    now = datetime.now(timezone.utc)
    if new_status == "picked_up":
        _require(ret, {"approved", "pickup_scheduled"}, "mark picked up")
        ret.picked_up_at = now
    else:
        _require(ret, {"approved", "pickup_scheduled", "picked_up"}, "mark received")
        ret.picked_up_at = ret.picked_up_at or now
        ret.received_at = now
    ret.status = new_status
    db.commit()


def refund(db: Session, order: Order, return_id: int, reference: Optional[str]) -> None:
    ret = _get(db, return_id, order.id)
    if ret.kind != "return":
        raise HTTPException(status.HTTP_400_BAD_REQUEST, "Exchanges are completed by shipping the replacement")
    _require(ret, {"picked_up", "received"}, "refund")
    ret.refund_reference = (reference or "").strip()[:100] or None
    ret.status = "completed"
    ret.completed_at = datetime.now(timezone.utc)
    db.commit()


def send_replacement(db: Session, order: Order, return_id: int, pkg: dict) -> None:
    ret = _get(db, return_id, order.id)
    if ret.kind != "exchange":
        raise HTTPException(status.HTTP_400_BAD_REQUEST, "Returns are completed by sending the refund")
    _require(ret, {"picked_up", "received"}, "ship a replacement for")
    shiprocket.ship_replacement(db, order, ret, pkg)
    ret.status = "completed"
    ret.completed_at = datetime.now(timezone.utc)
    db.commit()


def refresh(db: Session, order: Order, return_id: int) -> None:
    shiprocket.refresh_return_tracking(db, _get(db, return_id, order.id))

