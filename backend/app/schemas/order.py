from pydantic import BaseModel, ConfigDict, Field, computed_field
from typing import Optional, List, Literal
from datetime import datetime
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
    created_at: datetime
    updated_at: datetime

    @computed_field
    @property
    def tracking_url(self) -> Optional[str]:
        return f"https://shiprocket.co/tracking/{self.awb_code}" if self.awb_code else None


class AdminOrderResponse(OrderResponse):
    customer_name: Optional[str] = None
    customer_email: Optional[str] = None
    shiprocket_order_id: Optional[str] = None
    shiprocket_shipment_id: Optional[str] = None
    shipping_label_url: Optional[str] = None


class ShipOrderRequest(BaseModel):
    weight: float = Field(..., gt=0, le=100)        # kg
    length: float = Field(..., gt=0, le=300)        # cm
    breadth: float = Field(..., gt=0, le=300)
    height: float = Field(..., gt=0, le=300)
    cod: bool = False
    courier_id: Optional[int] = None


class OrderStatusUpdate(BaseModel):
    status: Literal["pending", "confirmed", "processing", "shipped", "delivered", "cancelled"]


class PaymentStatusUpdate(BaseModel):
    payment_status: Literal["pending", "paid", "failed", "refunded"]


class PaginatedOrders(BaseModel):
    items: List[AdminOrderResponse]
    total: int
    page: int
    pages: int
