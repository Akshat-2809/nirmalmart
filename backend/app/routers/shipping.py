import logging
from fastapi import APIRouter, Depends, Header, HTTPException, Query, Request, status
from sqlalchemy.orm import Session
from app.database import get_db
from app.services import shiprocket

logger = logging.getLogger("nirmalmart")
router = APIRouter(tags=["Shipping"])


@router.get("/api/shipping/estimate")
def delivery_estimate(pincode: str = Query(..., pattern=r"^[1-9]\d{5}$")):
    """Courier delivery time for a pincode. `available: false` means use the built-in estimate instead."""
    if not shiprocket.is_configured():
        return {"available": False}
    try:
        return {"available": True, **shiprocket.delivery_estimate(pincode)}
    except shiprocket.ShiprocketError as e:
        logger.warning("Delivery estimate failed for %s: %s", pincode, e)
        return {"available": False}


# Shiprocket refuses webhook URLs containing "shiprocket", "kartrocket", "sr" or "kr", hence the neutral path
@router.post("/api/webhooks/courier")
async def courier_webhook(request: Request, x_api_key: str = Header(None), db: Session = Depends(get_db)):
    if not shiprocket.webhook_token_ok(x_api_key):
        raise HTTPException(status.HTTP_401_UNAUTHORIZED, "Invalid token")
    try:
        payload = await request.json()
    except ValueError:
        payload = None
    if isinstance(payload, dict) and not shiprocket.handle_webhook(db, payload):
        logger.info("Courier update for unknown shipment awb=%s order=%s", payload.get("awb"), payload.get("order_id"))
    return {"received": True}   # always 200 so Shiprocket doesn't retry updates we can't use
