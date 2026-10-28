from datetime import datetime, timedelta, timezone
from typing import Optional, List
from fastapi import APIRouter, Depends, HTTPException, status, UploadFile, File, Form, Query
from sqlalchemy.orm import Session
from sqlalchemy import func, cast, Date
from slugify import slugify
from app.database import get_db
from app.schemas.product import ProductCreate, ProductUpdate, ProductResponse, PaginatedProducts, ProductImageResponse
from app.schemas.category import CategoryCreate, CategoryUpdate, CategoryResponse
from app.schemas.order import AdminOrderResponse, OrderStatusUpdate, PaginatedOrders, ShipOrderRequest
from app.schemas.user import AdminUserUpdate
from app.schemas.ai_product import AIProductGenerationResponse
from app.services.auth import require_admin
from app.services import product as product_service
from app.services.order import get_all_orders, get_order_by_id, update_order_status, _with_customer
from app.services import shiprocket
from app.services.ai import generate_product_listing
from app.services.settings import get_settings, update_settings
from app.schemas.setting import StoreSettings, StoreSettingsUpdate
from app.services.storage import read_image, save_image, delete_image
from app.routers.categories import categories_with_counts
from app.models.user import User
from app.models.product import Product, ProductImage
from app.models.order import Order, OrderItem, ORDER_STATUSES
from app.models.category import Category

router = APIRouter(prefix="/api/admin", tags=["Admin"], dependencies=[Depends(require_admin)])

LOW_STOCK = 10


# ─── Dashboard ───

@router.get("/dashboard")
def dashboard(days: int = Query(30, ge=7, le=365), db: Session = Depends(get_db)):
    live = Order.status != "cancelled"
    since = datetime.now(timezone.utc) - timedelta(days=days - 1)
    since = since.replace(hour=0, minute=0, second=0, microsecond=0)

    revenue = db.query(func.coalesce(func.sum(Order.total_amount), 0)).filter(live).scalar()
    period_revenue = db.query(func.coalesce(func.sum(Order.total_amount), 0)).filter(live, Order.created_at >= since).scalar()
    period_orders = db.query(func.count(Order.id)).filter(Order.created_at >= since).scalar()

    day = cast(Order.created_at, Date)
    daily = dict((d, (float(r), n)) for d, r, n in db.query(day, func.sum(Order.total_amount), func.count(Order.id))
                 .filter(live, Order.created_at >= since).group_by(day).all())
    series = []
    for i in range(days):
        d = (since + timedelta(days=i)).date()
        r, n = daily.get(d, (0.0, 0))
        series.append({"date": d.isoformat(), "revenue": round(r, 2), "orders": n})

    by_status = dict(db.query(Order.status, func.count(Order.id)).group_by(Order.status).all())

    top_products = (db.query(OrderItem.product_id, OrderItem.product_name,
                             func.sum(OrderItem.quantity).label("units"), func.sum(OrderItem.subtotal).label("revenue"))
                    .join(Order).filter(live).group_by(OrderItem.product_id, OrderItem.product_name)
                    .order_by(func.sum(OrderItem.subtotal).desc()).limit(5).all())

    top_customers = (db.query(User.full_name, User.email, func.count(Order.id), func.sum(Order.total_amount))
                     .join(Order, Order.user_id == User.id).filter(live).group_by(User.id)
                     .order_by(func.sum(Order.total_amount).desc()).limit(5).all())

    low_stock = (db.query(Product).filter(Product.is_active.is_(True), Product.stock_quantity <= LOW_STOCK)
                 .order_by(Product.stock_quantity).limit(8).all())

    recent = (db.query(Order).order_by(Order.created_at.desc()).limit(6).all())

    return {
        "stats": {
            "total_revenue": float(revenue),
            "period_revenue": float(period_revenue),
            "period_orders": period_orders,
            "total_orders": db.query(func.count(Order.id)).scalar(),
            "pending_orders": by_status.get("pending", 0),
            "total_products": db.query(func.count(Product.id)).filter(Product.is_active.is_(True)).scalar(),
            "total_customers": db.query(func.count(User.id)).filter(User.role == "customer").scalar(),
            "low_stock_count": db.query(func.count(Product.id)).filter(Product.is_active.is_(True), Product.stock_quantity <= LOW_STOCK).scalar(),
        },
        "revenue_series": series,
        "orders_by_status": {s: by_status.get(s, 0) for s in ORDER_STATUSES},
        "top_products": [{"product_id": pid, "name": n, "units": int(u), "revenue": float(r)} for pid, n, u, r in top_products],
        "top_customers": [{"name": n, "email": e, "orders": c, "spend": float(s)} for n, e, c, s in top_customers],
        "low_stock": [{"id": p.id, "name": p.name, "slug": p.slug, "stock": p.stock_quantity, "image": p.primary_image} for p in low_stock],
        "recent_orders": [{"id": o.id, "order_number": o.order_number, "customer": o.user.full_name if o.user else None,
                           "total_amount": float(o.total_amount), "status": o.status, "created_at": o.created_at.isoformat()}
                          for o in recent],
    }


