import math
import secrets
import string
from datetime import datetime, timezone
from typing import Optional
from sqlalchemy.orm import Session, selectinload, joinedload
from fastapi import HTTPException, status
from app.models.order import Order, OrderItem
from app.models.cart import CartItem
from app.models.product import Product
from app.models.address import Address
from app.models.user import User
from app.schemas.order import OrderCreate
from app.services import shiprocket
from app.services.pricing import to_money, compute_totals

# Which status changes an admin may make
TRANSITIONS = {
    "pending": {"confirmed", "cancelled"},
    "confirmed": {"processing", "shipped", "cancelled"},
    "processing": {"shipped", "cancelled"},
    "shipped": {"delivered"},
    "delivered": set(),
    "cancelled": set(),
}
# Like Amazon, customers can cancel until the courier has the parcel
CUSTOMER_CANCELLABLE = {"pending", "confirmed", "processing"}


def generate_order_number() -> str:
    date_part = datetime.now(timezone.utc).strftime("%y%m%d")
    rand = "".join(secrets.choice(string.ascii_uppercase + string.digits) for _ in range(6))
    return f"NM{date_part}{rand}"


def _resolve_address(db: Session, user: User, order_data: OrderCreate) -> dict:
    if order_data.address_id:
        addr = db.query(Address).filter(Address.id == order_data.address_id, Address.user_id == user.id).first()
        if not addr:
            raise HTTPException(status.HTTP_400_BAD_REQUEST, "Address not found")
        return {
            "full_name": addr.full_name or user.full_name, "phone": addr.phone or user.phone,
            "address_line1": addr.address_line1, "address_line2": addr.address_line2,
            "city": addr.city, "state": addr.state, "postal_code": addr.postal_code, "country": addr.country,
        }
    if order_data.shipping_address:
        return order_data.shipping_address.model_dump()
    raise HTTPException(status.HTTP_400_BAD_REQUEST, "A shipping address is required")


def create_order_from_cart(db: Session, user: User, order_data: OrderCreate) -> Order:
    address = _resolve_address(db, user, order_data)
    cart_items = db.query(CartItem).filter(CartItem.user_id == user.id).all()
    if not cart_items:
        raise HTTPException(status.HTTP_400_BAD_REQUEST, "Your cart is empty")

    # Lock product rows so concurrent checkouts can't oversell
    ids = [c.product_id for c in cart_items]
    products = {p.id: p for p in db.query(Product).options(selectinload(Product.images))
                .filter(Product.id.in_(ids)).with_for_update(of=Product).all()}

    subtotal, lines = to_money(0), []
    for c in cart_items:
        p = products.get(c.product_id)
        if not p or not p.is_active:
            raise HTTPException(status.HTTP_400_BAD_REQUEST, "An item in your cart is no longer available")
        if p.stock_quantity < c.quantity:
            raise HTTPException(status.HTTP_400_BAD_REQUEST,
                                f"Only {p.stock_quantity} of {p.name} left in stock")
        line = to_money(p.price * c.quantity)
        subtotal += line
        lines.append((p, c.quantity, line))

    totals = compute_totals(subtotal)
    order = Order(
        order_number=generate_order_number(), user_id=user.id, status="pending",
        payment_method="upi_qr", payment_status="pending", subtotal_amount=totals["subtotal"], tax_amount=totals["tax_amount"],
        shipping_amount=totals["shipping_amount"], total_amount=totals["total_amount"],
        shipping_address=address, notes=order_data.notes,
    )
    db.add(order)
    db.flush()
    for p, qty, line in lines:
        db.add(OrderItem(order_id=order.id, product_id=p.id, product_name=p.name, product_slug=p.slug,
                         product_image=p.primary_image, quantity=qty, unit_price=p.price, subtotal=line))
        p.stock_quantity -= qty
        p.sold_count += qty

    db.query(CartItem).filter(CartItem.user_id == user.id).delete()
    db.commit()
    return get_order_by_id(db, order.id)


def _drop_unfinished_shipment(db: Session, order: Order):
    """If booking a courier failed after Shiprocket created the order, that order sits there as NEW;
    cancel it too so Shiprocket's list matches ours."""
    if order.shiprocket_order_id and not order.awb_code:
        shiprocket.cancel_shipment(db, order)


def _restock(order: Order):
    for item in order.items:
        if item.product:
            item.product.stock_quantity += item.quantity
            item.product.sold_count = max(0, item.product.sold_count - item.quantity)


def get_user_orders(db: Session, user_id: int) -> list:
    return (db.query(Order).options(selectinload(Order.items))
            .filter(Order.user_id == user_id).order_by(Order.created_at.desc()).all())


def get_order_by_id(db: Session, order_id: int, user_id: Optional[int] = None) -> Optional[Order]:
    q = db.query(Order).options(selectinload(Order.items)).filter(Order.id == order_id)
    if user_id:
        q = q.filter(Order.user_id == user_id)
    return q.first()


