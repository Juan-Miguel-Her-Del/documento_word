"""Punto de entrada de la API de HandText AI (tarea T007).

Para ejecutarla en desarrollo (desde la carpeta backend):
    uvicorn app.main:app --reload

Qué hace este archivo:
1. Crea la aplicación FastAPI y registra las rutas de cuentas (spec 002), reconocimiento
   y exportación. Abre y cierra el pool de PostgreSQL con la vida de la API.
2. Asigna a cada solicitud un identificador (request_id), lo devuelve en la cabecera
   X-Request-ID y lo usa en los registros (constitución §5, Backend).
3. Convierte cualquier error inesperado en un 500 genérico, sin detalles sensibles.
4. Configura registros con método, ruta, estado y duración; nunca guardan imágenes,
   textos ni la clave del proveedor (constitución §3, Privacidad).
"""

from __future__ import annotations

import logging
import time
import uuid
from collections.abc import AsyncIterator, Awaitable, Callable
from contextlib import asynccontextmanager
from datetime import datetime

from fastapi import FastAPI, Request
from starlette.responses import Response

from app.api import auth, exports, recognitions
from app.config import Settings
from app.errors import (
    AppError,
    ErrorCode,
    error_response,
    install_error_handlers,
    log_unexpected_error,
)
from app.persistence.postgres_store import PostgresUserStore
from app.persistence.user_store import UserStore
from app.services.accounts.account_service import AccountService
from app.services.accounts.passwords import PasswordService
from app.services.ocr import OcrProvider, build_ocr_provider

logger = logging.getLogger("handtext")


@asynccontextmanager
async def _lifespan(app: FastAPI) -> AsyncIterator[None]:
    """Abre el pool de PostgreSQL al iniciar la API y lo cierra al apagarla."""
    store = app.state.user_store
    if isinstance(store, PostgresUserStore):
        store.open()
    try:
        yield
    finally:
        if isinstance(store, PostgresUserStore):
            store.close()


def _configure_logging() -> None:
    """Activa registros de nivel INFO si nadie los configuró antes (por ejemplo, Uvicorn)."""
    if not logging.getLogger().handlers:
        logging.basicConfig(
            level=logging.INFO,
            format="%(asctime)s %(levelname)s %(name)s %(message)s",
        )
    logger.setLevel(logging.INFO)
    # httpx anota cada llamada saliente; solo se dejan sus advertencias.
    logging.getLogger("httpx").setLevel(logging.WARNING)


def create_app(
    settings: Settings | None = None,
    ocr_provider: OcrProvider | None = None,
    user_store: UserStore | None = None,
    password_service: PasswordService | None = None,
    clock: Callable[[], datetime] | None = None,
) -> FastAPI:
    """Crea la aplicación.

    Las pruebas pasan versiones falsas o rápidas de las dependencias: un proveedor de OCR
    falso, un almacén de usuarios en memoria, un cifrado de contraseñas más rápido y un
    reloj que pueden adelantar.
    """
    settings = settings or Settings.from_environment()
    _configure_logging()

    app = FastAPI(
        title="HandText AI API",
        version="0.2.0",
        description="Cuentas de usuario, reconocimiento de documentos manuscritos y "
        "exportación a Word y PDF.",
        lifespan=_lifespan,
    )
    # Proveedor de OCR que usarán las rutas. Es None si falta la clave; en ese caso el
    # reconocimiento responde 503 OCR_NOT_CONFIGURED.
    app.state.ocr_provider = (
        ocr_provider if ocr_provider is not None else build_ocr_provider(settings)
    )
    # Cuentas (spec 002): PostgreSQL si hay HANDTEXT_DATABASE_URL. Si no hay base, las
    # rutas de cuentas y las protegidas responden 503 ACCOUNTS_UNAVAILABLE.
    if user_store is None and settings.database_url is not None:
        user_store = PostgresUserStore.connect(settings.database_url)
    app.state.user_store = user_store
    app.state.accounts = (
        AccountService(user_store, passwords=password_service, now=clock)
        if user_store is not None
        else None
    )
    install_error_handlers(app)

    @app.middleware("http")
    async def request_context(
        request: Request, call_next: Callable[[Request], Awaitable[Response]]
    ) -> Response:
        """Asigna el request_id, mide la duración y atrapa errores inesperados."""
        request_id = uuid.uuid4().hex
        request.state.request_id = request_id
        started = time.perf_counter()
        try:
            response = await call_next(request)
        except Exception as exc:
            # Última barrera: se registra solo el tipo y el lugar del error, y el cliente
            # recibe un mensaje genérico (constitución §5: sin trazas ni detalles).
            log_unexpected_error(exc, request_id)
            response = error_response(AppError(ErrorCode.INTERNAL_ERROR), request_id)
        response.headers["X-Request-ID"] = request_id
        logger.info(
            "request method=%s path=%s status=%s duration_ms=%d request_id=%s",
            request.method,
            request.url.path,
            response.status_code,
            (time.perf_counter() - started) * 1000,
            request_id,
        )
        return response

    app.include_router(auth.router, prefix="/api/v1")
    app.include_router(recognitions.router, prefix="/api/v1")
    app.include_router(exports.router, prefix="/api/v1")
    return app


# Instancia que usa Uvicorn: `uvicorn app.main:app`.
app = create_app()
