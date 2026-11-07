"""Almacén de usuarios y sesiones en PostgreSQL (tarea T107; research.md de 002, R3).

Constitución §2: todas las consultas son parametrizadas (`%s`). Los valores nunca se
pegan dentro del texto SQL, lo que evita la inyección SQL.

- psycopg 3 síncrono con un pool de conexiones. Las rutas asíncronas lo llaman en un
  hilo aparte, porque el modo asíncrono de psycopg no funciona con el bucle de eventos
  predeterminado de Windows.
- Si la base no responde, se lanza StoreUnavailableError y la API responde 503.
"""

from __future__ import annotations

from collections.abc import Iterator
from contextlib import contextmanager
from datetime import datetime, timedelta

import psycopg
from psycopg.rows import dict_row
from psycopg_pool import ConnectionPool, PoolTimeout

from app.persistence.user_store import (
    EmailAlreadyRegisteredError,
    StoreUnavailableError,
    UserRecord,
)

# Columnas que se leen de users (el id UUID se convierte a texto).
_USER_COLUMNS = (
    "u.id::text AS id, u.email, u.display_name, u.password_hash, "
    "u.failed_login_attempts, u.locked_until"
)


class PostgresUserStore:
    """Implementa el contrato UserStore sobre las tablas users y sessions."""

    def __init__(self, pool: ConnectionPool) -> None:
        self._pool = pool

    @classmethod
    def connect(cls, conninfo: str) -> PostgresUserStore:
        """Prepara el pool; se abre con open() al iniciar la API (lifespan de main.py)."""
        pool = ConnectionPool(
            conninfo,
            min_size=1,
            max_size=10,
            timeout=5,  # segundos de espera por una conexión antes de responder 503
            kwargs={"row_factory": dict_row},
            open=False,
        )
        return cls(pool)

    def open(self) -> None:
        self._pool.open(wait=False)

    def close(self) -> None:
        self._pool.close()

    @contextmanager
    def _connection(self) -> Iterator[psycopg.Connection]:
        """Presta una conexión. Al salir sin errores, confirma (commit) la transacción."""
        try:
            with self._pool.connection() as connection:
                yield connection
        except (psycopg.OperationalError, PoolTimeout):
            raise StoreUnavailableError from None

    def create_user(
        self, *, email: str, display_name: str, password_hash: str, accepted_at: datetime
    ) -> UserRecord:
        try:
            with self._connection() as connection:
                row = connection.execute(
                    "INSERT INTO users AS u (email, display_name, password_hash, "
                    "data_policy_accepted_at) VALUES (%s, %s, %s, %s) "
                    f"RETURNING {_USER_COLUMNS}",
                    (email, display_name, password_hash, accepted_at),
                ).fetchone()
        except psycopg.errors.UniqueViolation:
            raise EmailAlreadyRegisteredError from None
        return UserRecord(**row)

    def find_user_by_email(self, email: str) -> UserRecord | None:
        with self._connection() as connection:
            row = connection.execute(
                f"SELECT {_USER_COLUMNS} FROM users u WHERE u.email = %s", (email,)
            ).fetchone()
        return UserRecord(**row) if row else None

    def register_failed_login(
        self, user_id: str, *, now: datetime, max_attempts: int, lock_duration: timedelta
    ) -> None:
        # Una sola sentencia: suma el fallo y, si llega al máximo, bloquea y reinicia.
        with self._connection() as connection:
            connection.execute(
                "UPDATE users SET "
                "failed_login_attempts = CASE WHEN failed_login_attempts + 1 >= %(max)s "
                "THEN 0 ELSE failed_login_attempts + 1 END, "
                "locked_until = CASE WHEN failed_login_attempts + 1 >= %(max)s "
                "THEN %(now)s + %(lock)s ELSE locked_until END "
                "WHERE id = %(id)s::uuid",
                {"max": max_attempts, "now": now, "lock": lock_duration, "id": user_id},
            )

    def reset_failed_logins(self, user_id: str) -> None:
        with self._connection() as connection:
            connection.execute(
                "UPDATE users SET failed_login_attempts = 0, locked_until = NULL "
                "WHERE id = %s::uuid",
                (user_id,),
            )

    def create_session(self, *, token_hash: str, user_id: str, expires_at: datetime) -> None:
        with self._connection() as connection:
            # Limpieza: se borran las sesiones vencidas de esa persona.
            connection.execute(
                "DELETE FROM sessions WHERE user_id = %s::uuid AND expires_at <= now()",
                (user_id,),
            )
            connection.execute(
                "INSERT INTO sessions (token_hash, user_id, expires_at) VALUES (%s, %s::uuid, %s)",
                (token_hash, user_id, expires_at),
            )

    def find_user_by_session(self, token_hash: str, *, now: datetime) -> UserRecord | None:
        with self._connection() as connection:
            row = connection.execute(
                f"SELECT {_USER_COLUMNS} FROM sessions s JOIN users u ON u.id = s.user_id "
                "WHERE s.token_hash = %s AND s.expires_at > %s",
                (token_hash, now),
            ).fetchone()
        return UserRecord(**row) if row else None

    def delete_session(self, token_hash: str) -> None:
        with self._connection() as connection:
            connection.execute("DELETE FROM sessions WHERE token_hash = %s", (token_hash,))

    def delete_user(self, user_id: str) -> None:
        with self._connection() as connection:
            # ON DELETE CASCADE borra también sus sesiones (SC-205).
            connection.execute("DELETE FROM users WHERE id = %s::uuid", (user_id,))
