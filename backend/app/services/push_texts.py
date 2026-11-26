"""Short order-update notifications, in the language the app is set to (English or Marathi)."""
from typing import Optional


def _money(v) -> str:
    v = float(v or 0)
    return f"₹{v:,.0f}" if v == int(v) else f"₹{v:,.2f}"


def order_push(order, event: str, lang: str) -> Optional[tuple]:
    no = order.order_number
    mr = lang == "mr"
    if event == "paid":
        return (("पेमेंट मिळाले", f"ऑर्डर {no} निश्चित झाली. आम्ही ती पॅक करत आहोत.") if mr else
                ("Payment received", f"Order {no} is confirmed. We’re packing it now."))
    if event == "shipped":
        return (("तुमची ऑर्डर निघाली आहे", f"ऑर्डर {no} पाठवली आहे. ट्रॅक करण्यासाठी टॅप करा.") if mr else
                ("Your order is on its way", f"Order {no} has been shipped. Tap to track it."))
    if event == "delivered":
        return (("ऑर्डर पोहोचली", f"ऑर्डर {no} पोहोचली आहे. आशा आहे तुम्हाला आवडेल!") if mr else
                ("Delivered", f"Order {no} has been delivered. We hope you love it!"))
    if event == "cancelled":
        refund = order.payment_status in ("refund_pending", "refunded")
        if mr:
            return "ऑर्डर रद्द झाली", f"ऑर्डर {no} रद्द झाली." + (" 5–7 कामकाजाच्या दिवसांत परतावा मिळेल." if refund else "")
        return "Order cancelled", f"Order {no} was cancelled." + (" Your refund will reach you in 5–7 working days." if refund else "")
    if event == "refunded":
        amt = _money(order.total_amount)
        return (("परतावा पाठवला", f"ऑर्डर {no} साठी {amt} परत पाठवले.") if mr else
                ("Refund sent", f"{amt} refunded for order {no}."))
    return None


def return_push(order, ret, event: str, lang: str) -> Optional[tuple]:
    no = order.order_number
    mr = lang == "mr"
    exchange = ret.kind == "exchange"
    if event == "pickup_scheduled":
        return (("पिकअप ठरला", f"ऑर्डर {no}: कुरिअर वस्तू घ्यायला येईल. ती पॅक करून ठेवा.") if mr else
                ("Pickup scheduled", f"Order {no}: a courier will collect the item. Please keep it packed."))
    if event == "rejected":
        return ((("बदलाची विनंती" if exchange else "परतीची विनंती") + " मंजूर नाही", f"ऑर्डर {no}: तपशीलासाठी टॅप करा.") if mr else
                (f"About your {'exchange' if exchange else 'return'} request", f"Order {no}: tap to see the details."))
    if event == "completed" and exchange:
        return (("बदललेली वस्तू निघाली", f"ऑर्डर {no} साठी नवीन वस्तू पाठवली आहे.") if mr else
                ("Your replacement is on its way", f"We’ve sent the replacement for order {no}."))
    if event == "completed":
        amt = _money(ret.refund_amount)
        return (("परतावा पाठवला", f"ऑर्डर {no}: परत केलेल्या वस्तूसाठी {amt} पाठवले.") if mr else
                ("Refund sent", f"{amt} refunded for your return on order {no}."))
    return None
