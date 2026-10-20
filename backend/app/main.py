import logging
import os
from contextlib import asynccontextmanager
from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from fastapi.middleware.gzip import GZipMiddleware
from fastapi.staticfiles import StaticFiles
from sqlalchemy import text
from app.config import settings
from app.database import create_tables, SessionLocal
from app.models.user import User
from app.services.auth import hash_password
from app.routers import auth, products, categories, cart, orders, reviews, users, admin, wishlist

logging.basicConfig(level=logging.INFO)
logger = logging.getLogger("nirmalmart")


def ensure_admin():
    """Creates the store owner account on first start. Never overwrites an existing password."""
    if not settings.ADMIN_PASSWORD:
        logger.warning("ADMIN_PASSWORD is not set; skipping admin account creation")
        return
    db = SessionLocal()
    try:
        username, email = settings.ADMIN_USERNAME.lower(), settings.ADMIN_EMAIL.lower()
        user = db.query(User).filter((User.username == username) | (User.email == email)).first()
        if not user:
            db.add(User(email=email, username=username, password_hash=hash_password(settings.ADMIN_PASSWORD),
                        full_name="NirmalMart Admin", role="admin"))
            db.commit()
            logger.info("Created admin account '%s'", username)
        elif not user.username:
            user.username = username
            db.commit()
    finally:
        db.close()


@asynccontextmanager
async def lifespan(_: FastAPI):
    # Production schema is managed by Alembic (`alembic upgrade head` runs before the server
    # starts); create_all keeps local development zero-setup.
    if not settings.is_production:
        create_tables()
    ensure_admin()
    yield


app = FastAPI(title=f"{settings.APP_NAME} API", description="NirmalMart e-commerce API", version="2.0.0",
              lifespan=lifespan, docs_url=None if settings.is_production else "/docs",
              redoc_url=None)

app.add_middleware(GZipMiddleware, minimum_size=1024)
app.add_middleware(CORSMiddleware, allow_origins=settings.cors_origins_list, allow_credentials=True,
                   allow_methods=["*"], allow_headers=["*"])

os.makedirs(settings.UPLOAD_DIR, exist_ok=True)
app.mount("/uploads", StaticFiles(directory=settings.UPLOAD_DIR), name="uploads")

for r in (auth, products, categories, cart, orders, reviews, users, wishlist, admin):
    app.include_router(r.router)


@app.get("/api/health", tags=["Health"])
def health():
    db = SessionLocal()
    try:
        db.execute(text("SELECT 1"))
        return {"status": "ok"}
    finally:
        db.close()


@app.get("/")
def root():
    return {"message": f"Welcome to {settings.APP_NAME} API", "docs": "/docs"}
