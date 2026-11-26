"""The emails the store sends: password reset, order updates and offers. Each builder returns
(subject, html, text). Simple table-based HTML so it looks right in Gmail, Outlook and phone mail apps."""
from html import escape
from typing import Optional

from app.config import settings

GREEN = "#317239"
INK = "#111217"
SOFT = "#5F6270"
SUPPORT_PHONE = "+91 74982 99375"


def _money(v) -> str:
    v = float(v or 0)
    return f"₹{v:,.0f}" if v == int(v) else f"₹{v:,.2f}"


def _button(label: str, url: str) -> str:
    return (f'<table role="presentation" cellpadding="0" cellspacing="0" style="margin:22px 0 6px"><tr>'
            f'<td style="background:{GREEN};border-radius:12px">'
            f'<a href="{escape(url, quote=True)}" style="display:inline-block;padding:13px 24px;color:#fff;'
            f'font-weight:700;font-size:15px;text-decoration:none">{escape(label)}</a></td></tr></table>')


def layout(heading: str, body_html: str, preheader: str = "", footer_note: str = "") -> str:
    site = settings.SITE_URL
    return f"""<!doctype html><html><head><meta charset="utf-8"><meta name="viewport" content="width=device-width">
<title>{escape(heading)}</title></head>
<body style="margin:0;background:#F3F3F0;font-family:Inter,Segoe UI,Roboto,Arial,sans-serif;color:{INK}">
<span style="display:none;max-height:0;overflow:hidden">{escape(preheader)}</span>
<table role="presentation" width="100%" cellpadding="0" cellspacing="0" style="background:#F3F3F0;padding:24px 12px"><tr><td align="center">
<table role="presentation" width="100%" cellpadding="0" cellspacing="0" style="max-width:560px">
<tr><td style="padding:0 4px 14px"><a href="{site}" style="text-decoration:none;font-size:20px;font-weight:800;color:{GREEN}">Nirmal Mart</a></td></tr>
<tr><td style="background:#fff;border-radius:20px;padding:28px 26px;border:1px solid #EDEDE7">
<h1 style="margin:0 0 12px;font-size:22px;line-height:1.25">{escape(heading)}</h1>
<div style="font-size:15px;line-height:1.6;color:#30333B">{body_html}</div>
</td></tr>
<tr><td style="padding:18px 6px;font-size:12px;line-height:1.6;color:{SOFT}">
{footer_note}
Questions? Reply to this email, write to {escape(settings.EMAIL_REPLY_TO)} or WhatsApp {SUPPORT_PHONE}.<br>
<a href="{site}" style="color:{SOFT}">nirmalmart.in</a> · Made with ❤️ in Maharashtra
</td></tr></table></td></tr></table></body></html>"""


def _p(text: str) -> str:
    return f'<p style="margin:0 0 12px">{text}</p>'


def _order_link(order) -> str:
    return f"{settings.SITE_URL}/account/orders/{order.id}"


def _items_table(order) -> str:
    rows = "".join(
        f'<tr><td style="padding:6px 0;border-bottom:1px solid #F0F0EC">{escape(i.product_name)} × {i.quantity}</td>'
        f'<td align="right" style="padding:6px 0;border-bottom:1px solid #F0F0EC;white-space:nowrap">{_money(i.subtotal)}</td></tr>'
        for i in order.items)
    ship = "FREE" if float(order.shipping_amount or 0) == 0 else _money(order.shipping_amount)
    return (f'<table role="presentation" width="100%" cellpadding="0" cellspacing="0" style="font-size:14px;margin:8px 0 4px">{rows}'
            f'<tr><td style="padding:6px 0;color:{SOFT}">Delivery</td><td align="right" style="padding:6px 0">{ship}</td></tr>'
            f'<tr><td style="padding:8px 0;font-weight:800">Total</td><td align="right" style="padding:8px 0;font-weight:800">{_money(order.total_amount)}</td></tr>'
            f'</table>')


def _first_name(user) -> str:
    n = (getattr(user, "full_name", "") or "").strip().split(" ")
    return escape(n[0]) if n and n[0] else "there"


# ───────────── Account ─────────────

def password_reset(user, link: str) -> tuple:
    body = (_p(f"Hello {_first_name(user)},") +
            _p("We got a request to reset the password for your Nirmal Mart account. Tap the button to choose a new one. "
               "The link works for 1 hour and only once.") +
            _button("Choose a new password", link) +
            _p(f'<span style="font-size:13px;color:{SOFT}">Didn’t ask for this? You can ignore this email — your password stays the same.</span>'))
    text = (f"Reset your Nirmal Mart password: {link}\n\nThe link works for 1 hour and only once. "
            "If you didn't ask for this, ignore this email.")
    return "Reset your Nirmal Mart password", layout("Reset your password", body, "Choose a new password — link valid for 1 hour"), text


# ───────────── Orders ─────────────

def order_placed(order, user) -> tuple:
    no = escape(order.order_number)
    pay = order.payment_status == "pending"
    body = (_p(f"Hello {_first_name(user)}, thank you for your order <b>{no}</b>.") +
            (_p(f"<b>One last step:</b> pay <b>{_money(order.total_amount)}</b> by UPI and send us the payment proof on WhatsApp. "
                "Open the order to see our QR code and UPI ID. We start packing once the payment is checked.") if pay else "") +
            _items_table(order) + _button("Pay now" if pay else "View order", _order_link(order)))
    text = (f"Thank you for your order {order.order_number}. Total {_money(order.total_amount)}.\n"
            + ("Pay by UPI and send the proof on WhatsApp — details on the order page.\n" if pay else "")
            + f"View your order: {_order_link(order)}")
    return f"Order {order.order_number} placed", layout("Order placed!", body, f"Total {_money(order.total_amount)}"), text


