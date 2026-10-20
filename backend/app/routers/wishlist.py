from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session, joinedload, selectinload
from typing import List
from app.database import get_db
from app.schemas.product import ProductListResponse
from app.services.auth import get_current_user
from app.models.user import User
from app.models.product import Product
from app.models.wishlist import WishlistItem

router = APIRouter(prefix="/api/wishlist", tags=["Wishlist"])


def _list(db: Session, user: User):
    rows = (db.query(WishlistItem)
            .options(joinedload(WishlistItem.product).selectinload(Product.images),
                     joinedload(WishlistItem.product).joinedload(Product.category))
            .filter(WishlistItem.user_id == user.id).order_by(WishlistItem.created_at.desc()).all())
    return [r.product for r in rows if r.product and r.product.is_active]


@router.get("", response_model=List[ProductListResponse])
def get_wishlist(user: User = Depends(get_current_user), db: Session = Depends(get_db)):
    return _list(db, user)


@router.post("/{product_id}", response_model=List[ProductListResponse])
def add(product_id: int, user: User = Depends(get_current_user), db: Session = Depends(get_db)):
    if not db.get(Product, product_id):
        raise HTTPException(status.HTTP_404_NOT_FOUND, "Product not found")
    if not db.query(WishlistItem.id).filter_by(user_id=user.id, product_id=product_id).first():
        db.add(WishlistItem(user_id=user.id, product_id=product_id))
        db.commit()
    return _list(db, user)


@router.delete("/{product_id}", response_model=List[ProductListResponse])
def remove(product_id: int, user: User = Depends(get_current_user), db: Session = Depends(get_db)):
    db.query(WishlistItem).filter_by(user_id=user.id, product_id=product_id).delete()
    db.commit()
    return _list(db, user)
