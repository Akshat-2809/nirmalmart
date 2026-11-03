"""Shiprocket courier integration.

Shipping an order is several Shiprocket calls in a row (create order → assign AWB → request pickup →
label). Each result is saved on our order as soon as it arrives, so if a later step fails the admin can
press "Ship" again and it carries on from where it stopped instead of creating a duplicate shipment.
"""
import hmac
import logging
import threading
import time
from datetime import datetime, timedelta, timezone
from typing import Optional

import httpx
from fastapi import HTTPException, status
from sqlalchemy.orm import Session

from app.config import settings
from app.models.order import Order
from app.models.return_request import ReturnRequest
from app.models.product import Product

logger = logging.getLogger("nirmalmart")

TOKEN_TTL = 9 * 24 * 3600          # Shiprocket tokens last 10 days; refresh a day early
PICKUP_TTL = 6 * 3600
ESTIMATE_TTL = 6 * 3600
IST = timezone(timedelta(hours=5, minutes=30))

# Courier wording → our order status. Anything not listed only updates the tracking text.
SHIPPED_WORDS = ("PICKED UP", "SHIPPED", "IN TRANSIT", "OUT FOR DELIVERY", "REACHED", "DISPATCHED")
STATUS_RANK = {"pending": 0, "confirmed": 1, "processing": 2, "shipped": 3, "delivered": 4}

_transport: Optional[httpx.BaseTransport] = None   # tests swap in a fake Shiprocket here
_lock = threading.Lock()
_token: dict = {"value": None, "expires": 0.0}
_pickup_cache: dict = {"value": None, "expires": 0.0}
_estimate_cache: dict = {}


class ShiprocketError(Exception):
    pass


def is_configured() -> bool:
    return bool(settings.SHIPROCKET_EMAIL and settings.SHIPROCKET_PASSWORD)


def _client() -> httpx.Client:
    return httpx.Client(base_url=settings.SHIPROCKET_API_URL, timeout=25, transport=_transport)


def _message(resp: httpx.Response) -> str:
    try:
        body = resp.json()
    except ValueError:
        return f"Shiprocket returned HTTP {resp.status_code}"
    if isinstance(body, dict):
        errors = body.get("errors")
        if isinstance(errors, dict) and errors:
            return "; ".join(f"{k}: {v[0] if isinstance(v, list) else v}" for k, v in errors.items())
        if body.get("message"):
            return str(body["message"])
    return f"Shiprocket returned HTTP {resp.status_code}"


def _login(force: bool = False) -> str:
    with _lock:
        if not force and _token["value"] and time.time() < _token["expires"]:
            return _token["value"]
        if not is_configured():
            raise ShiprocketError("Shiprocket is not connected yet (SHIPROCKET_EMAIL / SHIPROCKET_PASSWORD are not set)")
        with _client() as c:
            resp = c.post("/auth/login", json={"email": settings.SHIPROCKET_EMAIL, "password": settings.SHIPROCKET_PASSWORD})
        if resp.status_code != 200 or not resp.json().get("token"):
            raise ShiprocketError(f"Could not sign in to Shiprocket: {_message(resp)}")
        _token.update(value=resp.json()["token"], expires=time.time() + TOKEN_TTL)
        return _token["value"]


def _call(method: str, path: str, **kwargs) -> dict:
    for attempt in (1, 2):
        token = _login(force=attempt == 2)
        try:
            with _client() as c:
                resp = c.request(method, path, headers={"Authorization": f"Bearer {token}"}, **kwargs)
        except httpx.HTTPError as e:
            raise ShiprocketError(f"Could not reach Shiprocket ({e.__class__.__name__})") from e
        if resp.status_code == 401 and attempt == 1:
            continue   # token revoked or expired early: sign in again once
        if resp.status_code >= 400:
            raise ShiprocketError(_message(resp))
        try:
            return resp.json()
        except ValueError:
            return {}
    raise ShiprocketError("Shiprocket rejected the API login")


# ───────────── Account ─────────────

