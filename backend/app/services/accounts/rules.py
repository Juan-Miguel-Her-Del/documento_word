"""Reglas de los datos de la cuenta (tarea T115; spec 002, módulo 1; CU-H1-E4).

La app aplica las mismas reglas antes de enviar el formulario, para orientar al usuario;
el backend las vuelve a aplicar porque no puede confiar en el cliente (constitución §5).
"""

from __future__ import annotations

import re

from app.config import (
    DISPLAY_NAME_MAX_CHARS,
    EMAIL_MAX_CHARS,
    PASSWORD_MAX_CHARS,
    PASSWORD_MIN_CHARS,
)
from app.errors import AppError, ErrorCode

# Forma básica de un correo: algo@dominio.ext, sin espacios. La verificación real del
# correo (enviar un mensaje) está fuera de esta iteración (Non-Goals de 002).
_EMAIL_PATTERN = re.compile(r"^[^@\s]+@[^@\s]+\.[^@\s]+$")


def normalize_email(email: str) -> str:
    """Quita espacios y pasa a minúsculas: «Ana@Correo.com » = «ana@correo.com»."""
    return email.strip().lower()


def validate_email(email: str) -> str:
    """Devuelve el correo normalizado o lanza INVALID_EMAIL."""
    normalized = normalize_email(email)
    if len(normalized) > EMAIL_MAX_CHARS or not _EMAIL_PATTERN.match(normalized):
        raise AppError(ErrorCode.INVALID_EMAIL)
    return normalized


def validate_display_name(display_name: str) -> str:
    """Une los espacios repetidos y exige de 1 a 60 caracteres visibles."""
    cleaned = " ".join(display_name.split())
    if not 1 <= len(cleaned) <= DISPLAY_NAME_MAX_CHARS or not cleaned.isprintable():
        raise AppError(ErrorCode.INVALID_DISPLAY_NAME)
    return cleaned


def validate_new_password(password: str) -> None:
    """Exige longitud (8 a 128) y algo más que espacios (supuesto 4 de la spec 002)."""
    if not PASSWORD_MIN_CHARS <= len(password) <= PASSWORD_MAX_CHARS or not password.strip():
        raise AppError(ErrorCode.WEAK_PASSWORD)
