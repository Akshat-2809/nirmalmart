from typing import Optional
from pydantic import BaseModel


class StoreSettings(BaseModel):
    show_banner: bool = True


class StoreSettingsUpdate(BaseModel):
    show_banner: Optional[bool] = None