# ─── Users ───

@router.get("/users")
def list_users(search: Optional[str] = None, db: Session = Depends(get_db)):
    order_stats = dict((uid, (n, float(s))) for uid, n, s in
                       db.query(Order.user_id, func.count(Order.id), func.coalesce(func.sum(Order.total_amount), 0))
                       .filter(Order.status != "cancelled").group_by(Order.user_id).all())
    q = db.query(User)
    if search:
        term = f"%{search}%"
        q = q.filter(User.email.ilike(term) | User.full_name.ilike(term))
    return [{
        "id": u.id, "email": u.email, "full_name": u.full_name, "phone": u.phone, "role": u.role,
        "is_active": u.is_active, "created_at": u.created_at.isoformat() if u.created_at else None,
        "orders": order_stats.get(u.id, (0, 0))[0], "spend": order_stats.get(u.id, (0, 0))[1],
    } for u in q.order_by(User.created_at.desc()).all()]


@router.patch("/users/{user_id}")
def update_user(user_id: int, body: AdminUserUpdate, admin: User = Depends(require_admin), db: Session = Depends(get_db)):
    user = db.get(User, user_id)
    if not user:
        raise HTTPException(status.HTTP_404_NOT_FOUND, "User not found")
    if user.id == admin.id:
        raise HTTPException(status.HTTP_400_BAD_REQUEST, "You can't change your own role or status")
    for key, value in body.model_dump(exclude_unset=True).items():
        setattr(user, key, value)
    db.commit()
    return {"message": "User updated"}


# ─── Products ───

@router.get("/products", response_model=PaginatedProducts)
def list_products(
    page: int = Query(1, ge=1), per_page: int = Query(20, ge=1, le=100),
    search: Optional[str] = None, category: Optional[str] = None,
    sort_by: str = "newest", db: Session = Depends(get_db),
):
    return product_service.get_products(db, page, per_page, sort_by, include_inactive=True, search=search, category=category)


@router.get("/products/{product_id}", response_model=ProductResponse)
def get_product(product_id: int, db: Session = Depends(get_db)):
    product = product_service.get_product_by_id(db, product_id)
    if not product:
        raise HTTPException(status.HTTP_404_NOT_FOUND, "Product not found")
    return product


@router.post("/products", response_model=ProductResponse, status_code=status.HTTP_201_CREATED)
def create_product(body: ProductCreate, db: Session = Depends(get_db)):
    return product_service.create_product(db, body)


@router.put("/products/{product_id}", response_model=ProductResponse)
def update_product(product_id: int, body: ProductUpdate, db: Session = Depends(get_db)):
    product = product_service.update_product(db, product_id, body)
    if not product:
        raise HTTPException(status.HTTP_404_NOT_FOUND, "Product not found")
    return product


@router.delete("/products/{product_id}")
def delete_product(product_id: int, db: Session = Depends(get_db)):
    result = product_service.delete_product(db, product_id)
    if not result:
        raise HTTPException(status.HTTP_404_NOT_FOUND, "Product not found")
    if result == "archived":
        return {"message": "Product has order history, so it was hidden from the store instead of deleted", "result": result}
    return {"message": "Product deleted", "result": result}


