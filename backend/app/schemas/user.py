from pydantic import BaseModel, ConfigDict, Field, EmailStr
from typing import Optional
from datetime import datetime
from app.schemas.common import NAME_PATTERN, CITY_PATTERN, MOBILE_PATTERN, PINCODE_PATTERN


class UserCreate(BaseModel):
    email: EmailStr
    password: str = Field(..., min_length=8, max_length=128)
    full_name: str = Field(..., min_length=2, max_length=100, pattern=NAME_PATTERN)
    phone: Optional[str] = Field(None, pattern=MOBILE_PATTERN)


class UserLogin(BaseModel):
    # Email for customers; staff accounts may also sign in with their username
    email: str = Field(..., min_length=3, max_length=255)
    password: str


class UserResponse(BaseModel):
    model_config = ConfigDict(from_attributes=True)
    id: int
    email: str
    username: Optional[str] = None
    full_name: str
    phone: Optional[str] = None
    role: str
    is_active: bool
    created_at: datetime


class UserUpdate(BaseModel):
    full_name: Optional[str] = Field(None, min_length=2, max_length=100, pattern=NAME_PATTERN)
    phone: Optional[str] = Field(None, pattern=MOBILE_PATTERN)


class PasswordChange(BaseModel):
    current_password: str
    new_password: str = Field(..., min_length=8, max_length=128)


class Token(BaseModel):
    access_token: str
    token_type: str = "bearer"
    refresh_token: Optional[str] = None
    user: Optional[UserResponse] = None


class RefreshRequest(BaseModel):
    refresh_token: str


class AddressBase(BaseModel):
    label: str = Field("Home", max_length=30)
    full_name: str = Field(..., min_length=2, max_length=100, pattern=NAME_PATTERN)
    phone: str = Field(..., pattern=MOBILE_PATTERN)
    address_line1: str = Field(..., min_length=3, max_length=255)
    address_line2: Optional[str] = None
    city: str = Field(..., min_length=2, max_length=100, pattern=CITY_PATTERN)
    state: str = Field(..., min_length=2, max_length=100)
    postal_code: str = Field(..., pattern=PINCODE_PATTERN)
    country: str = "India"
    is_default: bool = False


class AddressCreate(AddressBase):
    pass


class AddressResponse(AddressBase):
    model_config = ConfigDict(from_attributes=True)
    id: int
    full_name: Optional[str] = None
    phone: Optional[str] = None


class AdminUserUpdate(BaseModel):
    role: Optional[str] = Field(None, pattern=r"^(customer|admin)$")
    is_active: Optional[bool] = None