def pickup_locations(force: bool = False) -> list[dict]:
    if not force and _pickup_cache["value"] is not None and time.time() < _pickup_cache["expires"]:
        return _pickup_cache["value"]
    data = _call("GET", "/settings/company/pickup").get("data") or {}
    locations = [{"name": a.get("pickup_location"), "pincode": str(a.get("pin_code") or ""),
                  "city": a.get("city"), "address": a.get("address"), "verified": bool(a.get("phone_verified")),
                  # used as the destination of return pickups
                  "address_2": a.get("address_2") or "", "state": a.get("state"), "contact": a.get("name"),
                  "phone": str(a.get("phone") or ""), "email": a.get("email") or ""}
                 for a in data.get("shipping_address") or []]
    _pickup_cache.update(value=locations, expires=time.time() + PICKUP_TTL)
    return locations


def _pickup() -> dict:
    locations = pickup_locations()
    if not locations:
        raise ShiprocketError("Add a pickup address in Shiprocket (Settings → Pickup Addresses) first")
    wanted = settings.SHIPROCKET_PICKUP_LOCATION.strip().lower()
    if wanted:
        for loc in locations:
            if (loc["name"] or "").lower() == wanted:
                return loc
        raise ShiprocketError(f"No Shiprocket pickup address is named “{settings.SHIPROCKET_PICKUP_LOCATION}”")
    return locations[0]


def connection_status() -> dict:
    if not is_configured():
        return {"configured": False, "connected": False, "pickup_locations": [], "pickup_location": None,
                "webhook": bool(settings.SHIPROCKET_WEBHOOK_TOKEN), "error": None}
    try:
        locations = pickup_locations(force=True)
        chosen = _pickup()["name"]
        return {"configured": True, "connected": True, "pickup_locations": locations, "pickup_location": chosen,
                "webhook": bool(settings.SHIPROCKET_WEBHOOK_TOKEN), "error": None}
    except ShiprocketError as e:
        return {"configured": True, "connected": False, "pickup_locations": [], "pickup_location": None,
                "webhook": bool(settings.SHIPROCKET_WEBHOOK_TOKEN), "error": str(e)}


# ───────────── Couriers & delivery estimates ─────────────

def _serviceability(delivery_pin: str, weight: float, cod: bool) -> dict:
    pickup_pin = _pickup()["pincode"]
    try:
        return _call("GET", "/courier/serviceability/", params={
            "pickup_postcode": pickup_pin, "delivery_postcode": delivery_pin, "weight": weight, "cod": int(cod)})
    except ShiprocketError as e:
        # Shiprocket answers 404 when no courier covers the pincode
        if "not serviceable" in str(e).lower() or "no courier" in str(e).lower():
            return {}
        raise


def courier_options(delivery_pin: str, weight: float, cod: bool) -> dict:
    data = _serviceability(delivery_pin, weight, cod).get("data") or {}
    couriers = [{
        "courier_id": c.get("courier_company_id"), "name": c.get("courier_name"),
        "rate": float(c.get("rate") or c.get("freight_charge") or 0),
        "etd": c.get("etd"), "days": _int(c.get("estimated_delivery_days")),
        "cod": bool(c.get("cod")), "rating": c.get("rating"),
    } for c in data.get("available_courier_companies") or []]
    couriers.sort(key=lambda c: c["rate"])
    return {"recommended_id": data.get("recommended_courier_company_id"), "couriers": couriers}


def delivery_estimate(pincode: str) -> dict:
    """Fastest courier's delivery time for a pincode, cached; used by the product page pincode check."""
    hit = _estimate_cache.get(pincode)
    if hit and time.time() < hit[0]:
        return hit[1]
    options = courier_options(pincode, 0.5, cod=False)["couriers"]
    days = [c["days"] for c in options if c["days"]]
    result = {"serviceable": bool(options), "min_days": min(days) if days else None,
              "max_days": max(days) if days else None, "cod": any(c["cod"] for c in options)}
    if len(_estimate_cache) > 5000:
        _estimate_cache.clear()
    _estimate_cache[pincode] = (time.time() + ESTIMATE_TTL, result)
    return result


def _int(v) -> Optional[int]:
    try:
        return int(float(v))
    except (TypeError, ValueError):
        return None


