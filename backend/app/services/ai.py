import json
import logging
from typing import Optional, List
from fastapi import HTTPException, status
from fastapi.concurrency import run_in_threadpool
from app.config import settings
from app.schemas.ai_product import AIProductGenerationResponse

logger = logging.getLogger("nirmalmart.ai")

PROMPT = """You are a merchandiser for an Indian online marketplace. Analyse the product photo and
write listing data. Respond with JSON only, matching this shape:
{{"title": str (50-80 chars, SEO friendly),
  "brand": str or null (only if clearly visible),
  "description": str (120-250 words, benefit-led, short paragraphs),
  "highlights": [4-6 short bullet strings],
  "suggested_category": one of {categories},
  "tags": [5-8 search tags],
  "specifications": {{"key": "value", ...}},
  "estimated_price": number (retail price in INR)}}"""


def _sample(categories: List[str]) -> AIProductGenerationResponse:
    return AIProductGenerationResponse(
        title="Sample Product Title (add GEMINI_API_KEY for real AI)",
        brand=None,
        description="This is placeholder copy. Add a GEMINI_API_KEY to .env and the AI will write a real "
                    "title, description, highlights and specs from the photo you upload.",
        highlights=["Placeholder highlight one", "Placeholder highlight two", "Placeholder highlight three"],
        suggested_category=categories[0] if categories else "Electronics",
        tags=["sample", "placeholder"],
        specifications={"Material": "—", "Weight": "—"},
        estimated_price=999.0,
        is_sample=True,
    )


def _call_gemini(image_bytes: bytes, content_type: str, prompt: str) -> str:
    from google import genai
    from google.genai import types

    client = genai.Client(api_key=settings.GEMINI_API_KEY)
    response = client.models.generate_content(
        model=settings.GEMINI_MODEL,
        contents=[types.Part.from_bytes(data=image_bytes, mime_type=content_type), prompt],
        config=types.GenerateContentConfig(response_mime_type="application/json", temperature=0.6),
    )
    return response.text


async def generate_product_listing(image_bytes: bytes, content_type: str, categories: List[str],
                                   hints: Optional[str] = None) -> AIProductGenerationResponse:
    if not settings.GEMINI_API_KEY or settings.GEMINI_API_KEY.startswith("your-"):
        return _sample(categories)

    prompt = PROMPT.format(categories=json.dumps(categories or ["Other"]))
    if hints:
        prompt += f"\n\nExtra context from the seller: {hints[:500]}"
    try:
        text = await run_in_threadpool(_call_gemini, image_bytes, content_type, prompt)
        return AIProductGenerationResponse(**json.loads(text))
    except Exception:
        logger.exception("Gemini listing generation failed")
        raise HTTPException(status.HTTP_502_BAD_GATEWAY, "AI generation failed. Please try again.")
