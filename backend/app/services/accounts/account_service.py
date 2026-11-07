"""Servicio de cuentas: registro, ingreso, bloqueo, sesiones y eliminación (tarea T116).

Spec 002, módulos 1 a 4. Etiquetas de los escenarios: [CU-H1-E2] = Historia 1,
escenario 2, de la spec 002.
"""

from __future__ import annotations

from collections.abc import Callable
from dataclasses import dataclass
from datetime import UTC, datetime

from app.config import LOGIN_LOCK_DURATION, MAX_FAILED_LOGINS, SESSION_DURATION
from app.errors import AppError, ErrorCode
from app.persistence.user_store import EmailAlreadyRegisteredError, UserRecord, UserStore
from app.services.accounts.passwords import PasswordService
from app.services.accounts.rules import (
    normalize_email,
    validate_display_name,
    validate_email,
    validate_new_password,
)
from app.services.accounts.tokens import hash_session_token, new_session_token


def _utc_now() -> datetime:
    return datetime.now(UTC)


@dataclass(frozen=True)
class SessionGrant:
    """Sesión recién creada: el token (que se entrega una sola vez) y su dueño."""

    token: str
    user: UserRecord


class AccountService:
    def __init__(
        self,
        store: UserStore,
        passwords: PasswordService | None = None,
        now: Callable[[], datetime] | None = None,
    ) -> None:
        self._store = store
        self._passwords = passwords or PasswordService()
        # Reloj inyectable: las pruebas adelantan el tiempo para probar bloqueos y vencimientos.
        self._now = now or _utc_now

    def register(
        self, *, display_name: str, email: str, password: str, accepts_data_policy: bool
    ) -> SessionGrant:
        """[CU-H1-E2] Crea la cuenta e inicia la sesión."""
        name = validate_display_name(display_name)  # [CU-H1-E4]
        normalized_email = validate_email(email)
        validate_new_password(password)
        if accepts_data_policy is not True:
            raise AppError(ErrorCode.DATA_POLICY_NOT_ACCEPTED)  # [CU-H1-E5]

        try:
            user = self._store.create_user(
                email=normalized_email,
                display_name=name,
                password_hash=self._passwords.hash(password),  # [SC-201] nunca en claro
                accepted_at=self._now(),
            )
        except EmailAlreadyRegisteredError:
            raise AppError(ErrorCode.EMAIL_ALREADY_REGISTERED) from None  # [CU-H1-E3]
        return self._start_session(user)

    def login(self, *, email: str, password: str) -> SessionGrant:
        """[CU-H1-E6] Ingresa con correo y contraseña."""
        user = self._store.find_user_by_email(normalize_email(email))
        if user is None:
            # [CU-H1-E7] [SC-203] Mismo mensaje y mismo tiempo que con una contraseña mala.
            self._passwords.verify_dummy(password)
            raise AppError(ErrorCode.INVALID_CREDENTIALS)

        now = self._now()
        if user.locked_until is not None and user.locked_until > now:
            raise AppError(ErrorCode.TOO_MANY_ATTEMPTS)  # [CU-H1-E8] [SC-204]

        if not self._passwords.verify(user.password_hash, password):
            self._store.register_failed_login(
                user.id, now=now, max_attempts=MAX_FAILED_LOGINS, lock_duration=LOGIN_LOCK_DURATION
            )
            raise AppError(ErrorCode.INVALID_CREDENTIALS)

        if user.failed_login_attempts or user.locked_until is not None:
            self._store.reset_failed_logins(user.id)
        return self._start_session(user)

    def authenticate(self, token: str) -> UserRecord:
        """[SC-202] Devuelve el dueño de una sesión vigente o lanza UNAUTHENTICATED."""
        user = self._store.find_user_by_session(hash_session_token(token), now=self._now())
        if user is None:
            raise AppError(ErrorCode.UNAUTHENTICATED)  # [CU-H2-E5]
        return user

    def logout(self, token: str) -> None:
        """[CU-H2-E1] Cierra la sesión: el token deja de servir en el servidor."""
        self._store.delete_session(hash_session_token(token))

    def delete_account(self, user: UserRecord, password: str) -> None:
        """[CU-H2-E3] [CU-H2-E4] Elimina la cuenta si la contraseña es correcta."""
        if not self._passwords.verify(user.password_hash, password):
            raise AppError(ErrorCode.INVALID_CREDENTIALS)
        self._store.delete_user(user.id)  # [SC-205] borra también sus sesiones

    def _start_session(self, user: UserRecord) -> SessionGrant:
        token = new_session_token()
        self._store.create_session(
            token_hash=hash_session_token(token),  # [SC-201] solo el hash
            user_id=user.id,
            expires_at=self._now() + SESSION_DURATION,  # [CU-H1-E9] 30 días
        )
        return SessionGrant(token=token, user=user)