# ───────────── Shipping an order ─────────────

def _items_payload(db: Session, lines: list) -> list[dict]:
    """lines: (OrderItem, units) pairs"""
    ids = [i.product_id for i, _ in lines if i.product_id]
    skus = dict(db.query(Product.id, Product.sku).filter(Product.id.in_(ids)).all()) if ids else {}
    return [{"name": i.product_name[:250], "sku": skus.get(i.product_id) or f"NM-ITEM-{i.id}",
             "units": units, "selling_price": float(i.unit_price)} for i, units in lines]


def _customer_name(order: Order) -> tuple[str, str]:
    a = order.shipping_address or {}
    first, _, last = (a.get("full_name") or (order.user.full_name if order.user else "") or "Customer").strip().partition(" ")
    return first, last or "."


def _order_payload(db: Session, order: Order, pkg: dict, cod: bool, pickup_name: str,
                   lines: Optional[list] = None, ref: Optional[str] = None) -> dict:
    """Forward shipment of the whole order, or of `lines` only (an exchange replacement, sent free)."""
    a = order.shipping_address or {}
    first, last = _customer_name(order)
    partial = lines is not None
    lines = lines if partial else [(i, i.quantity) for i in order.items]
    return {
        "order_id": ref or order.order_number,
        "order_date": order.created_at.astimezone(IST).strftime("%Y-%m-%d %H:%M"),
        "pickup_location": pickup_name,
        "billing_customer_name": first,
        "billing_last_name": last,
        "billing_address": a.get("address_line1") or "",
        "billing_address_2": a.get("address_line2") or "",
        "billing_city": a.get("city") or "",
        "billing_pincode": a.get("postal_code") or "",
        "billing_state": a.get("state") or "",
        "billing_country": a.get("country") or "India",
        "billing_email": order.user.email if order.user else "",
        "billing_phone": (a.get("phone") or "")[-10:],
        "shipping_is_billing": True,
        "order_items": _items_payload(db, lines),
        "payment_method": "COD" if cod else "Prepaid",
        "shipping_charges": 0 if partial else float(order.shipping_amount or 0),
        "sub_total": sum(float(i.unit_price) * u for i, u in lines) if partial else float(order.subtotal_amount),
        "length": pkg["length"], "breadth": pkg["breadth"], "height": pkg["height"], "weight": pkg["weight"],
    }


def ship_order(db: Session, order: Order, pkg: dict, cod: bool, courier_id: Optional[int] = None) -> Order:
    if order.status not in ("confirmed", "processing"):
        raise HTTPException(status.HTTP_400_BAD_REQUEST, "Confirm the order before shipping it")
    if order.awb_code:
        raise HTTPException(status.HTTP_400_BAD_REQUEST, "This order already has a shipment")
    try:
        # 1. Create the order in Shiprocket (skipped when a previous attempt got this far)
        if not order.shiprocket_shipment_id:
            res = _call("POST", "/orders/create/adhoc", json=_order_payload(db, order, pkg, cod, _pickup()["name"]))
            if not res.get("shipment_id"):
                raise ShiprocketError(res.get("message") or "Shiprocket did not create the shipment")
            order.shiprocket_order_id = str(res.get("order_id"))
            order.shiprocket_shipment_id = str(res["shipment_id"])
            order.tracking_status = "NEW"
            db.commit()

        # 2. Assign a courier and AWB number (Shiprocket picks its recommended courier if none is given)
        body = {"shipment_id": int(order.shiprocket_shipment_id)}
        if courier_id:
            body["courier_id"] = courier_id
        res = _call("POST", "/courier/assign/awb", json=body)
        data = (res.get("response") or {}).get("data") or {}
        if res.get("awb_assign_status") != 1 or not data.get("awb_code"):
            raise ShiprocketError(data.get("awb_assign_error") or res.get("message")
                                  or "No courier could take this shipment; try another courier or check your Shiprocket wallet balance")
        order.awb_code = str(data["awb_code"])
        order.courier_name = data.get("courier_name")
        order.tracking_status = "AWB ASSIGNED"
        if order.status == "confirmed":
            order.status = "processing"
        db.commit()
    except ShiprocketError as e:
        db.commit()
        raise HTTPException(status.HTTP_502_BAD_GATEWAY, str(e))

    # 3–4. Pickup request and label: useful but not essential, the admin can retry them
    _request_pickup(db, order)
    _fetch_label(db, order)
    db.refresh(order)
    return order


