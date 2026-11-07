"""Lectura del cuerpo de una solicitud con límite de tamaño (tarea T009).

El cuerpo se lee por fragmentos y la lectura se corta apenas supera el límite; así no se
carga en memoria un envío enorme. Nada se escribe en disco: por eso la imagen viaja como
cuerpo binario y no como multipart, que guarda en archivos temporales las partes de más
de 1 MB (research.md, R2).
"""

from __future__ import annotations

from fastapi import Request

from app.errors import AppError, ErrorCode


async def read_body_limited(request: Request, max_bytes: int, too_large: ErrorCode) -> bytes:
    """Devuelve el cuerpo completo o lanza `too_large` si supera `max_bytes`."""
    # Si el cliente declara un tamaño mayor al permitido, se rechaza sin leer nada.
    declared = request.headers.get("content-length")
    if declared is not None and declared.isdigit() and int(declared) > max_bytes:
        raise AppError(too_large)

    body = bytearray()
    async for chunk in request.stream():
        body.extend(chunk)
        if len(body) > max_bytes:
            raise AppError(too_large)
    return bytes(body)
