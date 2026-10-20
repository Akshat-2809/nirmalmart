import io
import logging
import os
import uuid
import httpx
from PIL import Image, UnidentifiedImageError
from fastapi import HTTPException, UploadFile, status
from app.config import settings

logger = logging.getLogger("nirmalmart.storage")


def _auth_headers() -> dict:
    # Legacy service_role JWTs use Authorization; newer sb_secret_ keys need apikey. Send both.
    key = settings.SUPABASE_SERVICE_KEY
    return {"Authorization": f"Bearer {key}", "apikey": key}


ALLOWED_FORMATS = {"JPEG": ("jpg", "image/jpeg"), "PNG": ("png", "image/png"), "WEBP": ("webp", "image/webp")}


async def read_image(file: UploadFile) -> tuple[bytes, str, str]:
    """Reads an upload and checks it really is a JPEG/PNG/WebP within the size limit.
    Returns (bytes, extension, mime type) derived from the file contents, not its name."""
    limit = settings.MAX_UPLOAD_MB * 1024 * 1024
    data = await file.read(limit + 1)
    if len(data) > limit:
        raise HTTPException(status.HTTP_413_REQUEST_ENTITY_TOO_LARGE, f"Image must be under {settings.MAX_UPLOAD_MB} MB")
    try:
        with Image.open(io.BytesIO(data)) as img:
            fmt = img.format
            img.verify()
    except (UnidentifiedImageError, OSError):
        raise HTTPException(status.HTTP_400_BAD_REQUEST, "File is not a valid image")
    if fmt not in ALLOWED_FORMATS:
        raise HTTPException(status.HTTP_400_BAD_REQUEST, "Only JPEG, PNG and WebP images are allowed")
    ext, mime = ALLOWED_FORMATS[fmt]
    return data, ext, mime


def save_image(data: bytes, ext: str, mime: str, folder: str = "products") -> str:
    """Stores an image and returns its public URL."""
    name = f"{folder}/{uuid.uuid4().hex}.{ext}"
    if settings.STORAGE_BACKEND == "supabase":
        base = settings.SUPABASE_URL.rstrip("/")
        resp = httpx.post(
            f"{base}/storage/v1/object/{settings.SUPABASE_BUCKET}/{name}",
            content=data,
            headers={**_auth_headers(), "Content-Type": mime, "x-upsert": "false"},
            timeout=30,
        )
        if resp.status_code >= 300:
            logger.error("Supabase upload failed (%s): %s", resp.status_code, resp.text[:300])
            raise HTTPException(status.HTTP_502_BAD_GATEWAY, "Image storage upload failed")
        return f"{base}/storage/v1/object/public/{settings.SUPABASE_BUCKET}/{name}"

    path = os.path.join(settings.UPLOAD_DIR, name)
    os.makedirs(os.path.dirname(path), exist_ok=True)
    with open(path, "wb") as f:
        f.write(data)
    return f"/uploads/{name}"


def delete_image(url: str):
    if url.startswith("/uploads/"):
        path = os.path.join(settings.UPLOAD_DIR, url.removeprefix("/uploads/"))
        if os.path.isfile(path):
            os.remove(path)
    elif settings.STORAGE_BACKEND == "supabase" and settings.SUPABASE_URL and url.startswith(
            f"{settings.SUPABASE_URL.rstrip('/')}/storage/v1/object/public/{settings.SUPABASE_BUCKET}/"):
        base = settings.SUPABASE_URL.rstrip("/")
        name = url.split(f"/public/{settings.SUPABASE_BUCKET}/", 1)[-1]
        try:
            resp = httpx.delete(f"{base}/storage/v1/object/{settings.SUPABASE_BUCKET}/{name}", headers=_auth_headers(), timeout=15)
            if resp.status_code >= 300:
                logger.warning("Supabase delete failed for %s (%s): %s", name, resp.status_code, resp.text[:200])
        except httpx.HTTPError:
            logger.exception("Supabase delete failed for %s", name)