def _request_pickup(db: Session, order: Order) -> None:
    try:
        res = _call("POST", "/courier/generate/pickup", json={"shipment_id": [int(order.shiprocket_shipment_id)]})
        if res.get("pickup_status") == 1:
            order.tracking_status = "PICKUP SCHEDULED"
            db.commit()
    except ShiprocketError as e:
        logger.warning("Shiprocket pickup request failed for %s: %s", order.order_number, e)


def _fetch_label(db: Session, order: Order) -> None:
    try:
        res = _call("POST", "/courier/generate/label", json={"shipment_id": [int(order.shiprocket_shipment_id)]})
        if res.get("label_url"):
            order.shipping_label_url = res["label_url"]
            db.commit()
    except ShiprocketError as e:
        logger.warning("Shiprocket label failed for %s: %s", order.order_number, e)


def retry_label_and_pickup(db: Session, order: Order) -> Order:
    if not order.awb_code:
        raise HTTPException(status.HTTP_400_BAD_REQUEST, "Ship the order first")
    if order.tracking_status in ("AWB ASSIGNED", "NEW"):
        _request_pickup(db, order)
    _fetch_label(db, order)
    if not order.shipping_label_url:
        raise HTTPException(status.HTTP_502_BAD_GATEWAY, "Shiprocket has not produced the label yet; try again in a minute")
    return order


def cancel_shipment(db: Session, order: Order) -> Order:
    if not order.shiprocket_order_id:
        raise HTTPException(status.HTTP_400_BAD_REQUEST, "This order has no shipment")
    if order.status in ("shipped", "delivered"):
        raise HTTPException(status.HTTP_400_BAD_REQUEST, "The courier already has this parcel; cancel it in Shiprocket")
    try:
        _call("POST", "/orders/cancel", json={"ids": [int(order.shiprocket_order_id)]})
    except ShiprocketError as e:
        raise HTTPException(status.HTTP_502_BAD_GATEWAY, str(e))
    order.shiprocket_order_id = order.shiprocket_shipment_id = order.awb_code = None
    order.courier_name = order.shipping_label_url = None
    order.tracking_status = "SHIPMENT CANCELLED"
    db.commit()
    return order


# ───────────── Tracking ─────────────

def apply_tracking(db: Session, order: Order, courier_status: str) -> None:
    """Record the courier's status and move the order forward (never backwards)."""
    text = (courier_status or "").strip().upper()
    if not text:
        return
    order.tracking_status = text[:60]
    target = None
    if text == "DELIVERED":
        target = "delivered"
    elif any(w in text for w in SHIPPED_WORDS) and not text.startswith("RTO"):
        target = "shipped"
    if target and order.status in STATUS_RANK and STATUS_RANK[target] > STATUS_RANK[order.status]:
        order.status = target
        if target == "delivered":
            order.delivered_at = datetime.now(timezone.utc)
    db.commit()


def refresh_tracking(db: Session, order: Order) -> Order:
    if not order.awb_code:
        raise HTTPException(status.HTTP_400_BAD_REQUEST, "This order has no AWB yet")
    try:
        data = _call("GET", f"/courier/track/awb/{order.awb_code}").get("tracking_data") or {}
    except ShiprocketError as e:
        raise HTTPException(status.HTTP_502_BAD_GATEWAY, str(e))
    scans = data.get("shipment_track") or []
    current = (scans[0].get("current_status") if scans else None) or (data.get("shipment_track_activities") or [{}])[0].get("sr-status-label")
    if current:
        apply_tracking(db, order, current)
    return order


def webhook_token_ok(given: Optional[str]) -> bool:
    expected = settings.SHIPROCKET_WEBHOOK_TOKEN
    return bool(expected) and hmac.compare_digest((given or "").encode(), expected.encode())


