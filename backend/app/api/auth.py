"""Rutas de cuentas y protección de la API (tarea T117; spec 002; contracts/auth-api.md).

- POST /auth/register, POST /auth/login, POST /auth/logout, GET /auth/me y
  DELETE /account.
- `require_user` (y su alias CurrentUser) protege las rutas: sin
  `Authorization: Bearer <token>` válido responde 401 [SC-202]. Constitución §3, Acceso:
  la autenticación se verifica en CADA solicitud.
- Los cuerpos se validan a mano: un error de esquema nunca repite la contraseña enviada.
- Los registros guardan el id de la cuenta, nunca el correo, la contraseña ni el token.
"""

from __future__ import annotations

import logging
from typing import Annotated

from fastapi import APIRouter, Depends, Request
from fastapi.responses import Response
from pydantic import BaseModel, ValidationError
from starlette.concurrency import run_in_threadpool

from app.api.request_body import read_body_limited
from app.config import MAX_AUTH_BODY_BYTES
from app.errors import AppError, ErrorCode, request_id_of
from app.persistence.user_store import UserRecord
from app.schemas import (
    DeleteAccountRequest,
    LoginRequest,
    MeResponse,
    RegisterRequest,
    SessionResponse,
    UserResponse,
)
from app.services.accounts.account_service import AccountService, SessionGrant

logger = logging.getLogger("handtext")
router = APIRouter(tags=["Cuentas"])


def get_accounts(request: Request) -> AccountService:
    """Servicio de cuentas, o 503 si la API no tiene base de datos configurada."""
    accounts: AccountService | None = request.app.state.accounts
    if accounts is None:
        raise AppError(ErrorCode.ACCOUNTS_UNAVAILABLE)
    return accounts


def bearer_token(request: Request) -> str:
    """Extrae el token de la cabecera `Authorization: Bearer <token>`."""
    scheme, _, token = request.headers.get("authorization", "").partition(" ")
    if scheme.lower() != "bearer" or not token.strip():
        raise AppError(ErrorCode.UNAUTHENTICATED)
    return token.strip()


def require_user(request: Request) -> UserRecord:
    """Dependencia de las rutas protegidas: devuelve la cuenta dueña de la sesión.

    Es síncrona a propósito: FastAPI la ejecuta en un hilo aparte porque consulta la base.
    """
    return get_accounts(request).authenticate(bearer_token(request))


# Forma de pedir la cuenta en una ruta:  def ruta(user: CurrentUser): ...
CurrentUser = Annotated[UserRecord, Depends(require_user)]


def _json_body(model: type[BaseModel]) -> dict:
    """Describe el cuerpo JSON en la documentación interactiva (/docs)."""
    return {
        "requestBody": {
            "required": True,
            "content": {"application/json": {"schema": model.model_json_schema()}},
        }
    }


async def _read_json[ModelT: BaseModel](request: Request, model: type[ModelT]) -> ModelT:
    """Lee el cuerpo (máximo 16 KB) y lo valida con el modelo indicado."""
    raw = await read_body_limited(request, MAX_AUTH_BODY_BYTES, ErrorCode.REQUEST_TOO_LARGE)
    try:
        return model.model_validate_json(raw)
    except ValidationError:
        # Sin detalles: el detalle de Pydantic repetiría lo enviado, incluida la contraseña.
        raise AppError(ErrorCode.VALIDATION_ERROR) from None


def _session_response(grant: SessionGrant) -> SessionResponse:
    return SessionResponse(token=grant.token, user=_user_response(grant.user))


def _user_response(user: UserRecord) -> UserResponse:
    return UserResponse(id=user.id, display_name=user.display_name, email=user.email)


@router.post(
    "/auth/register",
    status_code=201,
    response_model=SessionResponse,
    summary="Crear una cuenta e iniciar sesión",
    openapi_extra=_json_body(RegisterRequest),
)
async def register(request: Request) -> SessionResponse:
    """[CU-H1-E2] Registro; la sesión queda iniciada."""
    accounts = get_accounts(request)
    body = await _read_json(request, RegisterRequest)
    grant = await run_in_threadpool(
        lambda: accounts.register(
            display_name=body.display_name,
            email=body.email,
            password=body.password,
            accepts_data_policy=body.accepts_data_policy,
        )
    )
    logger.info(
        "account_registered user_id=%s request_id=%s", grant.user.id, request_id_of(request)
    )
    return _session_response(grant)


@router.post(
    "/auth/login",
    response_model=SessionResponse,
    summary="Iniciar sesión con correo y contraseña",
    openapi_extra=_json_body(LoginRequest),
)
async def login(request: Request) -> SessionResponse:
    """[CU-H1-E6] Ingreso. Datos incorrectos: 401; cuenta bloqueada: 429."""
    accounts = get_accounts(request)
    body = await _read_json(request, LoginRequest)
    grant = await run_in_threadpool(
        lambda: accounts.login(email=body.email, password=body.password)
    )
    logger.info("login user_id=%s request_id=%s", grant.user.id, request_id_of(request))
    return _session_response(grant)


@router.post("/auth/logout", status_code=204, summary="Cerrar la sesión actual")
async def logout(request: Request, user: CurrentUser) -> Response:
    """[CU-H2-E1] La sesión deja de servir en el servidor."""
    await run_in_threadpool(get_accounts(request).logout, bearer_token(request))
    logger.info("logout user_id=%s request_id=%s", user.id, request_id_of(request))
    return Response(status_code=204)


@router.get("/auth/me", response_model=MeResponse, summary="Datos de la cuenta con sesión")
def me(user: CurrentUser) -> MeResponse:
    """[CU-H1-E9] La app lo usa al abrirse para comprobar que la sesión sigue vigente."""
    return MeResponse(user=_user_response(user))


@router.delete(
    "/account",
    status_code=204,
    summary="Eliminar la cuenta (confirmando con la contraseña)",
    openapi_extra=_json_body(DeleteAccountRequest),
)
async def delete_account(request: Request, user: CurrentUser) -> Response:
    """[CU-H2-E3] [CU-H2-E4] Borra la cuenta y sus sesiones [SC-205]."""
    accounts = get_accounts(request)
    body = await _read_json(request, DeleteAccountRequest)
    await run_in_threadpool(accounts.delete_account, user, body.password)
    logger.info("account_deleted user_id=%s request_id=%s", user.id, request_id_of(request))
    return Response(status_code=204)
