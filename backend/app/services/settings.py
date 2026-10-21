from sqlalchemy.orm import Session
from app.models.setting import StoreSetting
from app.schemas.setting import StoreSettings, StoreSettingsUpdate


def get_settings(db: Session) -> StoreSettings:
    stored = {s.key: s.value for s in db.query(StoreSetting).all()}
    return StoreSettings(**{k: v for k, v in stored.items() if k in StoreSettings.model_fields})


def update_settings(db: Session, body: StoreSettingsUpdate) -> StoreSettings:
    for key, value in body.model_dump(exclude_none=True).items():
        row = db.get(StoreSetting, key)
        if row:
            row.value = value
        else:
            db.add(StoreSetting(key=key, value=value))
    db.commit()
    return get_settings(db)
