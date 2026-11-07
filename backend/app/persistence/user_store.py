"""Contrato del almacén de usuarios y sesiones (tarea T106; data-model.md de 002).

El servicio de cuentas solo conoce este contrato. En producción lo cumple
PostgresUserStore; en las pruebas, un almacén en memoria que se comporta igual (las
mismas pruebas de contrato se ejecutan contra ambos).
"""

from __future__ import annotations

from dataclasses import dataclass
from datetime import datetime, timedelta
from typing import Protocol


@dataclass(frozen=True)
class UserRecord:
    """Una fila de la tabla users. `password_hash` es Argon2id, nunca la contraseña."""

    id: str
    email: str
    display_name: str
    password_hash: str
    failed_login_attempts: int
    locked_until: datetime | None


class EmailAlreadyRegisteredError(Exception):
    """Ya existe una cuenta con ese correo (restricción UNIQUE de la base)."""


class StoreUnavailableError(Exception):
    """La base de datos no responde o no se pudo conectar (se responde 503)."""


class UserStore(Protocol):
    """Operaciones que el servicio de cuentas necesita de la base."""

    def create_user(
        self, *, email: str, display_name: str, password_hash: str, accepted_at: datetime
    ) -> UserRecord:
        """Crea la cuenta o lanza EmailAlreadyRegisteredError."""
        ...

    def find_user_by_email(self, email: str) -> UserRecord | None:
        """Busca por correo ya normalizado."""
        ...

    def register_failed_login(
        self, user_id: str, *, now: datetime, max_attempts: int, lock_duration: timedelta
    ) -> None:
        """Suma un fallo; al llegar a `max_attempts` bloquea la cuenta y reinicia el conteo."""
        ...

    def reset_failed_logins(self, user_id: str) -> None:
        """Borra el conteo de fallos y el bloqueo tras un ingreso correcto."""
        ...

    def create_session(self, *, token_hash: str, user_id: str, expires_at: datetime) -> None:
        """Guarda una sesión (solo el hash del token)."""
        ...

    def find_user_by_session(self, token_hash: str, *, now: datetime) -> UserRecord | None:
        """Devuelve el dueño de una sesión vigente, o None si no existe o venció."""
        ...

    def delete_session(self, token_hash: str) -> None:
        """Cierra una sesión."""
        ...

    def delete_user(self, user_id: str) -> None:
        """Elimina la cuenta y, en cascada, todas sus sesiones."""
        ...
