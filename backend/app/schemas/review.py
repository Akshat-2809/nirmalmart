from pydantic import BaseModel, ConfigDict, Field
from typing import Optional, List, Dict
from datetime import datetime


class ReviewCreate(BaseModel):
    rating: int = Field(..., ge=1, le=5)
    title: Optional[str] = Field(None, max_length=255)
    comment: Optional[str] = Field(None, max_length=3000)


class ReviewResponse(BaseModel):
    model_config = ConfigDict(from_attributes=True)
    id: int
    user_id: int
    user_name: str
    product_id: int
    rating: int
    title: Optional[str] = None
    comment: Optional[str] = None
    is_verified_purchase: bool
    created_at: datetime


class ReviewSummary(BaseModel):
    average: float
    count: int
    distribution: Dict[int, int]
    reviews: List[ReviewResponse]
    can_review: bool = False
