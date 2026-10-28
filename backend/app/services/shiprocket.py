"""Shiprocket courier integration.

Shipping an order is several Shiprocket calls in a row (create order → assign AWB → request pickup →
label). Each result is saved on our order as soon as it arrives, so if a later step fails the admin can
press "Ship" again and it carries on from where it stopped instead of creating a duplicate shipment.
"""
import hmac
import logging
import threading
import time
from datetime import timedelta, timezone
from typing import Optional

import httpx
from fastapi import HTTPException, status
from sqlalchemy.orm import Session

from app.config import settings
from app.models.order import Order
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
                  "city": a.get("city"), "address": a.get("address"), "verified": bool(a.get("phone_verified"))}
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

def _order_payload(db: Session, order: Order, pkg: dict, cod: bool, pickup_name: str) -> dict:
    a = order.shipping_address or {}
    first, _, last = (a.get("full_name") or (order.user.full_name if order.user else "") or "Customer").strip().partition(" ")
    skus = {}
    ids = [i.product_id for i in order.items if i.product_id]
    if ids:
        skus = dict(db.query(Product.id, Product.sku).filter(Product.id.in_(ids)).all())
    return {
        "order_id": order.order_number,
        "order_date": order.created_at.astimezone(IST).strftime("%Y-%m-%d %H:%M"),
        "pickup_location": pickup_name,
        "billing_customer_name": first,
        "billing_last_name": last or ".",
        "billing_address": a.get("address_line1") or "",
        "billing_address_2": a.get("address_line2") or "",
        "billing_city": a.get("city") or "",
        "billing_pincode": a.get("postal_code") or "",
        "billing_state": a.get("state") or "",
        "billing_country": a.get("country") or "India",
        "billing_email": order.user.email if order.user else "",
        "billing_phone": (a.get("phone") or "")[-10:],
        "shipping_is_billing": True,
        "order_items": [{
            "name": i.product_name[:250],
            "sku": skus.get(i.product_id) or f"NM-ITEM-{i.id}",
            "units": i.quantity,
            "selling_price": float(i.unit_price),
        } for i in order.items],
        "payment_method": "COD" if cod else "Prepaid",
        "shipping_charges": float(order.shipping_amount or 0),
        "sub_total": float(order.subtotal_amount),
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
    if not order and ref:
        order = db.query(Order).filter(Order.order_number == ref).first()
    if not order:
        return False
    apply_tracking(db, order, payload.get("current_status") or payload.get("shipment_status") or "")
    return True
