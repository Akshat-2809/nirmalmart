from fastapi import APIRouter, Depends
from sqlalchemy.orm import Session
from app.database import get_db
from app.schemas.cart import CartItemCreate, CartItemUpdate, CartResponse, CartMerge
from app.services.auth import get_current_user
from app.services import cart as cart_service
from app.models.user import User

router = APIRouter(prefix="/api/cart", tags=["Cart"])


@router.get("", response_model=CartResponse)
def get_user_cart(user: User = Depends(get_current_user), db: Session = Depends(get_db)):
    return cart_service.get_cart(db, user.id)


@router.post("/items", response_model=CartResponse, status_code=201)
def add_item(item: CartItemCreate, user: User = Depends(get_current_user), db: Session = Depends(get_db)):
    cart_service.add_to_cart(db, user.id, item.product_id, item.quantity)
    return cart_service.get_cart(db, user.id)


@router.put("/items/{item_id}", response_model=CartResponse)
def update_item(item_id: int, item: CartItemUpdate, user: User = Depends(get_current_user), db: Session = Depends(get_db)):
    cart_service.update_cart_item(db, user.id, item_id, item.quantity)
    return cart_service.get_cart(db, user.id)


@router.delete("/items/{item_id}", response_model=CartResponse)
def remove_item(item_id: int, user: User = Depends(get_current_user), db: Session = Depends(get_db)):
    cart_service.remove_from_cart(db, user.id, item_id)
    return cart_service.get_cart(db, user.id)


@router.post("/merge", response_model=CartResponse)
def merge(body: CartMerge, user: User = Depends(get_current_user), db: Session = Depends(get_db)):
    cart_service.merge_cart(db, user.id, [i.model_dump() for i in body.items])
    return cart_service.get_cart(db, user.id)


@router.delete("", response_model=CartResponse)
def clear(user: User = Depends(get_current_user), db: Session = Depends(get_db)):
    cart_service.clear_cart(db, user.id)
    return cart_service.get_cart(db, user.id)
