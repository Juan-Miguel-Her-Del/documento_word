"""Pruebas de contrato del almacén de usuarios (tarea T109; constitución §6, persistencia).

Cada prueba se ejecuta dos veces: contra el almacén en memoria y contra PostgreSQL real
(pgserver). Así se garantiza que las consultas SQL hacen lo mismo que el modelo esperado.
"""

from __future__ import annotations

from collections.abc import Iterator
from datetime import UTC, datetime, timedelta

import psycopg
import pytest

from app.persistence.migrations import apply_migrations
from app.persistence.postgres_store import PostgresUserStore
from app.persistence.user_store import EmailAlreadyRegisteredError, UserStore
from app.services.accounts.account_service import AccountService
from tests.conftest import FAST_PASSWORDS
from tests.memory_store import InMemoryUserStore

NOW = datetime(2026, 10, 27, 12, 0, tzinfo=UTC)
LOCK = timedelta(minutes=15)


@pytest.fixture(params=["memoria", "postgres"])
def store(request: pytest.FixtureRequest) -> Iterator[UserStore]:
    if request.param == "memoria":
        yield InMemoryUserStore()
        return
    conninfo = request.getfixturevalue("postgres_conninfo")
    with psycopg.connect(conninfo) as connection:
        connection.execute("TRUNCATE users CASCADE")  # cada prueba empieza vacía
    postgres = PostgresUserStore.connect(conninfo)
    postgres.open()
    try:
        yield postgres
    finally:
        postgres.close()


def _create(store: UserStore, email: str = "ana@correo.com"):
    return store.create_user(
        email=email, display_name="Ana", password_hash="hash-argon2", accepted_at=NOW
    )


def test_create_and_find_by_email(store: UserStore) -> None:
    created = _create(store)

    found = store.find_user_by_email("ana@correo.com")

    assert found == created
    assert found.failed_login_attempts == 0
    assert found.locked_until is None
    assert store.find_user_by_email("otra@correo.com") is None


def test_email_must_be_unique(store: UserStore) -> None:
    _create(store)

    with pytest.raises(EmailAlreadyRegisteredError):
        _create(store)


def test_sessions_expire_and_can_be_deleted(store: UserStore) -> None:
    user = _create(store)
    store.create_session(token_hash="h1", user_id=user.id, expires_at=NOW + timedelta(days=30))

    assert store.find_user_by_session("h1", now=NOW) == user
    assert store.find_user_by_session("h1", now=NOW + timedelta(days=31)) is None
    assert store.find_user_by_session("otro", now=NOW) is None

    store.delete_session("h1")
    assert store.find_user_by_session("h1", now=NOW) is None


def test_five_failures_lock_the_account(store: UserStore) -> None:
    user = _create(store)
    for _ in range(4):
        store.register_failed_login(user.id, now=NOW, max_attempts=5, lock_duration=LOCK)
    assert store.find_user_by_email(user.email).failed_login_attempts == 4

    store.register_failed_login(user.id, now=NOW, max_attempts=5, lock_duration=LOCK)

    locked = store.find_user_by_email(user.email)
    assert locked.locked_until == NOW + LOCK
    assert locked.failed_login_attempts == 0

    store.reset_failed_logins(user.id)
    assert store.find_user_by_email(user.email).locked_until is None


def test_deleting_a_user_deletes_its_sessions(store: UserStore) -> None:
    user = _create(store)
    store.create_session(token_hash="h1", user_id=user.id, expires_at=NOW + timedelta(days=1))

    store.delete_user(user.id)

    assert store.find_user_by_email(user.email) is None
    assert store.find_user_by_session("h1", now=NOW) is None


def test_migrations_are_idempotent(postgres_conninfo: str) -> None:
    # Ya se aplicaron al crear la base: volver a ejecutarlas no aplica nada.
    assert apply_migrations(postgres_conninfo) == []


def test_database_never_stores_plain_passwords_or_tokens(postgres_conninfo: str) -> None:
    """[SC-201] Ni la contraseña ni el token aparecen en la base."""
    with psycopg.connect(postgres_conninfo) as connection:
        connection.execute("TRUNCATE users CASCADE")
    postgres = PostgresUserStore.connect(postgres_conninfo)
    postgres.open()
    try:
        grant = AccountService(postgres, passwords=FAST_PASSWORDS).register(
            display_name="Ana",
            email="ana@correo.com",
            password="mi-clave-secreta-123",
            accepts_data_policy=True,
        )
    finally:
        postgres.close()

    with psycopg.connect(postgres_conninfo) as connection:
        users = connection.execute("SELECT * FROM users").fetchall()
        sessions = connection.execute("SELECT * FROM sessions").fetchall()
    stored = " ".join(str(value) for row in users + sessions for value in row)
    assert "mi-clave-secreta-123" not in stored
    assert grant.token not in stored
    assert "$argon2id$" in stored  # lo que se guarda es el hash
