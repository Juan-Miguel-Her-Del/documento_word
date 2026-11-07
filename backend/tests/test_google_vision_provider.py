"""Pruebas del adaptador de Google Cloud Vision con un transporte simulado (tarea T019).

No se sale a internet: httpx.MockTransport responde como lo haría Google. Se comprueba la
forma de la solicitud (research.md, R1) y la distinción de fallos (constitución §5).
"""

from __future__ import annotations

import asyncio
import base64
import json
from collections.abc import Awaitable, Callable

import httpx
import pytest

from app.services.ocr import (
    GoogleVisionOcrProvider,
    OcrInvalidResponseError,
    OcrProviderError,
    OcrTimeoutError,
)
from app.services.ocr.google_vision import ENDPOINT

Handler = Callable[[httpx.Request], httpx.Response | Awaitable[httpx.Response]]


def _provider(handler: Handler, timeout: float = 5.0) -> GoogleVisionOcrProvider:
    return GoogleVisionOcrProvider(
        api_key="clave-de-prueba",
        language_hints=("es", "en"),
        timeout_seconds=timeout,
        transport=httpx.MockTransport(handler),
    )


def _recognize(handler: Handler, timeout: float = 5.0) -> str:
    return asyncio.run(_provider(handler, timeout).recognize(b"bytes-jpeg")).text


def _reply(body: object, status: int = 200) -> Handler:
    return lambda request: httpx.Response(status, json=body)


def test_request_uses_document_text_detection_hints_and_header_key() -> None:
    captured: list[httpx.Request] = []

    def handler(request: httpx.Request) -> httpx.Response:
        captured.append(request)
        return httpx.Response(200, json={"responses": [{"fullTextAnnotation": {"text": "Hola"}}]})

    assert _recognize(handler) == "Hola"

    request = captured[0]
    assert str(request.url) == ENDPOINT  # la clave NO va en la URL
    assert request.headers["x-goog-api-key"] == "clave-de-prueba"
    sent = json.loads(request.content)["requests"][0]
    assert sent["features"] == [{"type": "DOCUMENT_TEXT_DETECTION"}]
    assert sent["imageContext"]["languageHints"] == ["es", "en"]
    assert base64.b64decode(sent["image"]["content"]) == b"bytes-jpeg"


def test_text_is_returned_exactly_as_received() -> None:
    # Fidelidad (constitución §3): ni se corrige ni se recorta.
    original = "  Apuntes de clase  \nTema 1: ecuaciónes\n"
    body = {"responses": [{"fullTextAnnotation": {"text": original}}]}

    assert _recognize(_reply(body)) == original


def test_missing_annotation_means_no_text() -> None:
    assert _recognize(_reply({"responses": [{}]})) == ""


def _annotation_with_words(text: str, words: list[tuple[str, object]]) -> dict:
    """Respuesta de Vision con una página, un bloque y un párrafo (spec 003, R1)."""
    return {
        "responses": [
            {
                "fullTextAnnotation": {
                    "text": text,
                    "pages": [
                        {
                            "blocks": [
                                {
                                    "paragraphs": [
                                        {
                                            "words": [
                                                {
                                                    "confidence": confidence,
                                                    "symbols": [{"text": ch} for ch in word],
                                                }
                                                for word, confidence in words
                                            ]
                                        }
                                    ]
                                }
                            ]
                        }
                    ],
                }
            }
        ]
    }


def _recognize_result(body: object):
    return asyncio.run(_provider(_reply(body)).recognize(b"bytes-jpeg"))


def test_word_confidence_becomes_uncertain_spans() -> None:
    # [EX-H1-E1] La seguridad de cada palabra llega en pages/blocks/paragraphs/words.
    body = _annotation_with_words(
        "Tema 1: la célula\n",
        [("Tema", 0.98), ("1", 0.95), (":", 0.2), ("la", 0.9), ("célula", 0.41)],
    )

    result = _recognize_result(body)

    assert result.text == "Tema 1: la célula\n"  # el texto no cambia (fidelidad)
    assert [result.text[s.start : s.end] for s in result.uncertain_spans] == ["célula"]


def test_without_pages_the_text_has_no_marks() -> None:
    # [EX-H1-E8] Si Vision no informa la seguridad, el texto se devuelve igual.
    result = _recognize_result({"responses": [{"fullTextAnnotation": {"text": "Hola"}}]})

    assert result.text == "Hola"
    assert result.uncertain_spans == ()


@pytest.mark.parametrize("confidence", ["0.3", None, True, 1.5, -0.1])
def test_malformed_confidence_drops_the_marks_but_keeps_the_text(confidence: object) -> None:
    result = _recognize_result(_annotation_with_words("Hola", [("Hola", confidence)]))

    assert result.text == "Hola"
    assert result.uncertain_spans == ()


def test_image_level_error_is_a_provider_error() -> None:
    body = {"responses": [{"error": {"code": 3, "message": "Bad image data."}}]}

    with pytest.raises(OcrProviderError):
        _recognize(_reply(body))


def test_http_error_is_a_provider_error() -> None:
    with pytest.raises(OcrProviderError):
        _recognize(_reply({"error": {"code": 403}}, status=403))


def test_non_json_answer_is_an_invalid_response() -> None:
    with pytest.raises(OcrInvalidResponseError):
        _recognize(lambda request: httpx.Response(200, content=b"<html>error</html>"))


@pytest.mark.parametrize(
    "body",
    [
        {"otra": "cosa"},
        {"responses": []},
        {"responses": [{"fullTextAnnotation": {"text": 5}}]},
    ],
)
def test_unexpected_shapes_are_invalid_responses(body: object) -> None:
    with pytest.raises(OcrInvalidResponseError):
        _recognize(_reply(body))


def test_network_timeout_is_reported_as_timeout() -> None:
    def handler(request: httpx.Request) -> httpx.Response:
        raise httpx.ReadTimeout("sin respuesta", request=request)

    with pytest.raises(OcrTimeoutError):
        _recognize(handler)


def test_total_time_limit_is_enforced() -> None:
    async def slow_handler(request: httpx.Request) -> httpx.Response:
        await asyncio.sleep(1)
        return httpx.Response(200, json={"responses": [{}]})

    with pytest.raises(OcrTimeoutError):
        _recognize(slow_handler, timeout=0.05)


def test_connection_failure_is_a_provider_error() -> None:
    def handler(request: httpx.Request) -> httpx.Response:
        raise httpx.ConnectError("sin red", request=request)

    with pytest.raises(OcrProviderError):
        _recognize(handler)


def test_repr_hides_the_api_key() -> None:
    assert "clave-de-prueba" not in repr(_provider(_reply({})))
