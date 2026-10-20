from pydantic import BaseModel
from typing import List, Dict, Optional


class AIProductGenerationResponse(BaseModel):
    title: str
    title_mr: Optional[str] = None
    brand: Optional[str] = None
    description: str
    description_mr: Optional[str] = None
    highlights: List[str] = []
    suggested_category: str
    tags: List[str]
    specifications: Dict[str, str]
    estimated_price: float
    is_sample: bool = False
