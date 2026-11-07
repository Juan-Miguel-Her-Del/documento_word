"""Reconocimiento de texto (OCR): contrato, errores y fábrica del proveedor (tarea T030).

`build_ocr_provider` decide qué proveedor usa la API según la configuración: si no hay
clave de Google Cloud Vision devuelve None, y la ruta responde 503 OCR_NOT_CONFIGURED.
"""

from __future__ import annotations

from app.config import OCR_LANGUAGE_HINTS, OCR_TIMEOUT_SECONDS, Settings
from app.services.ocr.base import (
    OcrError,
    OcrInvalidResponseError,
    OcrProvider,
    OcrProviderError,
    OcrResult,
    OcrTimeoutError,
)
from app.services.ocr.google_vision import GoogleVisionOcrProvider

__all__ = [
    "GoogleVisionOcrProvider",
    "OcrError",
    "OcrInvalidResponseError",
    "OcrProvider",
    "OcrProviderError",
    "OcrResult",
    "OcrTimeoutError",
    "build_ocr_provider",
]


def build_ocr_provider(settings: Settings) -> OcrProvider | None:
    """Crea el proveedor configurado, o None si falta la clave."""
    if settings.google_vision_api_key is None:
        return None
    return GoogleVisionOcrProvider(
        api_key=settings.google_vision_api_key,
        language_hints=OCR_LANGUAGE_HINTS,
        timeout_seconds=OCR_TIMEOUT_SECONDS,
    )
