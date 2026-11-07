"""Validación de imágenes por su contenido (tarea T027).

Spec, módulo 1 (Clarifications 2026-10-26): JPEG y PNG, hasta 10 MB y de 600 a 10 000
píxeles por lado. Constitución §5: la imagen se comprueba por su contenido, no por su
extensión.

Orden de las comprobaciones, de la más barata a la más costosa:
1. Tamaño en bytes (413 IMAGE_TOO_LARGE).
2. Firma de los primeros bytes: ¿empieza como un JPEG o un PNG? (415).
3. Pillow lee el encabezado y confirma el formato y las dimensiones (400).
Los píxeles se decodifican al preparar la copia para el OCR (image_preparation.py); si
falla allí, también se responde IMAGE_UNREADABLE.
"""

from __future__ import annotations

import io
from dataclasses import dataclass

from PIL import Image, UnidentifiedImageError

from app.config import MAX_IMAGE_BYTES, MAX_IMAGE_SIDE_PX, MIN_IMAGE_SIDE_PX
from app.errors import AppError, ErrorCode

# Pillow se protege de las «bombas de descompresión»: imágenes que declaran dimensiones
# gigantes para agotar la memoria. Su umbral se ajusta al máximo acordado de
# 10 000 × 10 000 px; muy por encima de ese valor, Pillow se niega a abrirlas.
Image.MAX_IMAGE_PIXELS = MAX_IMAGE_SIDE_PX * MAX_IMAGE_SIDE_PX

# Firma (primeros bytes) de cada formato admitido.
_SIGNATURES: tuple[tuple[bytes, str], ...] = (
    (b"\xff\xd8\xff", "JPEG"),
    (b"\x89PNG\r\n\x1a\n", "PNG"),
)


@dataclass(frozen=True)
class ValidatedImage:
    """Datos de una imagen que pasó la validación."""

    format: str  # "JPEG" o "PNG"
    width: int
    height: int


def detect_format(data: bytes) -> str | None:
    """Identifica el formato por la firma de los bytes; None si no es JPEG ni PNG."""
    for signature, name in _SIGNATURES:
        if data.startswith(signature):
            return name
    return None


def validate_image(data: bytes) -> ValidatedImage:
    """Aplica las reglas del spec y devuelve el formato y las dimensiones de la imagen."""
    if not data:
        raise AppError(ErrorCode.IMAGE_UNREADABLE)
    if len(data) > MAX_IMAGE_BYTES:
        raise AppError(ErrorCode.IMAGE_TOO_LARGE)

    expected_format = detect_format(data)
    if expected_format is None:
        raise AppError(ErrorCode.UNSUPPORTED_IMAGE_TYPE)

    try:
        # Image.open solo lee el encabezado; todavía no decodifica los píxeles.
        with Image.open(io.BytesIO(data)) as image:
            actual_format = image.format
            width, height = image.size
    except Image.DecompressionBombError:
        raise AppError(ErrorCode.IMAGE_DIMENSIONS_OUT_OF_RANGE) from None
    except (UnidentifiedImageError, OSError, SyntaxError, ValueError):
        raise AppError(ErrorCode.IMAGE_UNREADABLE) from None

    # La firma y el contenido deben coincidir: un archivo «disfrazado» no se acepta.
    if actual_format != expected_format:
        raise AppError(ErrorCode.UNSUPPORTED_IMAGE_TYPE)

    if not (
        MIN_IMAGE_SIDE_PX <= width <= MAX_IMAGE_SIDE_PX
        and MIN_IMAGE_SIDE_PX <= height <= MAX_IMAGE_SIDE_PX
    ):
        raise AppError(ErrorCode.IMAGE_DIMENSIONS_OUT_OF_RANGE)

    return ValidatedImage(format=expected_format, width=width, height=height)
