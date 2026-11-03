from pydantic import BaseModel, ConfigDict, Field, computed_field
from typing import Optional, List, Literal
from datetime import datetime, timedelta, timezone
from app.models.return_request import RETURN_WINDOW_DAYS
from app.schemas.common import Money, NAME_PATTERN, CITY_PATTERN, MOBILE_PATTERN, PINCODE_PATTERN


class ShippingAddress(BaseModel):
    full_name: str = Field(..., min_length=2, max_length=100, pattern=NAME_PATTERN)
    phone: str = Field(..., pattern=MOBILE_PATTERN)
    address_line1: str = Field(..., min_length=3, max_length=255)
    address_line2: Optional[str] = None
    city: str = Field(..., min_length=2, max_length=100, pattern=CITY_PATTERN)
    state: str = Field(..., min_length=2)
    postal_code: str = Field(..., pattern=PINCODE_PATTERN)
    country: str = "India"


class OrderCreate(BaseModel):
    shipping_address: Optional[ShippingAddress] = None
    address_id: Optional[int] = None
    notes: Optional[str] = Field(None, max_length=500)


class OrderItemResponse(BaseModel):
    model_config = ConfigDict(from_attributes=True)
    id: int
    product_id: Optional[int] = None
    product_name: str
    product_slug: Optional[str] = None
    product_image: Optional[str] = None
    quantity: int
    unit_price: Money
    subtotal: Money


class ReturnItemIn(BaseModel):
    order_item_id: int
    quantity: int = Field(..., ge=1, le=1000)


class ReturnCreate(BaseModel):
    kind: Literal["return", "exchange"]
    items: List[ReturnItemIn] = Field(..., min_length=1)
    reason: str = Field(..., min_length=2, max_length=100)
    comment: Optional[str] = Field(None, max_length=500)


class ReturnResponse(BaseModel):
    model_config = ConfigDict(from_attributes=True)
    id: int
    kind: str
    items: List[dict]
    reason: str
    comment: Optional[str] = None
    status: str
    admin_note: Optional[str] = None
    refund_amount: Optional[Money] = None
    refund_reference: Optional[str] = None
    return_awb: Optional[str] = None
    return_courier: Optional[str] = None
    return_tracking: Optional[str] = None
    repl_awb: Optional[str] = None
    repl_courier: Optional[str] = None
    repl_tracking: Optional[str] = None
    created_at: datetime
    approved_at: Optional[datetime] = None
    picked_up_at: Optional[datetime] = None
    received_at: Optional[datetime] = None
    completed_at: Optional[datetime] = None

    @computed_field
    @property
    def return_tracking_url(self) -> Optional[str]:
        return f"https://shiprocket.co/tracking/{self.return_awb}" if self.return_awb else None

    @computed_field
    @property
    def repl_tracking_url(self) -> Optional[str]:
        return f"https://shiprocket.co/tracking/{self.repl_awb}" if self.repl_awb else None


class AdminReturnResponse(ReturnResponse):
    repl_label_url: Optional[str] = None


class OrderResponse(BaseModel):
    model_config = ConfigDict(from_attributes=True)
    id: int
    order_number: str
    status: str
    payment_method: Optional[str] = None
    payment_status: str
    subtotal_amount: Money
    tax_amount: Money
    shipping_amount: Money
    total_amount: Money
    shipping_address: Optional[dict] = None
    notes: Optional[str] = None
    items: List[OrderItemResponse] = []
    awb_code: Optional[str] = None
    courier_name: Optional[str] = None
    tracking_status: Optional[str] = None
    cancelled_at: Optional[datetime] = None
    delivered_at: Optional[datetime] = None
    returns: List[ReturnResponse] = []
    cancel_reason: Optional[str] = None
    refunded_at: Optional[datetime] = None
    refund_reference: Optional[str] = None
    created_at: datetime
    updated_at: datetime

    @computed_field
    @property
    def tracking_url(self) -> Optional[str]:
        return f"https://shiprocket.co/tracking/{self.awb_code}" if self.awb_code else None

    @computed_field
    @property
    def return_until(self) -> Optional[datetime]:
        """Last moment to ask for a return/exchange (only for delivered orders)"""
        if self.status != "delivered":
            return None
        delivered = self.delivered_at or self.updated_at
        if delivered.tzinfo is None:
            delivered = delivered.replace(tzinfo=timezone.utc)
        return delivered + timedelta(days=RETURN_WINDOW_DAYS)


class AdminOrderResponse(OrderResponse):
    returns: List[AdminReturnResponse] = []
    customer_name: Optional[str] = None
    customer_email: Optional[str] = None
    shiprocket_order_id: Optional[str] = None
    shiprocket_shipment_id: Optional[str] = None
    shipping_label_url: Optional[str] = None


class PackageIn(BaseModel):
    weight: float = Field(..., gt=0, le=100)        # kg
    length: float = Field(..., gt=0, le=300)        # cm
    breadth: float = Field(..., gt=0, le=300)
    height: float = Field(..., gt=0, le=300)


class ShipOrderRequest(PackageIn):
    cod: bool = False
    courier_id: Optional[int] = None


class OrderStatusUpdate(BaseModel):
    status: Literal["pending", "confirmed", "processing", "shipped", "delivered", "cancelled"]


class PaymentStatusUpdate(BaseModel):
    payment_status: Literal["pending", "paid", "failed", "refund_pending", "refunded"]
    refund_reference: Optional[str] = Field(None, max_length=100)


class OrderCancel(BaseModel):
    reason: Optional[str] = Field(None, max_length=200)


class ReturnReject(BaseModel):
    note: Optional[str] = Field(None, max_length=300)


class ReturnMark(BaseModel):
    status: Literal["picked_up", "received"]


class ReturnRefund(BaseModel):
    reference: Optional[str] = Field(None, max_length=100)


class PaginatedOrders(BaseModel):
    items: List[AdminOrderResponse]
    total: int
    page: int
    pages: int
