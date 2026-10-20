import logging
from typing import List
from pydantic_settings import BaseSettings, SettingsConfigDict

logger = logging.getLogger("nirmalmart")

DEFAULT_JWT_SECRET = "your-super-secret-jwt-key-change-in-production"


class Settings(BaseSettings):
    model_config = SettingsConfigDict(env_file=".env", extra="allow")

    APP_NAME: str = "NirmalMart"
    APP_ENV: str = "development"
    DATABASE_URL: str = "postgresql://nirmalmart:nirmalmart_secret@db:5432/nirmalmart"

    JWT_SECRET_KEY: str = DEFAULT_JWT_SECRET
    JWT_ALGORITHM: str = "HS256"
    ACCESS_TOKEN_EXPIRE_MINUTES: int = 30
    REFRESH_TOKEN_EXPIRE_DAYS: int = 7

    # Store owner account, created on first start if missing (signs in with username or email)
    ADMIN_USERNAME: str = "nirmalmartadmin"
    ADMIN_EMAIL: str = "admin@nirmalmart.com"
    ADMIN_PASSWORD: str = ""

    GEMINI_API_KEY: str = ""
    GEMINI_MODEL: str = "gemini-2.5-flash"

    RAZORPAY_KEY_ID: str = ""
    RAZORPAY_KEY_SECRET: str = ""

    CORS_ORIGINS: str = "http://localhost:5173,http://localhost:3000"
    UPLOAD_DIR: str = "uploads"
    MAX_UPLOAD_MB: int = 5

    # "local" (dev: files on disk) or "supabase" (prod: Supabase Storage bucket)
    STORAGE_BACKEND: str = "local"
    SUPABASE_URL: str = ""
    SUPABASE_SERVICE_KEY: str = ""
    SUPABASE_BUCKET: str = "product-images"

    # Pricing rules (INR)
    GST_RATE: float = 0.18
    FREE_SHIPPING_THRESHOLD: float = 499.0
    SHIPPING_FEE: float = 49.0

    @property
    def cors_origins_list(self) -> List[str]:
        return [origin.strip() for origin in self.CORS_ORIGINS.split(",") if origin.strip()]

    @property
    def is_production(self) -> bool:
        return self.APP_ENV.lower() == "production"


settings = Settings()

if settings.JWT_SECRET_KEY in (DEFAULT_JWT_SECRET, "generate-a-secure-random-key"):
    if settings.is_production:
        raise RuntimeError("JWT_SECRET_KEY must be set to a strong random value in production")
    logger.warning("JWT_SECRET_KEY is a placeholder; set a strong secret before deploying")