@router.post("/products/{product_id}/images", response_model=ProductImageResponse)
async def upload_product_image(product_id: int, file: UploadFile = File(...), is_primary: bool = Form(False),
                               db: Session = Depends(get_db)):
    if not db.get(Product, product_id):
        raise HTTPException(status.HTTP_404_NOT_FOUND, "Product not found")
    data, ext, mime = await read_image(file)
    url = save_image(data, ext, mime)
    return product_service.add_product_image(db, product_id, url, (file.filename or "")[:255] or None, is_primary)


@router.put("/products/{product_id}/images/{image_id}/primary", response_model=ProductImageResponse)
def set_primary_image(product_id: int, image_id: int, db: Session = Depends(get_db)):
    image = db.query(ProductImage).filter_by(id=image_id, product_id=product_id).first()
    if not image:
        raise HTTPException(status.HTTP_404_NOT_FOUND, "Image not found")
    db.query(ProductImage).filter(ProductImage.product_id == product_id).update({"is_primary": False})
    image.is_primary = True
    db.commit()
    db.refresh(image)
    return image


@router.delete("/products/{product_id}/images/{image_id}")
def delete_product_image(product_id: int, image_id: int, db: Session = Depends(get_db)):
    image = db.query(ProductImage).filter_by(id=image_id, product_id=product_id).first()
    if not image:
        raise HTTPException(status.HTTP_404_NOT_FOUND, "Image not found")
    url, was_primary = image.image_url, image.is_primary
    db.delete(image)
    db.flush()
    if was_primary:
        nxt = db.query(ProductImage).filter_by(product_id=product_id).order_by(ProductImage.sort_order).first()
        if nxt:
            nxt.is_primary = True
    db.commit()
    delete_image(url)
    return {"message": "Image deleted"}


@router.post("/ai/generate-listing", response_model=AIProductGenerationResponse)
async def ai_generate_listing(file: UploadFile = File(...), hints: Optional[str] = Form(None), db: Session = Depends(get_db)):
    data, _, mime = await read_image(file)
    categories = [name for (name,) in db.query(Category.name).order_by(Category.sort_order).all()]
    return await generate_product_listing(data, mime, categories, hints)


# ─── Orders ───

@router.get("/orders", response_model=PaginatedOrders)
def list_orders(page: int = Query(1, ge=1), per_page: int = Query(20, ge=1, le=100),
                status_filter: Optional[str] = Query(None, alias="status"), search: Optional[str] = None,
                db: Session = Depends(get_db)):
    return get_all_orders(db, page, per_page, status_filter, search)


@router.put("/orders/{order_id}/status", response_model=AdminOrderResponse)
def set_order_status(order_id: int, body: OrderStatusUpdate, db: Session = Depends(get_db)):
    return _with_customer(update_order_status(db, order_id, body.status))


# ───────────── Shiprocket shipping ─────────────

def _order_or_404(db: Session, order_id: int):
    order = get_order_by_id(db, order_id)
    if not order:
        raise HTTPException(status.HTTP_404_NOT_FOUND, "Order not found")
    return order


def _shiprocket(fn, *args):
    try:
        return fn(*args)
    except shiprocket.ShiprocketError as e:
        raise HTTPException(status.HTTP_502_BAD_GATEWAY, str(e))


@router.get("/shipping/status")
def shipping_status():
    return shiprocket.connection_status()


@router.get("/orders/{order_id}/couriers")
def order_couriers(order_id: int, weight: float = Query(..., gt=0, le=100), cod: bool = False, db: Session = Depends(get_db)):
    order = _order_or_404(db, order_id)
    pincode = (order.shipping_address or {}).get("postal_code")
    if not pincode:
        raise HTTPException(status.HTTP_400_BAD_REQUEST, "This order has no delivery pincode")
    return _shiprocket(shiprocket.courier_options, pincode, weight, cod)


@router.post("/orders/{order_id}/ship", response_model=AdminOrderResponse)
def ship_order(order_id: int, body: ShipOrderRequest, db: Session = Depends(get_db)):
    pkg = body.model_dump(include={"weight", "length", "breadth", "height"})
    return _with_customer(shiprocket.ship_order(db, _order_or_404(db, order_id), pkg, body.cod, body.courier_id))


