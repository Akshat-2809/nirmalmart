from decimal import Decimal, ROUND_HALF_UP
from app.config import settings

TWO_PLACES = Decimal("0.01")


def to_money(value) -> Decimal:
    return Decimal(str(value or 0)).quantize(TWO_PLACES, rounding=ROUND_HALF_UP)


def compute_totals(subtotal) -> dict:
    """Single source of truth for order maths. Listed prices are GST-inclusive (Indian MRP
    convention), so tax_amount is the GST already contained in the subtotal, not an extra charge."""
    subtotal = to_money(subtotal)
    rate = Decimal(str(settings.GST_RATE))
    tax = to_money(subtotal - subtotal / (1 + rate))
    if subtotal == 0 or subtotal >= to_money(settings.FREE_SHIPPING_THRESHOLD):
        shipping = to_money(0)
    else:
        shipping = to_money(settings.SHIPPING_FEE)
    return {
        "subtotal": subtotal,
        "tax_amount": tax,
        "shipping_amount": shipping,
        "total_amount": to_money(subtotal + shipping),
    }
