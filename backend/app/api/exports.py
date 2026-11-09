"""Ruta de exportación: POST /api/v1/exports (tarea T034).

Spec, módulo 4; Historia 1 (escenarios 9, 10 y 12) e Historia 3 (escenarios 1 a 3).
1. Lee el JSON con un límite de 3 MB (si se supera, 413 TEXT_TOO_LARGE).
2. Valida el esquema {"text": str, "format": "docx" | "pdf"} (si no cumple, 422).
3. Pide el archivo al servicio de documentos, donde están las reglas del texto.
4. Devuelve los bytes con el tipo MIME real del formato. No guarda nada en el servidor.
"""

from __future__ import annotations

import logging

from fastapi import APIRouter, Request
from fastapi.responses import Response
from pydantic import ValidationError
from starlette.concurrency import run_in_threadpool

from app.api.auth import DocumentUser
from app.api.request_body import read_body_limited
from app.config import MAX_EXPORT_BODY_BYTES
from app.errors import AppError, ErrorCode, request_id_of
from app.schemas import ExportRequest
from app.services.documents.export_service import (
    DOCX_MEDIA_TYPE,
    PDF_MEDIA_TYPE,
    export_document,
)

logger = logging.getLogger("handtext")
router = APIRouter(tags=["Exportación"])

# Descripción del cuerpo JSON para la documentación interactiva (/docs).
_EXPORT_BODY = {
    "requestBody": {
        "required": True,
        "content": {"application/json": {"schema": ExportRequest.model_json_schema()}},
    }
}


@router.post(
    "/exports",
    summary="Generar un archivo Word o PDF con el texto revisado",
    response_class=Response,
    openapi_extra=_EXPORT_BODY,
    responses={
        200: {
            "description": "Archivo generado",
            "content": {DOCX_MEDIA_TYPE: {}, PDF_MEDIA_TYPE: {}},
        }
    },
)
async def create_export(request: Request, user: DocumentUser) -> Response:
    """Genera el archivo con el texto recibido (la última versión confirmada en la app).

    Requiere sesión normal o el secreto local de desarrollo configurado explícitamente.
    """
    raw_body = await read_body_limited(request, MAX_EXPORT_BODY_BYTES, ErrorCode.TEXT_TOO_LARGE)
    try:
        payload = ExportRequest.model_validate_json(raw_body)
    except ValidationError:
        # No se devuelve el detalle de Pydantic porque incluiría el texto enviado.
        raise AppError(ErrorCode.VALIDATION_ERROR) from None

    document = await run_in_threadpool(export_document, payload.text, payload.format)
    logger.info(
        "export user_id=%s format=%s bytes=%d request_id=%s",
        user.id,
        payload.format,
        len(document.content),
        request_id_of(request),
    )
    return Response(
        content=document.content,
        media_type=document.media_type,
        headers={
            "Content-Disposition": f'attachment; filename="handtext.{document.extension}"',
            # El documento es privado: ningún intermediario debe guardarlo en caché.
            "Cache-Control": "no-store",
        },
    )
