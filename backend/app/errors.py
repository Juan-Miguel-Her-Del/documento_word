"""Catálogo de errores de la API (tarea T006; constitución §5, Backend).

Toda respuesta de error tiene la misma forma, documentada en contracts/api.md:

    {"error": {"code": "IMAGE_TOO_LARGE", "message": "...", "request_id": "..."}}

- code: identificador estable; la app decide qué mostrar según este valor.
- message: texto en español, sin rutas, trazas, consultas ni credenciales.
- request_id: identificador de la solicitud para localizarla en los registros.

Los servicios lanzan AppError con un código del catálogo y no conocen HTTP. Este módulo
traduce cada código a su estado HTTP; así las rutas, la validación y los servicios quedan
separados (constitución §4).
"""

from __future__ import annotations

import logging
import traceback
from enum import StrEnum
from pathlib import Path

from fastapi import FastAPI, Request
from fastapi.responses import JSONResponse
from starlette.exceptions import HTTPException as StarletteHTTPException

from app.persistence.user_store import StoreUnavailableError

logger = logging.getLogger("handtext")


class ErrorCode(StrEnum):
    """Códigos estables que la API puede devolver."""

    VALIDATION_ERROR = "VALIDATION_ERROR"
    IMAGE_TOO_LARGE = "IMAGE_TOO_LARGE"
    UNSUPPORTED_IMAGE_TYPE = "UNSUPPORTED_IMAGE_TYPE"
    IMAGE_UNREADABLE = "IMAGE_UNREADABLE"
    IMAGE_DIMENSIONS_OUT_OF_RANGE = "IMAGE_DIMENSIONS_OUT_OF_RANGE"
    OCR_NOT_CONFIGURED = "OCR_NOT_CONFIGURED"
    OCR_TIMEOUT = "OCR_TIMEOUT"
    OCR_PROVIDER_ERROR = "OCR_PROVIDER_ERROR"
    OCR_INVALID_RESPONSE = "OCR_INVALID_RESPONSE"
    EMPTY_TEXT = "EMPTY_TEXT"
    TEXT_TOO_LARGE = "TEXT_TOO_LARGE"
    UNSUPPORTED_CHARACTERS = "UNSUPPORTED_CHARACTERS"
    NOT_FOUND = "NOT_FOUND"
    METHOD_NOT_ALLOWED = "METHOD_NOT_ALLOWED"
    INTERNAL_ERROR = "INTERNAL_ERROR"
    # Cuentas de usuario (spec 002; contracts/auth-api.md).
    REQUEST_TOO_LARGE = "REQUEST_TOO_LARGE"
    UNAUTHENTICATED = "UNAUTHENTICATED"
    INVALID_CREDENTIALS = "INVALID_CREDENTIALS"
    TOO_MANY_ATTEMPTS = "TOO_MANY_ATTEMPTS"
    EMAIL_ALREADY_REGISTERED = "EMAIL_ALREADY_REGISTERED"
    INVALID_EMAIL = "INVALID_EMAIL"
    INVALID_DISPLAY_NAME = "INVALID_DISPLAY_NAME"
    WEAK_PASSWORD = "WEAK_PASSWORD"
    DATA_POLICY_NOT_ACCEPTED = "DATA_POLICY_NOT_ACCEPTED"
    ACCOUNTS_UNAVAILABLE = "ACCOUNTS_UNAVAILABLE"


