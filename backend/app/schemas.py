"""Modelos de datos de entrada y salida de la API (tarea T008).

Pydantic valida automáticamente la forma de los datos. Las reglas de contenido (texto
vacío, caracteres, tamaños) están en services/ porque dependen del spec, no del esquema.
"""

from __future__ import annotations

from enum import StrEnum
from typing import Literal

from pydantic import BaseModel, ConfigDict, StrictBool


class RecognitionStatus(StrEnum):
    """Resultado del reconocimiento (spec, módulo 2)."""

    TEXT_FOUND = "text_found"  # hay texto para revisar
    NO_TEXT = "no_text"  # la imagen se procesó, pero no tenía texto reconocible


class UncertainWord(BaseModel):
    """Palabra dudosa: `text[start:end]`, en puntos de código (spec 003, módulo 1)."""

    start: int
    end: int


class RecognitionResponse(BaseModel):
    """Respuesta de POST /api/v1/recognitions (contracts/api.md; en 003, recognition-api.md)."""

    status: RecognitionStatus
    text: str
    uncertain_words: list[UncertainWord]  # spec 003: lista vacía si no hay
    request_id: str


# Formatos de salida autorizados por la constitución §3: Word (.docx) y PDF (.pdf).
ExportFormat = Literal["docx", "pdf"]


class ExportRequest(BaseModel):
    """Cuerpo de POST /api/v1/exports."""

    # extra="forbid": un campo desconocido es un error de esquema (422), no se ignora.
    model_config = ConfigDict(extra="forbid")

    text: str
    format: ExportFormat


# --- Cuentas de usuario (spec 002; contracts/auth-api.md) ----------------------------


class RegisterRequest(BaseModel):
    """Cuerpo de POST /api/v1/auth/register."""

    model_config = ConfigDict(extra="forbid")

    display_name: str
    email: str
    password: str
    # StrictBool: solo se acepta el valor JSON `true`/`false`, no "sí" ni 1.
    accepts_data_policy: StrictBool


class LoginRequest(BaseModel):
    """Cuerpo de POST /api/v1/auth/login."""

    model_config = ConfigDict(extra="forbid")

    email: str
    password: str


class DeleteAccountRequest(BaseModel):
    """Cuerpo de DELETE /api/v1/account: se confirma con la contraseña."""

    model_config = ConfigDict(extra="forbid")

    password: str


class UserResponse(BaseModel):
    """Datos visibles de la cuenta (nunca el hash de la contraseña)."""

    id: str
    display_name: str
    email: str


class SessionResponse(BaseModel):
    """Respuesta del registro y del ingreso: el token se entrega una sola vez."""

    token: str
    user: UserResponse


class MeResponse(BaseModel):
    """Respuesta de GET /api/v1/auth/me."""

    user: UserResponse
