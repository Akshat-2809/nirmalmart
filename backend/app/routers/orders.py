from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session
from typing import List
from app.database import get_db
from app.schemas.order import OrderCreate, OrderResponse
from app.services.auth import get_current_user
from app.services.order import create_order_from_cart, get_user_orders, get_order_by_id, cancel_order_by_customer
from app.models.user import User

router = APIRouter(prefix="/api/orders", tags=["Orders"])


@router.post("", response_model=OrderResponse, status_code=status.HTTP_201_CREATED)
def create_order(order_data: OrderCreate, user: User = Depends(get_current_user), db: Session = Depends(get_db)):
    return create_order_from_cart(db, user, order_data)


@router.get("", response_model=List[OrderResponse])
def list_orders(user: User = Depends(get_current_user), db: Session = Depends(get_db)):
    return get_user_orders(db, user.id)


@router.get("/{order_id}", response_model=OrderResponse)
def get_order(order_id: int, user: User = Depends(get_current_user), db: Session = Depends(get_db)):
    order = get_order_by_id(db, order_id, user.id)
    if not order:
        raise HTTPException(status.HTTP_404_NOT_FOUND, "Order not found")
    return order


@router.post("/{order_id}/cancel", response_model=OrderResponse)
def cancel_order(order_id: int, user: User = Depends(get_current_user), db: Session = Depends(get_db)):
    return cancel_order_by_customer(db, order_id, user.id)