def payment_received(order, user) -> tuple:
    body = (_p(f"Hello {_first_name(user)}, we’ve received your payment of <b>{_money(order.total_amount)}</b> for order "
               f"<b>{escape(order.order_number)}</b>. Your order is confirmed and we’re getting it ready.") +
            _button("View order", _order_link(order)))
    text = f"Payment received for {order.order_number}. Your order is confirmed. {_order_link(order)}"
    return f"Payment received · order {order.order_number} confirmed", layout("Payment received", body), text


def order_shipped(order, user) -> tuple:
    track = f"{escape(order.courier_name or 'Our courier')}" + (f", AWB {escape(order.awb_code)}" if order.awb_code else "")
    url = f"https://shiprocket.co/tracking/{order.awb_code}" if order.awb_code else _order_link(order)
    body = (_p(f"Good news, {_first_name(user)} — order <b>{escape(order.order_number)}</b> is on its way.") +
            _p(f"Courier: {track}.") + _button("Track your parcel", url))
    text = f"Order {order.order_number} is on its way. Track: {url}"
    return f"Order {order.order_number} is on its way", layout("Your order is on its way", body), text


def order_delivered(order, user) -> tuple:
    body = (_p(f"Order <b>{escape(order.order_number)}</b> has been delivered. We hope you love it, {_first_name(user)}!") +
            _p("Something not right? You can ask for a return or exchange within 5 days of delivery from the order page.") +
            _button("View order", _order_link(order)))
    text = f"Order {order.order_number} was delivered. Return or exchange within 5 days: {_order_link(order)}"
    return f"Order {order.order_number} delivered", layout("Delivered", body), text


def order_cancelled(order, user) -> tuple:
    if order.payment_status in ("refund_pending", "refunded"):
        money = (f"Your payment of <b>{_money(order.total_amount)}</b> will be refunded to the UPI account you paid from "
                 "within 5–7 working days.")
    else:
        money = "No payment was confirmed for this order, so nothing has been charged."
    reason = f" Reason: {escape(order.cancel_reason)}." if order.cancel_reason else ""
    body = (_p(f"Order <b>{escape(order.order_number)}</b> has been cancelled.{reason}") + _p(money) +
            _button("View order", _order_link(order)))
    text = f"Order {order.order_number} was cancelled. {'Refund within 5-7 working days.' if 'refund' in money else 'Nothing was charged.'}"
    return f"Order {order.order_number} cancelled", layout("Order cancelled", body), text


def refund_sent(order, user, amount=None, reference: Optional[str] = None, what: str = "order") -> tuple:
    amt = _money(amount if amount is not None else order.total_amount)
    ref = f" (UPI reference {escape(reference)})" if reference else ""
    body = (_p(f"We’ve sent a refund of <b>{amt}</b> for your {what} on order <b>{escape(order.order_number)}</b> to the UPI "
               f"account you paid from{ref}.") +
            _p(f'<span style="font-size:13px;color:{SOFT}">Banks can take 1–2 working days to show it.</span>') +
            _button("View order", _order_link(order)))
    text = f"Refund of {amt} sent for order {order.order_number}{' — UPI ref ' + reference if reference else ''}."
    return f"Refund of {amt} sent · order {order.order_number}", layout("Refund sent", body), text


# ───────────── Returns and exchanges ─────────────

def return_update(order, user, ret, event: str) -> Optional[tuple]:
    kind = "exchange" if ret.kind == "exchange" else "return"
    no = escape(order.order_number)
    if event == "requested":
        heading, line = f"We got your {kind} request", (f"Thanks — we’ve received your {kind} request for order <b>{no}</b>. "
                                                       "We’ll check it and arrange a pickup from your address.")
    elif event == "pickup_scheduled":
        heading, line = "Pickup scheduled", (f"A courier will collect the item for your {kind} on order <b>{no}</b>. "
                                             "Please keep it packed, with all its accessories.")
    elif event == "rejected":
        note = f" Note from us: {escape(ret.admin_note)}" if ret.admin_note else ""
        heading, line = f"About your {kind} request", (f"We’re sorry — we couldn’t approve the {kind} request on order <b>{no}</b>.{note} "
                                                       "Reply to this email if you have questions.")
    elif event == "completed" and kind == "exchange":
        heading, line = "Your replacement is on its way", f"We’ve sent the replacement item for order <b>{no}</b>."
    elif event == "completed":
        return refund_sent(order, user, ret.refund_amount, ret.refund_reference, what="return")
    else:
        return None
    body = _p(line) + _button("View order", _order_link(order))
    text = f"{heading}: order {order.order_number}. {_order_link(order)}"
    return f"{heading} · order {order.order_number}", layout(heading, body), text


# ───────────── Offers ─────────────

def broadcast(subject: str, heading: str, message: str, button_text: Optional[str], button_url: Optional[str],
              unsubscribe_url: str) -> tuple:
    paras = "".join(_p(escape(line)) for line in message.strip().split("\n\n") if line.strip())
    paras = paras.replace("\n", "<br>")
    btn = _button(button_text, button_url) if button_text and button_url else ""
    note = (f'You’re getting this because you signed up for offers at nirmalmart.in. '
            f'<a href="{escape(unsubscribe_url, quote=True)}" style="color:{SOFT}">Unsubscribe</a>.<br>')
    html = layout(heading or subject, paras + btn, subject, footer_note=note)
    text = f"{heading or subject}\n\n{message.strip()}\n\n" + (f"{button_text}: {button_url}\n\n" if btn else "") + \
        f"Unsubscribe: {unsubscribe_url}"
    return subject, html, text