def _cancel(db: Session, order: Order, reason: Optional[str] = None) -> None:
    _restock(order)
    order.status = "cancelled"
    order.cancelled_at = datetime.now(timezone.utc)
    order.cancel_reason = (reason or "").strip()[:200] or None
    if order.payment_status == "paid":
        order.payment_status = "refund_pending"
    db.commit()


def cancel_order_by_customer(db: Session, order_id: int, user_id: int, reason: Optional[str] = None) -> Order:
    order = get_order_by_id(db, order_id, user_id)
    if not order:
        raise HTTPException(status.HTTP_404_NOT_FOUND, "Order not found")
    if order.status not in CUSTOMER_CANCELLABLE:
        raise HTTPException(status.HTTP_400_BAD_REQUEST, f"An order that is {order.status} can no longer be cancelled")
    # A booked courier pickup is cancelled with the order; Shiprocket refuses once the parcel is picked up
    try:
        if order.awb_code:
            shiprocket.cancel_shipment(db, order)
        else:
            _drop_unfinished_shipment(db, order)
    except HTTPException:
        raise HTTPException(status.HTTP_400_BAD_REQUEST, "We couldn't stop the courier pickup just now. "
                            "Please try again in a few minutes, or contact us to cancel.")
    _cancel(db, order, reason or "Cancelled by customer")
    return get_order_by_id(db, order_id)


def update_order_status(db: Session, order_id: int, new_status: str) -> Order:
    order = get_order_by_id(db, order_id)
    if not order:
        raise HTTPException(status.HTTP_404_NOT_FOUND, "Order not found")
    if new_status == order.status:
        return order
    if new_status not in TRANSITIONS[order.status]:
        raise HTTPException(status.HTTP_400_BAD_REQUEST, f"Cannot move an order from {order.status} to {new_status}")
    if new_status == "cancelled" and order.awb_code:
        raise HTTPException(status.HTTP_400_BAD_REQUEST, "Cancel the courier shipment first, then cancel the order")
    if new_status == "cancelled":
        _drop_unfinished_shipment(db, order)
        _cancel(db, order, "Cancelled by store")
        return get_order_by_id(db, order_id)
    order.status = new_status
    db.commit()
    return get_order_by_id(db, order_id)


def set_payment_status(db: Session, order_id: int, payment_status: str, refund_reference: Optional[str] = None) -> Order:
    """UPI QR payments and refunds are handled by hand, so the admin records each outcome here."""
    order = get_order_by_id(db, order_id)
    if not order:
        raise HTTPException(status.HTTP_404_NOT_FOUND, "Order not found")
    # Money that arrives for an already-cancelled order is owed back to the customer
    if payment_status == "paid" and order.status == "cancelled":
        payment_status = "refund_pending"
    order.payment_status = payment_status
    if payment_status == "refunded":
        order.refunded_at = datetime.now(timezone.utc)
        order.refund_reference = (refund_reference or "").strip() or None
    else:
        order.refunded_at = order.refund_reference = None
    db.commit()
    return get_order_by_id(db, order_id)


def delete_order(db: Session, order_id: int) -> None:
    """Admins may remove an order (e.g. a test or abandoned one) only while its payment is unconfirmed."""
    order = get_order_by_id(db, order_id)
    if not order:
        raise HTTPException(status.HTTP_404_NOT_FOUND, "Order not found")
    if order.payment_status in ("paid", "refund_pending", "refunded"):
        raise HTTPException(status.HTTP_400_BAD_REQUEST, "Orders with a confirmed payment can't be deleted")
    if order.awb_code:
        raise HTTPException(status.HTTP_400_BAD_REQUEST, "Cancel the courier shipment first, then delete the order")
    _drop_unfinished_shipment(db, order)
    if order.status != "cancelled":   # cancelled orders were already restocked
        _restock(order)
    db.delete(order)
    db.commit()


def _with_customer(order: Order) -> Order:
    order.customer_name = order.user.full_name if order.user else None
    order.customer_email = order.user.email if order.user else None
    return order


def get_all_orders(db: Session, page: int = 1, per_page: int = 20, status_filter: Optional[str] = None,
                   search: Optional[str] = None) -> dict:
    q = db.query(Order).options(selectinload(Order.items), joinedload(Order.user))
    if status_filter:
        q = q.filter(Order.status == status_filter)
    if search:
        term = f"%{search.strip()}%"
        q = q.join(User, Order.user_id == User.id).filter(
            Order.order_number.ilike(term) | User.email.ilike(term) | User.full_name.ilike(term))
    total = q.order_by(None).count()
    items = q.order_by(Order.created_at.desc()).offset((page - 1) * per_page).limit(per_page).all()
    return {"items": [_with_customer(o) for o in items], "total": total, "page": page,
            "pages": max(1, math.ceil(total / per_page))}
