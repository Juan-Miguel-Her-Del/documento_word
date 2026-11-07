"""Ruta de reconocimiento: POST /api/v1/recognitions (tarea T031).

Spec, módulo 2; Historia 1, escenarios 1 y 6 a 8. Pasos:
1. Leer la imagen en memoria con el límite de 10 MB (si se supera, 413).
2. Validarla por su contenido: JPEG/PNG y dimensiones (415 o 400). Se valida antes de
   mirar el proveedor, para que el usuario sepa siempre si el problema es su imagen.
3. Comprobar que el proveedor de OCR está configurado (si no, 503 OCR_NOT_CONFIGURED).
4. Preparar una copia JPEG en memoria para el OCR; lo recibido no se modifica.
5. Llamar al proveedor y distinguir texto, sin texto, tiempo agotado y error del proveedor
   (constitución §5: estos fallos no se confunden con un reconocimiento sin texto).
6. Spec 003 (tarea T205): devolver también las posiciones de las palabras dudosas.

Los registros guardan solo metadatos (formato, dimensiones y cantidad de caracteres).
"""

from __future__ import annotations

import logging

from fastapi import APIRouter, Request
from starlette.concurrency import run_in_threadpool

from app.api.auth import CurrentUser
from app.api.request_body import read_body_limited
from app.config import MAX_IMAGE_BYTES
from app.errors import AppError, ErrorCode, request_id_of
from app.schemas import RecognitionResponse, RecognitionStatus, UncertainWord
from app.services.image_preparation import prepare_for_ocr
from app.services.image_validation import validate_image
from app.services.ocr import (
    OcrInvalidResponseError,
    OcrProvider,
    OcrProviderError,
    OcrTimeoutError,
)

logger = logging.getLogger("handtext")
router = APIRouter(tags=["Reconocimiento"])

# Descripción del cuerpo binario para la documentación interactiva (/docs).
_IMAGE_BODY = {
    "requestBody": {
        "required": True,
        "content": {
            "image/jpeg": {"schema": {"type": "string", "format": "binary"}},
            "image/png": {"schema": {"type": "string", "format": "binary"}},
        },
    }
}


@router.post(
    "/recognitions",
    response_model=RecognitionResponse,
    summary="Reconocer el texto manuscrito de una imagen",
    openapi_extra=_IMAGE_BODY,
)
async def create_recognition(request: Request, user: CurrentUser) -> RecognitionResponse:
    """Valida la imagen, la reconoce con el proveedor y devuelve el texto sin modificarlo.

    [SC-202] `user: CurrentUser` exige una sesión válida antes de leer la imagen (spec 002).
    """
    image_bytes = await read_body_limited(request, MAX_IMAGE_BYTES, ErrorCode.IMAGE_TOO_LARGE)
    # Pillow trabaja con la CPU; se ejecuta en un hilo aparte para no bloquear la API.
    image = await run_in_threadpool(validate_image, image_bytes)

    provider: OcrProvider | None = request.app.state.ocr_provider
    if provider is None:
        raise AppError(ErrorCode.OCR_NOT_CONFIGURED)

    prepared = await run_in_threadpool(prepare_for_ocr, image_bytes)

    try:
        result = await provider.recognize(prepared)
    except OcrTimeoutError:
        raise AppError(ErrorCode.OCR_TIMEOUT) from None
    except OcrInvalidResponseError:
        raise AppError(ErrorCode.OCR_INVALID_RESPONSE) from None
    except OcrProviderError:
        raise AppError(ErrorCode.OCR_PROVIDER_ERROR) from None

    # Un resultado vacío o solo con espacios es «sin texto», nunca un documento vacío
    # presentado como éxito (Historia 1, escenario 7).
    has_text = bool(result.text.strip())
    request_id = request_id_of(request)
    # Spec 003: las posiciones de las palabras dudosas solo tienen sentido si hay texto.
    uncertain = (
        [UncertainWord(start=span.start, end=span.end) for span in result.uncertain_spans]
        if has_text
        else []
    )
    logger.info(
        "recognition user_id=%s format=%s width=%d height=%d has_text=%s chars=%d "
        "uncertain=%d request_id=%s",
        user.id,
        image.format,
        image.width,
        image.height,
        has_text,
        len(result.text),
        len(uncertain),
        request_id,
    )
    return RecognitionResponse(
        status=RecognitionStatus.TEXT_FOUND if has_text else RecognitionStatus.NO_TEXT,
        # Fidelidad (constitución §3): se devuelve el texto tal como lo entregó el proveedor.
        text=result.text if has_text else "",
        uncertain_words=uncertain,
        request_id=request_id,
    )
