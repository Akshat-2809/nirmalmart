from pydantic import BaseModel, ConfigDict, Field
from typing import Optional, List, Dict
from datetime import datetime
from app.schemas.common import Money


class ProductBase(BaseModel):
    name: str = Field(..., min_length=2, max_length=255)
    name_mr: Optional[str] = Field(None, max_length=255)
    brand: Optional[str] = None
    description: Optional[str] = None
    description_mr: Optional[str] = None
    highlights: Optional[List[str]] = None
    specifications: Optional[Dict[str, str]] = None
    price: float = Field(..., gt=0)
    compare_at_price: Optional[float] = Field(None, gt=0)
    sku: str = Field(..., min_length=1, max_length=100)
    stock_quantity: int = Field(0, ge=0)
    category_id: Optional[int] = None
    is_active: bool = True
    is_featured: bool = False
    is_trending: bool = False
    ai_tags: Optional[List[str]] = None


class ProductCreate(ProductBase):
    pass


class ProductUpdate(BaseModel):
    name: Optional[str] = Field(None, min_length=2, max_length=255)
    name_mr: Optional[str] = Field(None, max_length=255)
    brand: Optional[str] = None
    description: Optional[str] = None
    description_mr: Optional[str] = None
    highlights: Optional[List[str]] = None
    specifications: Optional[Dict[str, str]] = None
    price: Optional[float] = Field(None, gt=0)
    compare_at_price: Optional[float] = Field(None, gt=0)
    sku: Optional[str] = None
    stock_quantity: Optional[int] = Field(None, ge=0)
    category_id: Optional[int] = None
    is_active: Optional[bool] = None
    is_featured: Optional[bool] = None
    is_trending: Optional[bool] = None
    ai_tags: Optional[List[str]] = None


class ProductImageResponse(BaseModel):
    model_config = ConfigDict(from_attributes=True)
    id: int
    image_url: str
    alt_text: Optional[str] = None
    is_primary: bool
    sort_order: int


class CategoryBrief(BaseModel):
    model_config = ConfigDict(from_attributes=True)
    id: int
    name: str
    name_mr: Optional[str] = None
    slug: str


class ProductListResponse(BaseModel):
    model_config = ConfigDict(from_attributes=True)
    id: int
    name: str
    name_mr: Optional[str] = None
    slug: str
    brand: Optional[str] = None
    price: Money
    compare_at_price: Optional[Money] = None
    stock_quantity: int
    is_active: bool
    is_featured: bool
    is_trending: bool = False
    rating_avg: Money
    rating_count: int
    sold_count: int
    category_id: Optional[int] = None
    category: Optional[CategoryBrief] = None
    ai_tags: Optional[list] = None
    images: List[ProductImageResponse] = []
    created_at: datetime


class ProductResponse(ProductListResponse):
    sku: str
    description: Optional[str] = None
    description_mr: Optional[str] = None
    highlights: Optional[List[str]] = None
    specifications: Optional[Dict[str, str]] = None
    ai_generated_description: Optional[str] = None
    updated_at: datetime


class PaginatedProducts(BaseModel):
    items: List[ProductListResponse]
    total: int
    page: int
    pages: int
    per_page: int


class ProductFacets(BaseModel):
    brands: List[str]
    min_price: float
    max_price: float
