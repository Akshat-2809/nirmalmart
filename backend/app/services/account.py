"""Deleting a customer account (Play Store and privacy-law requirement).

The person's details are erased; their order records stay — with the name, phone and street address
removed — because orders are needed for GST, returns and refunds. Reviews stay, shown as "Customer".
"""
import secrets
from datetime import datetime, timezone

from fastapi import HTTPException, status
from sqlalchemy.orm import Session

from app.models.address import Address
from app.models.cart import CartItem
from app.models.order import Order
from app.models.return_request import OPEN_RETURN_STATUSES, ReturnRequest
from app.models.user import User
from app.models.wishlist import WishlistItem
from app.services.auth import hash_password, verify_password

ACTIVE_ORDER_STATUSES = ("pending", "confirmed", "processing", "shipped")


def unfinished_orders(db: Session, user: User) -> list:
    """Order numbers that still need the customer: not yet delivered, refund owed, or a return in progress"""
    orders = db.query(Order).filter(Order.user_id == user.id).all()
    busy = []
    for o in orders:
        open_return = db.query(ReturnRequest.id).filter(
            ReturnRequest.order_id == o.id, ReturnRequest.status.in_(OPEN_RETURN_STATUSES)).first()
        if o.status in ACTIVE_ORDER_STATUSES or o.payment_status == "refund_pending" or open_return:
            busy.append(o.order_number)
    return busy


def delete_account(db: Session, user: User, password: str) -> None:
    if user.role != "customer":
        raise HTTPException(status.HTTP_400_BAD_REQUEST, "Staff accounts can't be deleted here")
    if not verify_password(password, user.password_hash):
        raise HTTPException(status.HTTP_400_BAD_REQUEST, "Password is incorrect")
    busy = unfinished_orders(db, user)
    if busy:
        raise HTTPException(status.HTTP_400_BAD_REQUEST,
                            f"Please wait until these orders are delivered or cancelled: {', '.join(busy)}")

    for model in (Address, CartItem, WishlistItem):
        db.query(model).filter(model.user_id == user.id).delete(synchronize_session=False)

    # Orders are kept for the business's records, without personal contact details
    for o in db.query(Order).filter(Order.user_id == user.id).all():
        a = dict(o.shipping_address or {})
        o.shipping_address = {
            "full_name": "Deleted customer",
            "city": a.get("city"), "state": a.get("state"), "postal_code": a.get("postal_code"),
            "country": a.get("country", "India"),
        }
        o.notes = None

    stamp = datetime.now(timezone.utc).strftime("%Y%m%d%H%M%S")
    user.email = f"deleted-{user.id}-{stamp}@deleted.nirmalmart.in"  # frees the real email for a new sign-up
    user.username = None
    user.full_name = "Deleted customer"
    user.phone = None
    user.password_hash = hash_password(secrets.token_urlsafe(32))  # nobody can sign in again
    user.is_active = False
    db.commit()
