from fastapi import APIRouter, Depends
from sqlalchemy.orm import Session
from app.database import get_db
from app.schemas.setting import StoreSettings
from app.services.settings import get_settings

router = APIRouter(prefix="/api/settings", tags=["Settings"])


@router.get("", response_model=StoreSettings)
def public_settings(db: Session = Depends(get_db)):
    return get_settings(db)
