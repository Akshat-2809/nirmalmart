from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session, joinedload
from typing import Optional
from app.database import get_db
from app.schemas.review import ReviewCreate, ReviewResponse, ReviewSummary
from app.services.auth import get_current_user, get_optional_user
from app.services.product import recalculate_rating
from app.models.user import User
from app.models.review import Review
from app.models.product import Product
from app.models.order import Order, OrderItem

router = APIRouter(prefix="/api/products", tags=["Reviews"])


def _has_purchased(db: Session, user_id: int, product_id: int) -> bool:
    return db.query(OrderItem.id).join(Order).filter(
        Order.user_id == user_id, OrderItem.product_id == product_id, Order.status != "cancelled"
    ).first() is not None


def _to_response(r: Review) -> ReviewResponse:
    return ReviewResponse(id=r.id, user_id=r.user_id, user_name=r.user.full_name if r.user else "Customer",
                          product_id=r.product_id, rating=r.rating, title=r.title, comment=r.comment,
                          is_verified_purchase=r.is_verified_purchase, created_at=r.created_at)


@router.get("/{product_id}/reviews", response_model=ReviewSummary)
def get_reviews(product_id: int, user: Optional[User] = Depends(get_optional_user), db: Session = Depends(get_db)):
    reviews = (db.query(Review).options(joinedload(Review.user)).filter(Review.product_id == product_id)
               .order_by(Review.created_at.desc()).all())
    dist = {i: 0 for i in range(1, 6)}
    for r in reviews:
        dist[r.rating] += 1
    count = len(reviews)
    can_review = bool(user) and not any(r.user_id == user.id for r in reviews)
    return ReviewSummary(average=round(sum(r.rating for r in reviews) / count, 2) if count else 0,
                         count=count, distribution=dist, reviews=[_to_response(r) for r in reviews],
                         can_review=can_review)


@router.post("/{product_id}/reviews", response_model=ReviewResponse, status_code=status.HTTP_201_CREATED)
def add_review(product_id: int, body: ReviewCreate, user: User = Depends(get_current_user), db: Session = Depends(get_db)):
    if not db.get(Product, product_id):
        raise HTTPException(status.HTTP_404_NOT_FOUND, "Product not found")
    if db.query(Review.id).filter(Review.user_id == user.id, Review.product_id == product_id).first():
        raise HTTPException(status.HTTP_400_BAD_REQUEST, "You have already reviewed this product")
    review = Review(user_id=user.id, product_id=product_id, rating=body.rating, title=body.title,
                    comment=body.comment, is_verified_purchase=_has_purchased(db, user.id, product_id))
    db.add(review)
    db.flush()
    recalculate_rating(db, product_id)
    db.commit()
    db.refresh(review)
    return _to_response(review)


@router.delete("/{product_id}/reviews/{review_id}")
def delete_review(product_id: int, review_id: int, user: User = Depends(get_current_user), db: Session = Depends(get_db)):
    review = db.query(Review).filter(Review.id == review_id, Review.product_id == product_id).first()
    if not review or (review.user_id != user.id and user.role != "admin"):
        raise HTTPException(status.HTTP_404_NOT_FOUND, "Review not found")
    db.delete(review)
    db.flush()
    recalculate_rating(db, product_id)
    db.commit()
    return {"message": "Review deleted"}
