from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session
from sqlalchemy import func
from typing import List
from app.database import get_db
from app.schemas.category import CategoryResponse
from app.models.category import Category
from app.models.product import Product

router = APIRouter(prefix="/api/categories", tags=["Categories"])


def categories_with_counts(db: Session, active_only: bool = True) -> list:
    counts = db.query(Product.category_id, func.count(Product.id)).group_by(Product.category_id)
    if active_only:
        counts = counts.filter(Product.is_active.is_(True))
    count_map = dict(counts.all())
    result = []
    for c in db.query(Category).order_by(Category.sort_order, Category.name).all():
        c.product_count = count_map.get(c.id, 0)
        result.append(c)
    return result


@router.get("", response_model=List[CategoryResponse])
def list_categories(db: Session = Depends(get_db)):
    return categories_with_counts(db)


@router.get("/{slug}", response_model=CategoryResponse)
def get_category(slug: str, db: Session = Depends(get_db)):
    category = db.query(Category).filter(Category.slug == slug).first()
    if not category:
        raise HTTPException(status.HTTP_404_NOT_FOUND, "Category not found")
    return category
