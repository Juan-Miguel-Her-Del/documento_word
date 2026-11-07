"""Pruebas de POST /api/v1/recognitions (tarea T020).

Historia 1, escenarios 1 y 6 a 8; spec, módulos 1, 2 y 5; contracts/api.md.
"""

from __future__ import annotations

import pytest

from app.config import MAX_IMAGE_BYTES
from app.services.ocr import OcrInvalidResponseError, OcrProviderError, OcrTimeoutError
from app.services.ocr.base import UncertainSpan
from tests.conftest import FakeOcrProvider, make_client, make_image_bytes, make_noisy_jpeg

URL = "/api/v1/recognitions"


def _post(provider: FakeOcrProvider | None, data: bytes, content_type: str = "image/png"):
    return make_client(provider).post(URL, content=data, headers={"Content-Type": content_type})


def _error_code(response) -> str:
    return response.json()["error"]["code"]


def test_text_found_returns_the_text_and_request_id() -> None:
    provider = FakeOcrProvider(text="Apuntes de clase\nTema 1")

    response = _post(provider, make_image_bytes(800, 600))

    assert response.status_code == 200
    body = response.json()
    assert body["status"] == "text_found"
    assert body["text"] == "Apuntes de clase\nTema 1"
    assert body["request_id"] == response.headers["X-Request-ID"]


def test_uncertain_words_are_returned_with_their_positions() -> None:
    # Spec 003, [EX-H1-E1]; contracts/recognition-api.md de 003.
    provider = FakeOcrProvider(text="Tema 1: la célula", uncertain=(UncertainSpan(11, 17),))

    body = _post(provider, make_image_bytes(800, 600)).json()

    assert body["uncertain_words"] == [{"start": 11, "end": 17}]
    assert body["text"][11:17] == "célula"


def test_without_uncertain_words_the_list_is_empty() -> None:
    body = _post(FakeOcrProvider(text="Hola"), make_image_bytes(800, 600)).json()

    assert body["uncertain_words"] == []


def test_provider_receives_a_prepared_jpeg_copy() -> None:
    provider = FakeOcrProvider(text="Hola")

    _post(provider, make_image_bytes(800, 600, "PNG"))

    assert provider.received[0].startswith(b"\xff\xd8\xff")  # JPEG preparado


@pytest.mark.parametrize("provider_text", ["", "   \n\t  "])
def test_no_text_is_a_result_not_an_error(provider_text: str) -> None:
    # Historia 1, escenario 7: no se presenta un documento vacío como éxito.
    response = _post(FakeOcrProvider(text=provider_text), make_image_bytes(800, 600))

    assert response.status_code == 200
    assert response.json()["status"] == "no_text"
    assert response.json()["text"] == ""
    assert response.json()["uncertain_words"] == []


def test_missing_provider_key_returns_503() -> None:
    response = _post(None, make_image_bytes(800, 600))

    assert response.status_code == 503
    assert _error_code(response) == "OCR_NOT_CONFIGURED"


def test_invalid_image_is_reported_even_without_provider_key() -> None:
    # El usuario siempre sabe si el problema es su imagen, esté o no configurado el OCR.
    response = _post(None, make_image_bytes(500, 500))

    assert response.status_code == 400
    assert _error_code(response) == "IMAGE_DIMENSIONS_OUT_OF_RANGE"


def test_image_over_10_mb_returns_413_and_is_not_sent() -> None:
    provider = FakeOcrProvider(text="no debería llegar")

    response = _post(provider, b"\xff\xd8\xff" + bytes(MAX_IMAGE_BYTES), "image/jpeg")

    assert response.status_code == 413
    assert _error_code(response) == "IMAGE_TOO_LARGE"
    assert provider.received == []


def test_non_image_content_returns_415_and_is_not_sent() -> None:
    provider = FakeOcrProvider(text="no debería llegar")

    response = _post(provider, b"%PDF-1.7 documento", "image/jpeg")

    assert response.status_code == 415
    assert _error_code(response) == "UNSUPPORTED_IMAGE_TYPE"
    assert provider.received == []


def test_truncated_image_returns_400_unreadable() -> None:
    complete = make_noisy_jpeg()

    response = _post(FakeOcrProvider(text="x"), complete[: len(complete) // 2], "image/jpeg")

    assert response.status_code == 400
    assert _error_code(response) == "IMAGE_UNREADABLE"


def test_too_small_image_returns_400_dimensions() -> None:
    response = _post(FakeOcrProvider(text="x"), make_image_bytes(500, 500))

    assert response.status_code == 400
    assert _error_code(response) == "IMAGE_DIMENSIONS_OUT_OF_RANGE"


@pytest.mark.parametrize(
    ("error", "status", "code"),
    [
        (OcrTimeoutError(), 504, "OCR_TIMEOUT"),
        (OcrProviderError(), 502, "OCR_PROVIDER_ERROR"),
        (OcrInvalidResponseError(), 502, "OCR_INVALID_RESPONSE"),
    ],
)
def test_provider_failures_are_distinguished(error: Exception, status: int, code: str) -> None:
    # Historia 1, escenario 8: cada fallo se distingue de «no se encontró texto».
    response = _post(FakeOcrProvider(error=error), make_image_bytes(800, 600))

    assert response.status_code == status
    assert _error_code(response) == code


def test_error_messages_have_no_internal_details() -> None:
    responses = [
        _post(None, make_image_bytes(800, 600)),
        _post(FakeOcrProvider(), b"no es imagen"),
        _post(FakeOcrProvider(error=OcrProviderError()), make_image_bytes(800, 600)),
    ]
    for response in responses:
        message = response.json()["error"]["message"]
        assert message
        for forbidden in ("Traceback", ".py", "Exception", "\\", "http"):
            assert forbidden not in message
