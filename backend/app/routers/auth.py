from fastapi import APIRouter, Depends, HTTPException, Request, status
from pydantic import BaseModel, EmailStr, Field
from app.services import passwords
from sqlalchemy.orm import Session
from app.database import get_db
from app.models.user import User
from app.schemas.user import UserCreate, UserLogin, UserResponse, Token, RefreshRequest, PasswordChange
from app.services.auth import (
    create_user, authenticate_user, create_access_token, verify_token,
    get_current_user, issue_tokens, verify_password, hash_password,
)

router = APIRouter(prefix="/api/auth", tags=["Authentication"])


@router.post("/register", response_model=Token, status_code=status.HTTP_201_CREATED)
def register(user_data: UserCreate, db: Session = Depends(get_db)):
    return issue_tokens(create_user(db, user_data))


@router.post("/login", response_model=Token)
def login(user_data: UserLogin, db: Session = Depends(get_db)):
    user = authenticate_user(db, user_data.email, user_data.password)
    if not user:
        raise HTTPException(status.HTTP_401_UNAUTHORIZED, "Invalid email or password")
    if not user.is_active:
        raise HTTPException(status.HTTP_403_FORBIDDEN, "This account has been disabled")
    return issue_tokens(user)


@router.post("/refresh", response_model=Token)
def refresh(body: RefreshRequest, db: Session = Depends(get_db)):
    payload = verify_token(body.refresh_token)
    if payload.get("type") != "refresh":
        raise HTTPException(status.HTTP_401_UNAUTHORIZED, "Invalid refresh token")
    user = db.get(User, int(payload["sub"]))
    if not user or not user.is_active:
        raise HTTPException(status.HTTP_401_UNAUTHORIZED, "User not found")
    return Token(access_token=create_access_token({"sub": str(user.id)}), refresh_token=body.refresh_token, user=user)


@router.get("/me", response_model=UserResponse)
def get_me(current_user: User = Depends(get_current_user)):
    return current_user


class ForgotIn(BaseModel):
    email: EmailStr


class ResetIn(BaseModel):
    token: str = Field(..., min_length=10, max_length=200)
    new_password: str = Field(..., min_length=8, max_length=128)


@router.post("/forgot-password")
def forgot_password(body: ForgotIn, request: Request, db: Session = Depends(get_db)):
    """Emails a reset link if the address has an account. Always answers the same, so nobody can
    find out which emails are registered."""
    if passwords.too_many(request):
        raise HTTPException(status.HTTP_429_TOO_MANY_REQUESTS, "Too many attempts — please try again in a few minutes")
    passwords.start_reset(db, body.email)
    return {"message": "If that email has an account, we’ve sent a link to reset the password. Check your inbox (and spam)."}


@router.post("/reset-password")
def reset_password(body: ResetIn, db: Session = Depends(get_db)):
    passwords.finish_reset(db, body.token, body.new_password)
    return {"message": "Password updated — you can sign in now"}


@router.post("/change-password")
def change_password(body: PasswordChange, current_user: User = Depends(get_current_user), db: Session = Depends(get_db)):
    if not verify_password(body.current_password, current_user.password_hash):
        raise HTTPException(status.HTTP_400_BAD_REQUEST, "Current password is incorrect")
    current_user.password_hash = hash_password(body.new_password)
    db.commit()
    return {"message": "Password updated"}
