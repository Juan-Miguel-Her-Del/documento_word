"""Pruebas de la exportación a PDF (tarea T049).

Historia 3, escenario 2: PDF real, texto completo sin truncar, con el mismo orden,
caracteres y párrafos; SC-001 y SC-002. El texto se lee de vuelta con pypdf.
"""

from __future__ import annotations

import io

from pypdf import PdfReader

from tests.conftest import FakeOcrProvider, make_client

URL = "/api/v1/exports"


def _export_pdf(text: str):
    return make_client(FakeOcrProvider()).post(URL, json={"text": text, "format": "pdf"})


def _reader(content: bytes) -> PdfReader:
    return PdfReader(io.BytesIO(content))


def _words(content: bytes) -> list[str]:
    """Palabras del PDF en orden (los cortes de línea del ajuste no cuentan)."""
    pages = _reader(content).pages
    return " ".join(page.extract_text() for page in pages).split()


def test_pdf_is_real_and_keeps_spanish_characters() -> None:
    text = (
        "Título del documento\n"
        "\n"
        "Acentos: áéíóú ÁÉÍÓÚ ñ Ñ ü\n"
        "¿Pregunta? ¡Exclamación! «comillas» “tipográficas” — raya"
    )

    response = _export_pdf(text)

    assert response.status_code == 200
    assert response.headers["content-type"] == "application/pdf"
    assert response.content.startswith(b"%PDF-")  # un .pdf real (SC-001)
    assert _words(response.content) == text.split()


def test_long_text_continues_on_new_pages_without_truncation() -> None:
    lines = [f"Renglón {number}: apuntes de la clase de hoy" for number in range(200)]
    text = "\n".join(lines)

    response = _export_pdf(text)

    assert len(_reader(response.content).pages) > 1
    assert _words(response.content) == text.split()


def test_long_lines_are_wrapped_without_losing_words() -> None:
    text = " ".join(f"palabra{number}" for number in range(300))

    assert _words(_export_pdf(text).content) == text.split()


def test_tabs_are_drawn_as_spaces() -> None:
    assert _words(_export_pdf("columna1\tcolumna2").content) == ["columna1", "columna2"]


def test_characters_without_glyph_are_rejected_and_listed() -> None:
    # La fuente no tiene ideogramas chinos: se avisa en lugar de dibujar cuadros vacíos.
    response = _export_pdf("Hola 漢")

    assert response.status_code == 400
    error = response.json()["error"]
    assert error["code"] == "UNSUPPORTED_CHARACTERS"
    assert "U+6F22" in error["message"]
    assert "PDF" in error["message"]
