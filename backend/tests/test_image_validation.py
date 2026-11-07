"""Pruebas de la validación de imágenes (tarea T017).

Spec, módulo 1 (Clarifications): JPEG y PNG, hasta 10 MB y de 600 a 10 000 px por lado,
identificadas por su contenido. Historia 1, escenario 1.
"""

from __future__ import annotations

import io

import pytest
from PIL import Image

from app.config import MAX_IMAGE_BYTES
from app.errors import AppError, ErrorCode
from app.services.image_validation import validate_image
from tests.conftest import make_image_bytes, make_png_header_only


def _error_code(data: bytes) -> ErrorCode:
    with pytest.raises(AppError) as raised:
        validate_image(data)
    return raised.value.code


@pytest.mark.parametrize("image_format", ["PNG", "JPEG"])
def test_accepts_png_and_jpeg_within_limits(image_format: str) -> None:
    result = validate_image(make_image_bytes(800, 600, image_format))

    assert (result.format, result.width, result.height) == (image_format, 800, 600)


def test_accepts_the_exact_minimum_of_600_px() -> None:
    assert validate_image(make_image_bytes(600, 600)).width == 600


def test_rejects_a_side_smaller_than_600_px() -> None:
    assert _error_code(make_image_bytes(599, 800)) is ErrorCode.IMAGE_DIMENSIONS_OUT_OF_RANGE


def test_rejects_a_side_larger_than_10000_px() -> None:
    data = make_image_bytes(10_001, 600, mode="L", color=255)

    assert _error_code(data) is ErrorCode.IMAGE_DIMENSIONS_OUT_OF_RANGE


def test_rejects_giant_declared_dimensions_without_decoding_them() -> None:
    # 30 000 × 30 000 px: Pillow la detiene como «bomba de descompresión».
    data = make_png_header_only(30_000, 30_000)

    assert _error_code(data) is ErrorCode.IMAGE_DIMENSIONS_OUT_OF_RANGE


def test_rejects_files_over_10_mb() -> None:
    data = b"\xff\xd8\xff" + bytes(MAX_IMAGE_BYTES)

    assert _error_code(data) is ErrorCode.IMAGE_TOO_LARGE


def test_rejects_other_image_formats_by_content() -> None:
    gif = io.BytesIO()
    Image.new("RGB", (800, 800), "white").save(gif, format="GIF")

    assert _error_code(gif.getvalue()) is ErrorCode.UNSUPPORTED_IMAGE_TYPE


def test_rejects_non_image_content_even_if_it_was_named_jpg() -> None:
    # La API no mira nombres ni extensiones: decide por el contenido.
    assert _error_code(b"esto es texto, no una imagen") is ErrorCode.UNSUPPORTED_IMAGE_TYPE


def test_rejects_a_damaged_png() -> None:
    data = b"\x89PNG\r\n\x1a\n" + b"basura" * 20

    assert _error_code(data) is ErrorCode.IMAGE_UNREADABLE


def test_rejects_an_empty_body() -> None:
    assert _error_code(b"") is ErrorCode.IMAGE_UNREADABLE
