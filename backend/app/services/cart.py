from typing import List
from sqlalchemy.orm import Session, joinedload, selectinload
from fastapi import HTTPException, status
from app.config import settings
from app.models.cart import CartItem
from app.models.product import Product
from app.services.pricing import to_money, compute_totals

MAX_QTY = 20


def get_cart(db: Session, user_id: int) -> dict:
    rows = (db.query(CartItem)
            .options(joinedload(CartItem.product).selectinload(Product.images))
            .filter(CartItem.user_id == user_id)
            .order_by(CartItem.created_at.desc())
            .all())
    items, subtotal, count = [], to_money(0), 0
    for item in rows:
        p = item.product
        if not p or not p.is_active:
            continue
        line = to_money(p.price * item.quantity)
        items.append({
            "id": item.id,
            "product_id": p.id,
            "product_name": p.name,
            "product_name_mr": p.name_mr,
            "product_slug": p.slug,
            "product_brand": p.brand,
            "product_price": p.price,
            "compare_at_price": p.compare_at_price,
            "product_image": p.primary_image,
            "stock_quantity": p.stock_quantity,
            "quantity": item.quantity,
            "subtotal": line,
        })
        subtotal += line
        count += item.quantity
    totals = compute_totals(subtotal)
    return {"items": items, "total_items": count, **totals,
            "free_shipping_threshold": settings.FREE_SHIPPING_THRESHOLD}


def _active_product(db: Session, product_id: int) -> Product:
    product = db.query(Product).filter(Product.id == product_id, Product.is_active.is_(True)).first()
    if not product:
        raise HTTPException(status.HTTP_404_NOT_FOUND, "Product not found")
    return product


def _check_qty(product: Product, quantity: int):
    if quantity > product.stock_quantity:
        left = product.stock_quantity
        raise HTTPException(status.HTTP_400_BAD_REQUEST,
                            "This item is out of stock" if left == 0 else f"Only {left} left in stock")
    if quantity > MAX_QTY:
        raise HTTPException(status.HTTP_400_BAD_REQUEST, f"You can buy at most {MAX_QTY} of this item")


def add_to_cart(db: Session, user_id: int, product_id: int, quantity: int = 1) -> CartItem:
    product = _active_product(db, product_id)
    existing = db.query(CartItem).filter(CartItem.user_id == user_id, CartItem.product_id == product_id).first()
    new_qty = (existing.quantity if existing else 0) + quantity
    _check_qty(product, new_qty)
    if existing:
        existing.quantity = new_qty
        item = existing
    else:
        item = CartItem(user_id=user_id, product_id=product_id, quantity=quantity)
        db.add(item)
    db.commit()
    return item


def update_cart_item(db: Session, user_id: int, item_id: int, quantity: int):
    item = db.query(CartItem).filter(CartItem.id == item_id, CartItem.user_id == user_id).first()
    if not item:
        raise HTTPException(status.HTTP_404_NOT_FOUND, "Cart item not found")
    if quantity <= 0:
        db.delete(item)
        db.commit()
        return None
    _check_qty(_active_product(db, item.product_id), quantity)
    item.quantity = quantity
    db.commit()
    return item


def remove_from_cart(db: Session, user_id: int, item_id: int):
    deleted = db.query(CartItem).filter(CartItem.id == item_id, CartItem.user_id == user_id).delete()
    if not deleted:
        raise HTTPException(status.HTTP_404_NOT_FOUND, "Cart item not found")
    db.commit()


def clear_cart(db: Session, user_id: int):
    db.query(CartItem).filter(CartItem.user_id == user_id).delete()
    db.commit()


def merge_cart(db: Session, user_id: int, items: List[dict]):
    """Folds a guest (browser) cart into the user's cart after login, capping at stock."""
    for entry in items:
        product = db.query(Product).filter(Product.id == entry["product_id"], Product.is_active.is_(True)).first()
        if not product or product.stock_quantity <= 0:
            continue
        existing = db.query(CartItem).filter(CartItem.user_id == user_id, CartItem.product_id == product.id).first()
        qty = min((existing.quantity if existing else 0) + entry["quantity"], product.stock_quantity, MAX_QTY)
        if existing:
            existing.quantity = qty
        else:
            db.add(CartItem(user_id=user_id, product_id=product.id, quantity=qty))
    db.commit()
