"""Pruebas de la copia preparada para el OCR (tarea T018).

Constitución §3, Conservación del original: se trabaja sobre una copia (Historia 1,
escenario 14; SC-006). Research R3: orientación aplicada, sin metadatos, ≤ 3 000 px.
"""

from __future__ import annotations

import hashlib
import io

import pytest
from PIL import Image

from app.errors import AppError, ErrorCode
from app.services.image_preparation import prepare_for_ocr
from tests.conftest import make_image_bytes, make_noisy_jpeg

ORIENTATION_TAG = 0x0112
MAKE_TAG = 0x010F


def _open(data: bytes) -> Image.Image:
    return Image.open(io.BytesIO(data))


def test_original_bytes_are_never_modified() -> None:
    original = make_image_bytes(1200, 900, "JPEG")
    fingerprint = hashlib.sha256(original).hexdigest()

    prepare_for_ocr(original)

    assert hashlib.sha256(original).hexdigest() == fingerprint


def test_large_image_becomes_a_jpeg_of_at_most_3000_px() -> None:
    prepared = _open(prepare_for_ocr(make_image_bytes(4000, 3000, "PNG")))

    assert prepared.format == "JPEG"
    assert prepared.size == (3000, 2250)


def test_small_image_keeps_its_size() -> None:
    assert _open(prepare_for_ocr(make_image_bytes(800, 600, "JPEG"))).size == (800, 600)


def test_exif_orientation_is_applied() -> None:
    exif = Image.Exif()
    exif[ORIENTATION_TAG] = 6  # la cámara indica «girar 90°»

    prepared = _open(prepare_for_ocr(make_image_bytes(1200, 800, "JPEG", exif=exif)))

    assert prepared.size == (800, 1200)


def test_metadata_is_removed_from_the_copy() -> None:
    exif = Image.Exif()
    exif[MAKE_TAG] = "Fabricante del celular"

    prepared = _open(prepare_for_ocr(make_image_bytes(800, 800, "JPEG", exif=exif)))

    assert len(prepared.getexif()) == 0


def test_transparent_areas_become_white() -> None:
    transparent = make_image_bytes(800, 800, "PNG", mode="RGBA", color=(0, 0, 0, 0))

    prepared = _open(prepare_for_ocr(transparent)).convert("RGB")

    assert all(channel > 240 for channel in prepared.getpixel((400, 400)))


def test_a_truncated_file_is_reported_as_unreadable() -> None:
    complete = make_noisy_jpeg()

    with pytest.raises(AppError) as raised:
        prepare_for_ocr(complete[: len(complete) // 2])

    assert raised.value.code is ErrorCode.IMAGE_UNREADABLE