# Código -> (estado HTTP, mensaje público en español). Los estados siguen la constitución
# §5: 400 solicitud mal formada, 401 autenticación ausente o inválida, 409 conflicto,
# 413 carga excesiva, 415 tipo no admitido, 422 esquema, 5xx fallos internos o de
# dependencias. 429 (demasiados intentos) es el estándar HTTP para el bloqueo de ingreso.
_CATALOG: dict[ErrorCode, tuple[int, str]] = {
    ErrorCode.VALIDATION_ERROR: (422, "La solicitud no tiene el formato esperado."),
    ErrorCode.IMAGE_TOO_LARGE: (413, "La imagen supera el tamaño máximo permitido de 10 MB."),
    ErrorCode.UNSUPPORTED_IMAGE_TYPE: (415, "El archivo no es una imagen JPEG o PNG."),
    ErrorCode.IMAGE_UNREADABLE: (
        400,
        "No se pudo abrir la imagen. Puede estar dañada o incompleta.",
    ),
    ErrorCode.IMAGE_DIMENSIONS_OUT_OF_RANGE: (
        400,
        "La imagen debe medir entre 600 y 10 000 píxeles por lado.",
    ),
    ErrorCode.OCR_NOT_CONFIGURED: (
        503,
        "El servicio de reconocimiento no está disponible en este momento.",
    ),
    ErrorCode.OCR_TIMEOUT: (504, "El servicio de reconocimiento tardó demasiado en responder."),
    ErrorCode.OCR_PROVIDER_ERROR: (
        502,
        "El servicio de reconocimiento no pudo procesar la imagen.",
    ),
    ErrorCode.OCR_INVALID_RESPONSE: (
        502,
        "El servicio de reconocimiento devolvió una respuesta no válida.",
    ),
    ErrorCode.EMPTY_TEXT: (
        400,
        "No se puede exportar un texto vacío o compuesto solo por espacios.",
    ),
    ErrorCode.TEXT_TOO_LARGE: (413, "El texto supera el tamaño máximo que se puede exportar."),
    ErrorCode.UNSUPPORTED_CHARACTERS: (
        400,
        "El texto contiene caracteres que no se pueden incluir en el archivo.",
    ),
    ErrorCode.NOT_FOUND: (404, "El recurso solicitado no existe."),
    ErrorCode.METHOD_NOT_ALLOWED: (405, "Método no permitido para este recurso."),
    ErrorCode.INTERNAL_ERROR: (500, "Ocurrió un error interno. Intente de nuevo más tarde."),
    ErrorCode.REQUEST_TOO_LARGE: (413, "La solicitud es demasiado grande."),
    ErrorCode.UNAUTHENTICATED: (401, "Su sesión no es válida o venció. Inicie sesión de nuevo."),
    # [CU-H1-E7] [SC-203] Un solo mensaje: no revela si el correo existe.
    ErrorCode.INVALID_CREDENTIALS: (401, "Correo o contraseña incorrectos."),
    ErrorCode.TOO_MANY_ATTEMPTS: (
        429,
        "Demasiados intentos fallidos. Intente de nuevo en 15 minutos.",
    ),
    ErrorCode.EMAIL_ALREADY_REGISTERED: (409, "Ya existe una cuenta con ese correo."),
    ErrorCode.INVALID_EMAIL: (400, "El correo electrónico no es válido."),
    ErrorCode.INVALID_DISPLAY_NAME: (400, "El nombre debe tener entre 1 y 60 caracteres."),
    ErrorCode.WEAK_PASSWORD: (400, "La contraseña debe tener entre 8 y 128 caracteres."),
    ErrorCode.DATA_POLICY_NOT_ACCEPTED: (
        400,
        "Debe autorizar el tratamiento de sus datos para crear la cuenta.",
    ),
    ErrorCode.ACCOUNTS_UNAVAILABLE: (
        503,
        "El servicio de cuentas no está disponible en este momento.",
    ),
}


class AppError(Exception):
    """Error esperado del dominio, con un código del catálogo.

    `message` permite dar un detalle más preciso (por ejemplo, qué caracteres no se
    pueden exportar). Si no se indica, se usa el mensaje del catálogo.
    """

    def __init__(self, code: ErrorCode, message: str | None = None) -> None:
        self.code = code
        self.status_code, default_message = _CATALOG[code]
        self.message = message or default_message
        super().__init__(code.value)


def request_id_of(request: Request) -> str:
    """Devuelve el request_id que el middleware de main.py guardó en la solicitud."""
    return getattr(request.state, "request_id", "desconocido")


def error_response(error: AppError, request_id: str) -> JSONResponse:
    """Construye la respuesta JSON común a todos los errores."""
    # El estándar HTTP pide indicar en los 401 cómo autenticarse: con un token Bearer.
    headers = {"WWW-Authenticate": "Bearer"} if error.status_code == 401 else None
    return JSONResponse(
        status_code=error.status_code,
        content={
            "error": {
                "code": error.code.value,
                "message": error.message,
                "request_id": request_id,
            }
        },
        headers=headers,
    )


def log_unexpected_error(exc: BaseException, request_id: str) -> None:
    """Registra un error inesperado sin su mensaje ni sus valores.

    Solo se guarda el tipo de excepción y el archivo:línea donde ocurrió. Así se puede
    localizar la falla sin escribir en los registros contenido del documento
    (constitución §5: diagnósticos sin el contenido del documento).
    """
    frames = traceback.extract_tb(exc.__traceback__)
    where = f"{Path(frames[-1].filename).name}:{frames[-1].lineno}" if frames else "desconocido"
    logger.error(
        "unexpected_error type=%s where=%s request_id=%s",
        type(exc).__name__,
        where,
        request_id,
    )


def install_error_handlers(app: FastAPI) -> None:
    """Registra en la app los manejadores que convierten excepciones en JSON."""

    @app.exception_handler(AppError)
    async def handle_app_error(request: Request, exc: AppError) -> JSONResponse:
        # Errores esperados (imagen inválida, texto vacío, fallos del OCR, etc.).
        return error_response(exc, request_id_of(request))

    @app.exception_handler(StoreUnavailableError)
    async def handle_store_unavailable(
        request: Request, exc: StoreUnavailableError
    ) -> JSONResponse:
        # La base de datos no responde: 503 sin detalles técnicos (constitución §5).
        logger.error("accounts_store_unavailable request_id=%s", request_id_of(request))
        return error_response(AppError(ErrorCode.ACCOUNTS_UNAVAILABLE), request_id_of(request))

    @app.exception_handler(StarletteHTTPException)
    async def handle_http_error(request: Request, exc: StarletteHTTPException) -> JSONResponse:
        # Rutas inexistentes (404) o métodos no permitidos (405), con el mismo formato.
        if exc.status_code == 404:
            error = AppError(ErrorCode.NOT_FOUND)
        elif exc.status_code == 405:
            error = AppError(ErrorCode.METHOD_NOT_ALLOWED)
        else:
            error = AppError(ErrorCode.INTERNAL_ERROR)
        return error_response(error, request_id_of(request))
