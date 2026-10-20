from pydantic import BaseModel, ConfigDict, Field
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
    created_at: datetime
    updated_at: datetime


class AdminOrderResponse(OrderResponse):
    customer_name: Optional[str] = None
    customer_email: Optional[str] = None


class OrderStatusUpdate(BaseModel):
    status: Literal["pending", "confirmed", "processing", "shipped", "delivered", "cancelled"]


class PaginatedOrders(BaseModel):
    items: List[AdminOrderResponse]
    total: int
    page: int
    pages: int