@router.post("/orders/{order_id}/shipment/label", response_model=AdminOrderResponse)
def shipment_label(order_id: int, db: Session = Depends(get_db)):
    return _with_customer(shiprocket.retry_label_and_pickup(db, _order_or_404(db, order_id)))


@router.post("/orders/{order_id}/shipment/refresh", response_model=AdminOrderResponse)
def shipment_refresh(order_id: int, db: Session = Depends(get_db)):
    return _with_customer(shiprocket.refresh_tracking(db, _order_or_404(db, order_id)))


@router.post("/orders/{order_id}/shipment/cancel", response_model=AdminOrderResponse)
def shipment_cancel(order_id: int, db: Session = Depends(get_db)):
    return _with_customer(shiprocket.cancel_shipment(db, _order_or_404(db, order_id)))


# ─── Categories ───

def _unique_category_slug(db: Session, name: str, exclude_id: Optional[int] = None) -> str:
    base = slugify(name) or "category"
    slug, n = base, 2
    while True:
        q = db.query(Category.id).filter(Category.slug == slug)
        if exclude_id:
            q = q.filter(Category.id != exclude_id)
        if not q.first():
            return slug
        slug, n = f"{base}-{n}", n + 1


@router.get("/categories", response_model=List[CategoryResponse])
def list_categories(db: Session = Depends(get_db)):
    return categories_with_counts(db, active_only=False)


@router.post("/categories", response_model=CategoryResponse, status_code=status.HTTP_201_CREATED)
def create_category(body: CategoryCreate, db: Session = Depends(get_db)):
    category = Category(**body.model_dump(), slug=_unique_category_slug(db, body.name))
    db.add(category)
    db.commit()
    db.refresh(category)
    return category


@router.put("/categories/{category_id}", response_model=CategoryResponse)
def update_category(category_id: int, body: CategoryUpdate, db: Session = Depends(get_db)):
    category = db.get(Category, category_id)
    if not category:
        raise HTTPException(status.HTTP_404_NOT_FOUND, "Category not found")
    data = body.model_dump(exclude_unset=True)
    if data.get("parent_id") == category_id:
        raise HTTPException(status.HTTP_400_BAD_REQUEST, "A category can't be its own parent")
    if "name" in data and data["name"] != category.name:
        data["slug"] = _unique_category_slug(db, data["name"], category_id)
    for key, value in data.items():
        setattr(category, key, value)
    db.commit()
    db.refresh(category)
    return category


@router.post("/categories/{category_id}/image", response_model=CategoryResponse)
async def upload_category_image(category_id: int, file: UploadFile = File(...), db: Session = Depends(get_db)):
    category = db.get(Category, category_id)
    if not category:
        raise HTTPException(status.HTTP_404_NOT_FOUND, "Category not found")
    data, ext, mime = await read_image(file)
    old = category.image_url
    category.image_url = save_image(data, ext, mime, folder="categories")
    db.commit()
    db.refresh(category)
    if old:
        delete_image(old)  # only removes files we stored; external URLs are left alone
    return category


@router.delete("/categories/{category_id}")
def delete_category(category_id: int, db: Session = Depends(get_db)):
    category = db.get(Category, category_id)
    if not category:
        raise HTTPException(status.HTTP_404_NOT_FOUND, "Category not found")
    # Products and sub-categories are detached (ON DELETE SET NULL), never deleted
    db.query(Product).filter(Product.category_id == category_id).update({"category_id": None})
    db.query(Category).filter(Category.parent_id == category_id).update({"parent_id": None})
    db.delete(category)
    db.commit()
    return {"message": "Category deleted"}


# ─── Store settings ───

@router.get("/settings", response_model=StoreSettings)
def admin_settings(db: Session = Depends(get_db)):
    return get_settings(db)


@router.put("/settings", response_model=StoreSettings)
def admin_update_settings(body: StoreSettingsUpdate, db: Session = Depends(get_db)):
    return update_settings(db, body)
