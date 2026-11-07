"""Pruebas de la exportación a Word y de las reglas comunes del texto (tarea T021).

Historia 1, escenarios 9 y 10; SC-001, SC-002 y SC-007; spec, módulo 4.
"""

from __future__ import annotations

import io

import pytest
from docx import Document

from app.config import MAX_EXPORT_BODY_BYTES, MAX_EXPORT_TEXT_CHARS
from app.services.documents.export_service import DOCX_MEDIA_TYPE
from tests.conftest import FakeOcrProvider, make_client

URL = "/api/v1/exports"


def _export(text: str, export_format: str = "docx"):
    return make_client(FakeOcrProvider()).post(URL, json={"text": text, "format": export_format})


def _paragraphs(content: bytes) -> list[str]:
    return [paragraph.text for paragraph in Document(io.BytesIO(content)).paragraphs]


def test_docx_contains_exactly_the_edited_text() -> None:
    text = (
        "Título corregido por el usuario\n"
        "\n"
        "Acentos y signos: áéíóú ÁÉÍÓÚ ñ Ñ ü ¿Qué tal? ¡Bien!\n"
        "Segundo párrafo\tcon tabulación"
    )

    response = _export(text)

    assert response.status_code == 200
    assert response.headers["content-type"] == DOCX_MEDIA_TYPE
    assert response.content.startswith(b"PK")  # un .docx real es un ZIP (SC-001)
    assert _paragraphs(response.content) == text.split("\n")  # SC-002


def test_windows_line_breaks_become_paragraphs() -> None:
    assert _paragraphs(_export("uno\r\ndos\rtres").content) == ["uno", "dos", "tres"]


def test_long_text_is_not_truncated() -> None:
    lines = [f"Línea {number} de los apuntes" for number in range(3000)]

    assert _paragraphs(_export("\n".join(lines)).content) == lines


def test_metadata_is_neutral() -> None:
    properties = Document(io.BytesIO(_export("Hola").content)).core_properties

    assert properties.author == "HandText AI"
    assert properties.comments == ""


def test_emoji_is_allowed_in_word() -> None:
    assert _paragraphs(_export("Listo ✅ 😀").content) == ["Listo ✅ 😀"]


@pytest.mark.parametrize("export_format", ["docx", "pdf"])
@pytest.mark.parametrize("blank_text", ["", "   ", "\n\t \n"])
def test_blank_text_is_rejected(export_format: str, blank_text: str) -> None:
    # Historia 1, escenario 10; SC-007.
    response = _export(blank_text, export_format)

    assert response.status_code == 400
    assert response.json()["error"]["code"] == "EMPTY_TEXT"


def test_control_characters_are_rejected_and_listed() -> None:
    response = _export("Hola\x07mundo")

    assert response.status_code == 400
    error = response.json()["error"]
    assert error["code"] == "UNSUPPORTED_CHARACTERS"
    assert "U+0007" in error["message"]


def test_text_over_the_limit_returns_413() -> None:
    response = _export("a" * (MAX_EXPORT_TEXT_CHARS + 1))

    assert response.status_code == 413
    assert response.json()["error"]["code"] == "TEXT_TOO_LARGE"


def test_body_over_3_mb_returns_413() -> None:
    response = make_client(FakeOcrProvider()).post(
        URL,
        content=b"x" * (MAX_EXPORT_BODY_BYTES + 1),
        headers={"Content-Type": "application/json"},
    )

    assert response.status_code == 413


@pytest.mark.parametrize(
    "body",
    [
        b'{"text": "hola", "format": "txt"}',
        b'{"text": "hola", "format": "docx", "extra": 1}',
        b'{"format": "docx"}',
        b"{no es json",
    ],
)
def test_malformed_requests_return_422(body: bytes) -> None:
    response = make_client(FakeOcrProvider()).post(
        URL, content=body, headers={"Content-Type": "application/json"}
    )

    assert response.status_code == 422
    assert response.json()["error"]["code"] == "VALIDATION_ERROR"


def test_download_headers() -> None:
    response = _export("Hola")

    assert response.headers["content-disposition"] == 'attachment; filename="handtext.docx"'
    assert response.headers["cache-control"] == "no-store"