def handle_webhook(db: Session, payload: dict) -> bool:
    awb = str(payload.get("awb") or "").strip()
    ref = str(payload.get("order_id") or payload.get("channel_order_id") or "").strip()
    order = None
    if awb:
        order = db.query(Order).filter(Order.awb_code == awb).first()
        if not order:
            ret = db.query(ReturnRequest).filter((ReturnRequest.return_awb == awb) | (ReturnRequest.repl_awb == awb)).first()
            if ret:
                apply_return_tracking(db, ret, awb, payload.get("current_status") or payload.get("shipment_status") or "")
                return True
    if not order and ref:
        order = db.query(Order).filter(Order.order_number == ref).first()
    if not order:
        return False
    apply_tracking(db, order, payload.get("current_status") or payload.get("shipment_status") or "")
    return True


# ───────────── Returns & exchanges ─────────────

def _return_lines(order: Order, ret: ReturnRequest) -> list:
    by_id = {i.id: i for i in order.items}
    return [(by_id[x["order_item_id"]], x["quantity"]) for x in ret.items if x["order_item_id"] in by_id]


def _assign_awb(shipment_id: str, is_return: bool = False) -> dict:
    body = {"shipment_id": int(shipment_id)}
    if is_return:
        body["is_return"] = 1
    res = _call("POST", "/courier/assign/awb", json=body)
    data = (res.get("response") or {}).get("data") or {}
    if res.get("awb_assign_status") != 1 or not data.get("awb_code"):
        raise ShiprocketError(data.get("awb_assign_error") or res.get("message")
                              or "No courier could take this shipment; check the Shiprocket wallet balance and try again")
    return data


def _best_effort(path: str, shipment_id: str) -> dict:
    try:
        return _call("POST", path, json={"shipment_id": [int(shipment_id)]})
    except ShiprocketError as e:
        logger.warning("Shiprocket %s failed for shipment %s: %s", path, shipment_id, e)
        return {}


def book_return_pickup(db: Session, order: Order, ret: ReturnRequest, pkg: dict) -> ReturnRequest:
    """Reverse pickup: the courier collects the items from the customer and brings them to our pickup address."""
    try:
        if not ret.return_shipment_id:
            store = _pickup()
            a = order.shipping_address or {}
            first, last = _customer_name(order)
            lines = _return_lines(order, ret)
            res = _call("POST", "/orders/create/return", json={
                "order_id": f"{order.order_number}-R{ret.id}",
                "order_date": datetime.now(IST).strftime("%Y-%m-%d"),
                "pickup_customer_name": first, "pickup_last_name": last,
                "pickup_address": a.get("address_line1") or "", "pickup_address_2": a.get("address_line2") or "",
                "pickup_city": a.get("city") or "", "pickup_state": a.get("state") or "",
                "pickup_country": a.get("country") or "India", "pickup_pincode": a.get("postal_code") or "",
                "pickup_email": order.user.email if order.user else "", "pickup_phone": (a.get("phone") or "")[-10:],
                "shipping_customer_name": store.get("contact") or store["name"], "shipping_last_name": ".",
                "shipping_address": store.get("address") or "", "shipping_address_2": store.get("address_2") or "",
                "shipping_city": store.get("city") or "", "shipping_state": store.get("state") or "",
                "shipping_country": "India", "shipping_pincode": store["pincode"],
                "shipping_email": store.get("email") or "", "shipping_phone": (store.get("phone") or "")[-10:],
                "order_items": _items_payload(db, lines),
                "payment_method": "PREPAID",
                "sub_total": sum(float(i.unit_price) * u for i, u in lines),
                "length": pkg["length"], "breadth": pkg["breadth"], "height": pkg["height"], "weight": pkg["weight"],
            })
            if not res.get("shipment_id"):
                raise ShiprocketError(res.get("message") or "Shiprocket did not create the return")
            ret.return_sr_order_id = str(res.get("order_id"))
            ret.return_shipment_id = str(res["shipment_id"])
            ret.return_tracking = "RETURN CREATED"
            db.commit()
        data = _assign_awb(ret.return_shipment_id, is_return=True)
        ret.return_awb = str(data["awb_code"])
        ret.return_courier = data.get("courier_name")
        ret.return_tracking = "PICKUP SCHEDULED"
        ret.status = "pickup_scheduled"
        db.commit()
    except ShiprocketError as e:
        db.commit()
        raise HTTPException(status.HTTP_502_BAD_GATEWAY, str(e))
    _best_effort("/courier/generate/pickup", ret.return_shipment_id)
    return ret


