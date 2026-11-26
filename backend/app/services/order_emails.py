"""Order and return emails, sent automatically whenever an order changes — whatever changed it
(the customer, the admin panel or the courier's tracking updates).

How: after each database flush we note what changed on orders and returns; once the transaction
commits, the emails go out on a background thread. A failed email never affects the order.
"""
import logging
import threading

from sqlalchemy import event, inspect
from sqlalchemy.orm import Session

from app.models.order import Order
from app.models.return_request import ReturnRequest
from app.services import email, email_templates as tpl

log = logging.getLogger("nirmalmart.email")
_KEY = "nm_pending_emails"

# True in tests: send straight away instead of on a thread
RUN_INLINE = False

ORDER_STATUS_EMAILS = {"shipped", "delivered", "cancelled"}
RETURN_STATUS_EMAILS = {"pickup_scheduled", "rejected", "completed"}


def _changed(obj, attr):
    """(old, new) if the attribute changed in this flush, else None"""
    h = inspect(obj).attrs[attr].history
    if not h.has_changes():
        return None
    return (h.deleted[0] if h.deleted else None), (h.added[0] if h.added else None)


@event.listens_for(Session, "after_flush")
def _collect(session, _ctx):
    pending = session.info.setdefault(_KEY, [])
    for obj in session.new:
        if isinstance(obj, Order):
            pending.append(("order", obj.id, "placed"))
        elif isinstance(obj, ReturnRequest):
            pending.append(("return", obj.id, "requested"))
    for obj in session.dirty:
        if isinstance(obj, Order) and obj not in session.new:
            st = _changed(obj, "status")
            if st and st[1] in ORDER_STATUS_EMAILS and st[0] != st[1]:
                pending.append(("order", obj.id, st[1]))
            pay = _changed(obj, "payment_status")
            if pay and pay[0] != pay[1]:
                if pay[1] == "paid" and obj.status != "cancelled":
                    pending.append(("order", obj.id, "paid"))
                elif pay[1] == "refunded":
                    pending.append(("order", obj.id, "refunded"))
        elif isinstance(obj, ReturnRequest) and obj not in session.new:
            st = _changed(obj, "status")
            if st and st[1] in RETURN_STATUS_EMAILS and st[0] != st[1]:
                pending.append(("return", obj.id, st[1]))


@event.listens_for(Session, "after_commit")
def _dispatch(session):
    pending = session.info.pop(_KEY, [])
    if not pending:
        return
    # same email once per commit (e.g. status saved twice)
    unique = list(dict.fromkeys(pending))
    if RUN_INLINE:
        _send_all(unique)
    else:
        threading.Thread(target=_send_all, args=(unique,), daemon=True).start()


@event.listens_for(Session, "after_rollback")
def _forget(session):
    session.info.pop(_KEY, None)


def _recipient(order):
    u = order.user
    if not u or not u.is_active or not u.email or u.email.endswith("@deleted.nirmalmart.in"):
        return None
    return u


def _send_all(pending):
    from app.database import SessionLocal  # here, so tests can point it at their database first
    db = SessionLocal()
    try:
        for kind, obj_id, ev in pending:
            try:
                if kind == "order":
                    order = db.get(Order, obj_id)
                    user = order and _recipient(order)
                    if not user:
                        continue
                    build = {"placed": tpl.order_placed, "paid": tpl.payment_received, "shipped": tpl.order_shipped,
                             "delivered": tpl.order_delivered, "cancelled": tpl.order_cancelled}.get(ev)
                    msg = build(order, user) if build else (
                        tpl.refund_sent(order, user, reference=order.refund_reference) if ev == "refunded" else None)
                else:
                    ret = db.get(ReturnRequest, obj_id)
                    order = ret and db.get(Order, ret.order_id)
                    user = order and _recipient(order)
                    if not user:
                        continue
                    msg = tpl.return_update(order, user, ret, ev)
                if msg:
                    subject, html, text = msg
                    email.send(user.email, subject, html, text)
            except Exception:
                log.exception("order email %s %s %s failed", kind, obj_id, ev)
    finally:
        db.close()
