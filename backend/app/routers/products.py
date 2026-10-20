from fastapi import APIRouter, Depends, HTTPException, Query, status
from sqlalchemy.orm import Session
from typing import Optional, List
from app.database import get_db
from app.schemas.product import ProductResponse, PaginatedProducts, ProductListResponse, ProductFacets
from app.services.product import get_products, get_product_by_slug, get_related, get_facets, SORTS

router = APIRouter(prefix="/api/products", tags=["Products"])


@router.get("", response_model=PaginatedProducts)
def list_products(
    page: int = Query(1, ge=1),
    per_page: int = Query(12, ge=1, le=48),
    category: Optional[str] = Query(None, description="Category id or slug"),
    category_id: Optional[int] = None,
    search: Optional[str] = Query(None, max_length=100),
    brand: Optional[List[str]] = Query(None),
    min_price: Optional[float] = Query(None, ge=0),
    max_price: Optional[float] = Query(None, ge=0),
    in_stock: bool = False,
    min_rating: Optional[float] = Query(None, ge=0, le=5),
    featured: Optional[bool] = None,
    trending: Optional[bool] = None,
    sort_by: str = Query("newest", pattern=f"^({'|'.join(SORTS)})$"),
    db: Session = Depends(get_db),
):
    return get_products(db, page, per_page, sort_by, category=category or category_id, search=search,
                        brands=brand, min_price=min_price, max_price=max_price, in_stock=in_stock,
                        min_rating=min_rating, featured=featured, trending=trending)


@router.get("/facets", response_model=ProductFacets)
def product_facets(category: Optional[str] = None, search: Optional[str] = None, db: Session = Depends(get_db)):
    return get_facets(db, category, search)


@router.get("/suggest", response_model=List[ProductListResponse])
def suggest(q: str = Query(..., min_length=1, max_length=100), db: Session = Depends(get_db)):
    return get_products(db, 1, 6, "popular", search=q)["items"]


@router.get("/{slug}", response_model=ProductResponse)
def get_product(slug: str, db: Session = Depends(get_db)):
    product = get_product_by_slug(db, slug)
    if not product:
        raise HTTPException(status.HTTP_404_NOT_FOUND, "Product not found")
    return product


@router.get("/{slug}/related", response_model=List[ProductListResponse])
def related_products(slug: str, db: Session = Depends(get_db)):
    product = get_product_by_slug(db, slug)
    if not product:
        raise HTTPException(status.HTTP_404_NOT_FOUND, "Product not found")
    return get_related(db, product)
