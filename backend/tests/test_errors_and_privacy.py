"""Pruebas del formato de errores y de la privacidad de los registros (tarea T011).

Constitución §5: errores con código estable, mensaje comprensible y request_id, sin
trazas ni detalles internos. Constitución §3 y SC-005: los registros no contienen
imágenes, transcripciones ni credenciales.
"""

from __future__ import annotations

import logging

import httpx
import pytest

from app.services.ocr import GoogleVisionOcrProvider
from tests.conftest import FakeOcrProvider, make_client, make_image_bytes

IMAGE_HEADERS = {"Content-Type": "image/png"}


def _all_log_text(caplog: pytest.LogCaptureFixture) -> str:
    return "\n".join(record.getMessage() for record in caplog.records)


def test_unknown_route_returns_structured_404() -> None:
    response = make_client(FakeOcrProvider()).get("/api/v1/no-existe")

    assert response.status_code == 404
    error = response.json()["error"]
    assert error["code"] == "NOT_FOUND"
    assert error["request_id"] == response.headers["X-Request-ID"]


def test_wrong_method_returns_structured_405() -> None:
    response = make_client(FakeOcrProvider()).get("/api/v1/exports")

    assert response.status_code == 405
    assert response.json()["error"]["code"] == "METHOD_NOT_ALLOWED"


def test_unexpected_error_returns_generic_500_and_logs_no_details(
    caplog: pytest.LogCaptureFixture,
) -> None:
    caplog.set_level(logging.INFO, logger="handtext")
    secret = "TEXTO-CONFIDENCIAL-123"
    client = make_client(FakeOcrProvider(error=RuntimeError(secret)))

    response = client.post(
        "/api/v1/recognitions", content=make_image_bytes(800, 800), headers=IMAGE_HEADERS
    )

    assert response.status_code == 500
    assert response.json()["error"]["code"] == "INTERNAL_ERROR"
    assert secret not in response.text
    logs = _all_log_text(caplog)
    assert secret not in logs
    # El registro permite localizar la falla: tipo, archivo:línea y request_id.
    assert "unexpected_error type=RuntimeError" in logs
    assert response.headers["X-Request-ID"] in logs


def test_logs_never_contain_document_text(caplog: pytest.LogCaptureFixture) -> None:
    """SC-005: ni el texto reconocido ni el exportado aparecen en los registros."""
    caplog.set_level(logging.INFO, logger="handtext")
    secret = "Mi diario secreto 4567"
    client = make_client(FakeOcrProvider(text=secret))

    recognition = client.post(
        "/api/v1/recognitions", content=make_image_bytes(800, 800), headers=IMAGE_HEADERS
    )
    word = client.post("/api/v1/exports", json={"text": secret, "format": "docx"})
    pdf = client.post("/api/v1/exports", json={"text": secret, "format": "pdf"})

    assert (recognition.status_code, word.status_code, pdf.status_code) == (200, 200, 200)
    assert caplog.records, "se esperaban registros de las solicitudes"
    assert secret not in _all_log_text(caplog)


def test_api_key_never_appears_in_logs_or_responses(caplog: pytest.LogCaptureFixture) -> None:
    """SC-005: la clave del proveedor no se filtra aunque el proveedor la repita."""
    caplog.set_level(logging.INFO, logger="handtext")
    key = "CLAVE-DE-PRUEBA-NO-REAL"

    def google_rejects_key(request: httpx.Request) -> httpx.Response:
        return httpx.Response(403, json={"error": {"message": f"API key not valid: {key}"}})

    provider = GoogleVisionOcrProvider(
        api_key=key,
        language_hints=("es", "en"),
        timeout_seconds=5,
        transport=httpx.MockTransport(google_rejects_key),
    )
    response = make_client(provider).post(
        "/api/v1/recognitions", content=make_image_bytes(800, 800), headers=IMAGE_HEADERS
    )

    assert response.status_code == 502
    assert response.json()["error"]["code"] == "OCR_PROVIDER_ERROR"
    assert key not in response.text
    assert key not in _all_log_text(caplog)
    assert key not in repr(provider)


def test_schema_error_does_not_echo_the_submitted_text() -> None:
    secret = "Texto privado del usuario"
    response = make_client(FakeOcrProvider()).post(
        "/api/v1/exports", json={"text": secret, "format": "txt"}
    )

    assert response.status_code == 422
    assert response.json()["error"]["code"] == "VALIDATION_ERROR"
    assert secret not in response.text
