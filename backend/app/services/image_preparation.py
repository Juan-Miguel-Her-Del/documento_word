"""Preparación de la copia que se envía al OCR (tarea T028; research.md, R3).

Constitución §3, Conservación del original: la preparación trabaja sobre una copia. Esta
función recibe los bytes de la imagen y devuelve bytes nuevos; nunca modifica lo recibido
ni escribe nada en disco.

La copia preparada:
- tiene la orientación EXIF aplicada (las fotos del celular suelen venir «de lado»);
- no conserva metadatos: se eliminan el EXIF y, con él, la ubicación GPS;
- tiene el lado mayor de 3 000 px como máximo, porque una imagen de 10 MB en base64
  superaría el límite de 10 MB por solicitud de Google Cloud Vision;
- se compone sobre fondo blanco si tenía transparencia, para que el texto oscuro siga
  visible;
- se guarda como JPEG de calidad 90.
"""

from __future__ import annotations

import io

from PIL import Image, ImageOps, UnidentifiedImageError

from app.config import OCR_IMAGE_JPEG_QUALITY, OCR_IMAGE_MAX_SIDE_PX
from app.errors import AppError, ErrorCode


def prepare_for_ocr(data: bytes) -> bytes:
    """Devuelve una copia JPEG lista para el OCR, o IMAGE_UNREADABLE si no se puede decodificar."""
    try:
        with Image.open(io.BytesIO(data)) as source:
            # Solo para JPEG: decodifica directamente a una escala menor si la imagen es
            # muy grande. Ahorra memoria y no afecta a las imágenes pequeñas.
            source.draft("RGB", (OCR_IMAGE_MAX_SIDE_PX, OCR_IMAGE_MAX_SIDE_PX))
            # Devuelve una imagen NUEVA con la orientación aplicada (y decodifica los
            # píxeles: aquí se detectan los archivos dañados o incompletos).
            oriented = ImageOps.exif_transpose(source)

        prepared = _flatten_to_rgb(oriented)
        # thumbnail solo reduce (nunca agranda) y mantiene la proporción.
        prepared.thumbnail((OCR_IMAGE_MAX_SIDE_PX, OCR_IMAGE_MAX_SIDE_PX), Image.Resampling.LANCZOS)

        output = io.BytesIO()
        # No se pasa `exif` ni `icc_profile` a save(): la copia sale sin metadatos.
        prepared.save(output, format="JPEG", quality=OCR_IMAGE_JPEG_QUALITY)
        return output.getvalue()
    except (Image.DecompressionBombError, UnidentifiedImageError, OSError, SyntaxError, ValueError):
        raise AppError(ErrorCode.IMAGE_UNREADABLE) from None


def _flatten_to_rgb(image: Image.Image) -> Image.Image:
    """Convierte a RGB; si hay transparencia, la compone sobre un fondo blanco."""
    has_alpha = image.mode in ("RGBA", "LA") or (image.mode == "P" and "transparency" in image.info)
    if not has_alpha:
        return image.convert("RGB")
    rgba = image.convert("RGBA")
    background = Image.new("RGB", rgba.size, "white")
    background.paste(rgba, mask=rgba.getchannel("A"))
    return background