def cancel_return_pickup(db: Session, ret: ReturnRequest) -> None:
    if not ret.return_sr_order_id:
        return
    _call("POST", "/orders/cancel", json={"ids": [int(ret.return_sr_order_id)]})
    ret.return_sr_order_id = ret.return_shipment_id = ret.return_awb = ret.return_courier = None
    ret.return_tracking = "PICKUP CANCELLED"
    db.commit()


def ship_replacement(db: Session, order: Order, ret: ReturnRequest, pkg: dict) -> ReturnRequest:
    """Exchange: send the same items again, free of charge."""
    try:
        if not ret.repl_shipment_id:
            payload = _order_payload(db, order, pkg, False, _pickup()["name"], lines=_return_lines(order, ret),
                                     ref=f"{order.order_number}-EX{ret.id}")
            res = _call("POST", "/orders/create/adhoc", json=payload)
            if not res.get("shipment_id"):
                raise ShiprocketError(res.get("message") or "Shiprocket did not create the replacement shipment")
            ret.repl_sr_order_id = str(res.get("order_id"))
            ret.repl_shipment_id = str(res["shipment_id"])
            db.commit()
        data = _assign_awb(ret.repl_shipment_id)
        ret.repl_awb = str(data["awb_code"])
        ret.repl_courier = data.get("courier_name")
        ret.repl_tracking = "AWB ASSIGNED"
        db.commit()
    except ShiprocketError as e:
        db.commit()
        raise HTTPException(status.HTTP_502_BAD_GATEWAY, str(e))
    if _best_effort("/courier/generate/pickup", ret.repl_shipment_id).get("pickup_status") == 1:
        ret.repl_tracking = "PICKUP SCHEDULED"
    label = _best_effort("/courier/generate/label", ret.repl_shipment_id).get("label_url")
    if label:
        ret.repl_label_url = label
    db.commit()
    return ret


RETURN_RANK = {s: n for n, s in enumerate(["requested", "approved", "pickup_scheduled", "picked_up", "received"])}


def apply_return_tracking(db: Session, ret: ReturnRequest, awb: str, courier_status: str) -> None:
    """Courier updates for a return pickup move it forward (never back); replacement updates are shown as text."""
    text = (courier_status or "").strip().upper()
    if not text:
        return
    if awb == ret.repl_awb:
        ret.repl_tracking = text[:60]
        db.commit()
        return
    ret.return_tracking = text[:60]
    target = None
    if "DELIVERED" in text and "UNDELIVERED" not in text:
        target = "received"            # delivered back to our pickup address
    elif any(w in text for w in SHIPPED_WORDS):
        target = "picked_up"
    now = datetime.now(timezone.utc)
    if target and ret.status in RETURN_RANK and RETURN_RANK[target] > RETURN_RANK[ret.status]:
        ret.picked_up_at = ret.picked_up_at or now
        if target == "received":
            ret.received_at = now
        ret.status = target
    db.commit()


def refresh_return_tracking(db: Session, ret: ReturnRequest) -> ReturnRequest:
    for awb in (ret.return_awb, ret.repl_awb):
        if not awb:
            continue
        try:
            data = _call("GET", f"/courier/track/awb/{awb}").get("tracking_data") or {}
        except ShiprocketError as e:
            raise HTTPException(status.HTTP_502_BAD_GATEWAY, str(e))
        scans = data.get("shipment_track") or []
        current = (scans[0].get("current_status") if scans else None) or (data.get("shipment_track_activities") or [{}])[0].get("sr-status-label")
        if current:
            apply_return_tracking(db, ret, awb, current)
    return ret
