from typing import Optional
from pydantic import BaseModel


class StoreSettings(BaseModel):
    show_banner: bool = True
    cod_enabled: bool = False   # cash on delivery is hidden until the owner switches it on


class StoreSettingsUpdate(BaseModel):
    show_banner: Optional[bool] = None
    cod_enabled: Optional[bool] = None
