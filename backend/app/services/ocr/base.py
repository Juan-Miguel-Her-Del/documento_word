"""Contrato del proveedor de OCR (tarea T029; constitución §2, adaptador del backend).

Las rutas solo conocen este contrato. Así el proveedor (hoy Google Cloud Vision) queda
encapsulado: cambiarlo no exige tocar las rutas, y las pruebas pueden usar un proveedor
falso sin salir a internet.

Los tres errores permiten distinguir cada fallo de un reconocimiento sin texto
(constitución §5, OCR e integraciones):
- OcrTimeoutError: el proveedor no respondió a tiempo → 504.
- OcrProviderError: el proveedor rechazó la solicitud o falló la conexión → 502.
- OcrInvalidResponseError: la respuesta no tiene la forma esperada → 502.
"""

from __future__ import annotations

from dataclasses import dataclass
from typing import Protocol


@dataclass(frozen=True)
class UncertainSpan:
    """Posición de una palabra dudosa dentro del texto (spec 003, módulo 1).

    Cuenta puntos de código Unicode: `text[start:end]` es la palabra (research.md de
    003, R2).
    """

    start: int
    end: int


@dataclass(frozen=True)
class OcrResult:
    """Texto reconocido, tal como lo entregó el proveedor (cadena vacía si no hubo texto).

    `uncertain_spans` son las palabras leídas con poca seguridad, ordenadas y sin
    superponerse. Son solo una ayuda: nunca cambian el texto (spec 003).
    """

    text: str
    uncertain_spans: tuple[UncertainSpan, ...] = ()


class OcrError(Exception):
    """Base de los errores del proveedor de OCR."""


class OcrTimeoutError(OcrError):
    """El proveedor no respondió dentro del tiempo máximo."""


class OcrProviderError(OcrError):
    """El proveedor devolvió un error o no se pudo conectar con él."""


class OcrInvalidResponseError(OcrError):
    """La respuesta del proveedor no tiene el formato esperado."""


class OcrProvider(Protocol):
    """Lo que debe saber hacer cualquier proveedor de OCR."""

    async def recognize(self, image_jpeg: bytes) -> OcrResult:
        """Reconoce el texto de una imagen JPEG ya preparada."""
        ...
