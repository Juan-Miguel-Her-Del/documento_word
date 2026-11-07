"""Adaptador de Google Cloud Vision (tarea T030; research.md, R1).

Detalles de la integración:
- Función DOCUMENT_TEXT_DETECTION, la que Google indica para escritura a mano.
- Pistas de idioma ["es", "en"] (Clarifications 2026-10-26).
- La clave viaja en la cabecera `x-goog-api-key`, nunca en la URL; así no aparece en
  registros ni en historiales de proxies.
- Tiempo máximo total de 45 s (config.OCR_TIMEOUT_SECONDS).
- Fidelidad (constitución §3): el texto se devuelve tal como llega; no se corrige, no se
  resume y no se traduce.
- Errores: se distingue tiempo agotado, error del proveedor y respuesta inválida, y solo
  se registran códigos numéricos, nunca el contenido.
- Spec 003 (tarea T204): lee la seguridad de cada palabra y marca las dudosas. Si esa
  información falta o tiene otra forma, el texto se devuelve igual y sin marcas
  (research.md de 003, R1).
"""

from __future__ import annotations

import asyncio
import base64
import logging
from collections.abc import Sequence

import httpx

from app.config import UNCERTAIN_WORD_CONFIDENCE
from app.services.ocr.base import (
    OcrInvalidResponseError,
    OcrProviderError,
    OcrResult,
    OcrTimeoutError,
)
from app.services.ocr.uncertain_words import locate_uncertain_words

ENDPOINT = "https://vision.googleapis.com/v1/images:annotate"

logger = logging.getLogger("handtext")


class GoogleVisionOcrProvider:
    """Implementa el contrato OcrProvider llamando a la API REST de Google Cloud Vision."""

    def __init__(
        self,
        api_key: str,
        language_hints: Sequence[str],
        timeout_seconds: float,
        transport: httpx.AsyncBaseTransport | None = None,
    ) -> None:
        self._api_key = api_key
        self._language_hints = list(language_hints)
        self._timeout_seconds = timeout_seconds
        # Solo las pruebas pasan un `transport` simulado; en producción se usa la red.
        self._transport = transport

    def __repr__(self) -> str:
        # Si alguien imprime el objeto, la clave no debe aparecer.
        return "GoogleVisionOcrProvider(api_key=***)"

    async def recognize(self, image_jpeg: bytes) -> OcrResult:
        """Envía la imagen a Vision y devuelve el texto completo reconocido."""
        payload = {
            "requests": [
                {
                    "image": {"content": base64.b64encode(image_jpeg).decode("ascii")},
                    "features": [{"type": "DOCUMENT_TEXT_DETECTION"}],
                    "imageContext": {"languageHints": self._language_hints},
                }
            ]
        }
        headers = {"x-goog-api-key": self._api_key}

        try:
            # asyncio.timeout limita el tiempo TOTAL (conexión + envío + respuesta).
            async with asyncio.timeout(self._timeout_seconds):
                async with httpx.AsyncClient(
                    transport=self._transport, timeout=self._timeout_seconds
                ) as client:
                    response = await client.post(ENDPOINT, json=payload, headers=headers)
        except (TimeoutError, httpx.TimeoutException):
            raise OcrTimeoutError from None
        except httpx.HTTPError:
            raise OcrProviderError from None

        if response.status_code != 200:
            # Solo el código HTTP: el cuerpo podría repetir datos de la solicitud.
            logger.warning("ocr_provider_http_error status=%s", response.status_code)
            raise OcrProviderError
        return _parse_response(response)


def _parse_response(response: httpx.Response) -> OcrResult:
    """Extrae `responses[0].fullTextAnnotation.text` y valida la forma de la respuesta."""
    try:
        body = response.json()
    except ValueError:
        raise OcrInvalidResponseError from None

    responses = body.get("responses") if isinstance(body, dict) else None
    if not isinstance(responses, list) or len(responses) != 1 or not isinstance(responses[0], dict):
        raise OcrInvalidResponseError
    first = responses[0]

    # Vision informa los problemas de cada imagen dentro de la respuesta, con estado 200.
    if "error" in first:
        error = first["error"]
        logger.warning(
            "ocr_provider_image_error code=%s",
            error.get("code") if isinstance(error, dict) else "desconocido",
        )
        raise OcrProviderError

    annotation = first.get("fullTextAnnotation")
    if annotation is None:
        # Vision omite este campo cuando no encuentra texto: es «sin texto», no un error.
        return OcrResult(text="")
    if not isinstance(annotation, dict) or not isinstance(annotation.get("text", ""), str):
        raise OcrInvalidResponseError
    text = annotation.get("text", "")

    # Spec 003: palabras dudosas. Son una ayuda opcional; sin ellas el texto vale igual.
    words = _read_words(annotation)
    if words is None:
        logger.info("ocr_confidence_unavailable")
        return OcrResult(text=text)
    spans = locate_uncertain_words(text, words, UNCERTAIN_WORD_CONFIDENCE)
    return OcrResult(text=text, uncertain_spans=spans)


def _read_words(annotation: dict) -> list[tuple[str, float]] | None:
    """Lee cada palabra (unión de sus símbolos) y su seguridad, en orden de lectura.

    Recorre `pages[].blocks[].paragraphs[].words[]`. Devuelve None si falta la
    estructura o algún dato no tiene la forma esperada (seguridad entre 0 y 1).
    """
    words: list[tuple[str, float]] = []
    try:
        for page in annotation["pages"]:
            for block in page["blocks"]:
                for paragraph in block["paragraphs"]:
                    for word in paragraph["words"]:
                        confidence = word["confidence"]
                        # bool es subclase de int en Python: se descarta a propósito.
                        if isinstance(confidence, bool) or not isinstance(confidence, int | float):
                            return None
                        if not 0 <= confidence <= 1:
                            return None
                        symbols = [symbol["text"] for symbol in word["symbols"]]
                        if not all(isinstance(symbol, str) for symbol in symbols):
                            return None
                        words.append(("".join(symbols), float(confidence)))
    except (KeyError, TypeError):
        return None
    return words
