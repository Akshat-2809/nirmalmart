from pydantic import BaseModel, Field
from typing import List, Optional
from app.schemas.common import Money


class CartItemCreate(BaseModel):
    product_id: int
    quantity: int = Field(1, ge=1, le=20)


class CartItemUpdate(BaseModel):
    quantity: int = Field(..., ge=0, le=20)


class CartMergeItem(BaseModel):
    product_id: int
    quantity: int = Field(..., ge=1, le=20)


class CartMerge(BaseModel):
    items: List[CartMergeItem]


class CartItemResponse(BaseModel):
    id: int
    product_id: int
    product_name: str
    product_name_mr: Optional[str] = None
    product_slug: str
    product_brand: Optional[str] = None
    product_price: Money
    compare_at_price: Optional[Money] = None
    product_image: Optional[str] = None
    stock_quantity: int
    quantity: int
    subtotal: Money


class CartResponse(BaseModel):
    items: List[CartItemResponse]
    total_items: int
    subtotal: Money
    tax_amount: Money
    shipping_amount: Money
    total_amount: Money
    free_shipping_threshold: float
