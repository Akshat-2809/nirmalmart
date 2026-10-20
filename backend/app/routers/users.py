from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session
from typing import List
from app.database import get_db
from app.schemas.user import UserResponse, UserUpdate, AddressCreate, AddressResponse
from app.services.auth import get_current_user
from app.models.user import User
from app.models.address import Address

router = APIRouter(prefix="/api/users", tags=["Users"])


@router.get("/me", response_model=UserResponse)
def get_profile(user: User = Depends(get_current_user)):
    return user


@router.put("/me", response_model=UserResponse)
def update_profile(body: UserUpdate, user: User = Depends(get_current_user), db: Session = Depends(get_db)):
    for key, value in body.model_dump(exclude_unset=True).items():
        setattr(user, key, value)
    db.commit()
    db.refresh(user)
    return user


def _owned_address(db: Session, user: User, address_id: int) -> Address:
    addr = db.query(Address).filter(Address.id == address_id, Address.user_id == user.id).first()
    if not addr:
        raise HTTPException(status.HTTP_404_NOT_FOUND, "Address not found")
    return addr


def _set_default(db: Session, user: User, addr: Address):
    db.query(Address).filter(Address.user_id == user.id, Address.id != addr.id).update({"is_default": False})
    addr.is_default = True


@router.get("/me/addresses", response_model=List[AddressResponse])
def list_addresses(user: User = Depends(get_current_user), db: Session = Depends(get_db)):
    return (db.query(Address).filter(Address.user_id == user.id)
            .order_by(Address.is_default.desc(), Address.id.desc()).all())


@router.post("/me/addresses", response_model=AddressResponse, status_code=status.HTTP_201_CREATED)
def add_address(body: AddressCreate, user: User = Depends(get_current_user), db: Session = Depends(get_db)):
    is_first = not db.query(Address.id).filter(Address.user_id == user.id).first()
    addr = Address(user_id=user.id, **body.model_dump())
    db.add(addr)
    db.flush()
    if body.is_default or is_first:
        _set_default(db, user, addr)
    db.commit()
    db.refresh(addr)
    return addr


@router.put("/me/addresses/{address_id}", response_model=AddressResponse)
def update_address(address_id: int, body: AddressCreate, user: User = Depends(get_current_user), db: Session = Depends(get_db)):
    addr = _owned_address(db, user, address_id)
    for key, value in body.model_dump().items():
        setattr(addr, key, value)
    if body.is_default:
        _set_default(db, user, addr)
    db.commit()
    db.refresh(addr)
    return addr


@router.delete("/me/addresses/{address_id}")
def delete_address(address_id: int, user: User = Depends(get_current_user), db: Session = Depends(get_db)):
    addr = _owned_address(db, user, address_id)
    was_default = addr.is_default
    db.delete(addr)
    db.flush()
    if was_default:
        nxt = db.query(Address).filter(Address.user_id == user.id).order_by(Address.id.desc()).first()
        if nxt:
            nxt.is_default = True
    db.commit()
    return {"message": "Address deleted"}
