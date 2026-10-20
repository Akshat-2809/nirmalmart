import math
from typing import Optional, List
from sqlalchemy.orm import Session, selectinload, joinedload
from sqlalchemy import or_, func, cast, String, case
from slugify import slugify
from fastapi import HTTPException, status
from app.models.product import Product, ProductImage
from app.models.category import Category
from app.models.order import OrderItem
from app.models.review import Review
from app.schemas.product import ProductCreate, ProductUpdate
from app.services.pricing import to_money

SORTS = ("newest", "price_low", "price_high", "rating", "popular", "discount", "name")


def unique_slug(db: Session, name: str, exclude_id: Optional[int] = None) -> str:
    base = slugify(name)[:240] or "product"
    slug, n = base, 2
    while True:
        q = db.query(Product.id).filter(Product.slug == slug)
        if exclude_id:
            q = q.filter(Product.id != exclude_id)
        if not q.first():
            return slug
        slug = f"{base}-{n}"
        n += 1


def _category_ids(db: Session, category: str) -> List[int]:
    """Accepts an id or slug; includes direct sub-categories."""
    q = db.query(Category)
    cat = q.filter(Category.id == int(category)).first() if category.isdigit() else q.filter(Category.slug == category).first()
    if not cat:
        return [-1]
    return [cat.id] + [c.id for c in cat.children]


def _base_query(db: Session, include_inactive: bool = False):
    q = db.query(Product).options(selectinload(Product.images), joinedload(Product.category))
    if not include_inactive:
        q = q.filter(Product.is_active.is_(True))
    return q


def _apply_filters(db, query, category=None, search=None, brands=None, min_price=None,
                   max_price=None, in_stock=False, min_rating=None, featured=None):
    if category:
        query = query.filter(Product.category_id.in_(_category_ids(db, str(category))))
    if search:
        term = f"%{search.strip()}%"
        query = query.filter(or_(
            Product.name.ilike(term),
            Product.brand.ilike(term),
            Product.description.ilike(term),
            cast(Product.ai_tags, String).ilike(term),
        ))
    if brands:
        query = query.filter(Product.brand.in_(brands))
    if min_price is not None:
        query = query.filter(Product.price >= min_price)
    if max_price is not None:
        query = query.filter(Product.price <= max_price)
    if in_stock:
        query = query.filter(Product.stock_quantity > 0)
    if min_rating:
        query = query.filter(Product.rating_avg >= min_rating)
    if featured is not None:
        query = query.filter(Product.is_featured.is_(featured))
    return query


def get_products(db: Session, page: int = 1, per_page: int = 12, sort_by: str = "newest",
                 include_inactive: bool = False, **filters) -> dict:
    query = _apply_filters(db, _base_query(db, include_inactive), **filters)

    discount = case(
        (Product.compare_at_price > Product.price,
         (Product.compare_at_price - Product.price) / Product.compare_at_price),
        else_=0,
    )
    order = {
        "price_low": [Product.price.asc()],
        "price_high": [Product.price.desc()],
        "rating": [Product.rating_avg.desc(), Product.rating_count.desc()],
        "popular": [Product.sold_count.desc(), Product.rating_count.desc()],
        "discount": [discount.desc()],
        "name": [Product.name.asc()],
    }.get(sort_by, [Product.created_at.desc()])
    query = query.order_by(*order, Product.id.desc())

    total = query.order_by(None).count()
    pages = max(1, math.ceil(total / per_page))
    items = query.offset((page - 1) * per_page).limit(per_page).all()
    return {"items": items, "total": total, "page": page, "pages": pages, "per_page": per_page}


def get_facets(db: Session, category: Optional[str] = None, search: Optional[str] = None) -> dict:
    query = _apply_filters(db, db.query(Product).filter(Product.is_active.is_(True)), category=category, search=search)
    brands = [b for (b,) in query.with_entities(Product.brand).filter(Product.brand.isnot(None)).distinct().order_by(Product.brand).all()]
    lo, hi = query.with_entities(func.min(Product.price), func.max(Product.price)).one()
    return {"brands": brands, "min_price": float(lo or 0), "max_price": float(hi or 0)}


def get_product_by_slug(db: Session, slug: str) -> Optional[Product]:
    return _base_query(db).filter(Product.slug == slug).first()


def get_product_by_id(db: Session, product_id: int) -> Optional[Product]:
    return _base_query(db, include_inactive=True).filter(Product.id == product_id).first()


def get_related(db: Session, product: Product, limit: int = 8) -> list:
    q = _base_query(db).filter(Product.id != product.id)
    if product.category_id:
        q = q.filter(Product.category_id == product.category_id)
    return q.order_by(Product.rating_avg.desc(), Product.sold_count.desc()).limit(limit).all()


def _validate(db: Session, data: dict, product_id: Optional[int] = None):
    if data.get("sku"):
        q = db.query(Product.id).filter(Product.sku == data["sku"])
        if product_id:
            q = q.filter(Product.id != product_id)
        if q.first():
            raise HTTPException(status.HTTP_400_BAD_REQUEST, "A product with this SKU already exists")
    if data.get("category_id") and not db.get(Category, data["category_id"]):
        raise HTTPException(status.HTTP_400_BAD_REQUEST, "Category not found")
    for key in ("price", "compare_at_price"):
        if data.get(key) is not None:
            data[key] = to_money(data[key])


def create_product(db: Session, product_data: ProductCreate) -> Product:
    data = product_data.model_dump()
    _validate(db, data)
    product = Product(**data, slug=unique_slug(db, data["name"]))
    db.add(product)
    db.commit()
    return get_product_by_id(db, product.id)


def update_product(db: Session, product_id: int, product_data: ProductUpdate) -> Optional[Product]:
    product = db.get(Product, product_id)
    if not product:
        return None
    data = product_data.model_dump(exclude_unset=True)
    _validate(db, data, product_id)
    if "name" in data and data["name"] != product.name:
        data["slug"] = unique_slug(db, data["name"], exclude_id=product_id)
    for key, value in data.items():
        setattr(product, key, value)
    db.commit()
    return get_product_by_id(db, product_id)


def delete_product(db: Session, product_id: int) -> Optional[str]:
    """Hard-deletes unsold products; products with order history are archived instead."""
    product = db.get(Product, product_id)
    if not product:
        return None
    if db.query(OrderItem.id).filter(OrderItem.product_id == product_id).first():
        product.is_active = False
        db.commit()
        return "archived"
    db.delete(product)
    db.commit()
    return "deleted"


def add_product_image(db: Session, product_id: int, image_url: str, alt_text: str = None, is_primary: bool = False) -> ProductImage:
    has_images = db.query(ProductImage.id).filter(ProductImage.product_id == product_id).first() is not None
    if is_primary or not has_images:
        is_primary = True
        db.query(ProductImage).filter(ProductImage.product_id == product_id).update({"is_primary": False})
    next_order = (db.query(func.max(ProductImage.sort_order)).filter(ProductImage.product_id == product_id).scalar() or 0) + 1
    image = ProductImage(product_id=product_id, image_url=image_url, alt_text=alt_text,
                         is_primary=is_primary, sort_order=next_order)
    db.add(image)
    db.commit()
    db.refresh(image)
    return image


def recalculate_rating(db: Session, product_id: int):
    avg, count = db.query(func.avg(Review.rating), func.count(Review.id)).filter(Review.product_id == product_id).one()
    product = db.get(Product, product_id)
    if product:
        product.rating_avg = round(float(avg or 0), 2)
        product.rating_count = count or 0
