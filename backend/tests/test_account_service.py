"""Pruebas del servicio de cuentas (tarea T112; spec 002, Historias 1 y 2).

Usan el almacén en memoria y un reloj falso que se puede adelantar, para probar el
bloqueo de 15 minutos y el vencimiento de 30 días sin esperar.
"""

from __future__ import annotations

from datetime import UTC, datetime, timedelta

import pytest

from app.errors import AppError, ErrorCode
from app.services.accounts.account_service import AccountService
from tests.conftest import FAST_PASSWORDS
from tests.memory_store import InMemoryUserStore

PASSWORD = "clave-segura-123"


class FakeClock:
    def __init__(self) -> None:
        self.now = datetime(2026, 10, 27, 12, 0, tzinfo=UTC)

    def __call__(self) -> datetime:
        return self.now

    def advance(self, **delta: float) -> None:
        self.now += timedelta(**delta)


@pytest.fixture
def clock() -> FakeClock:
    return FakeClock()


@pytest.fixture
def store() -> InMemoryUserStore:
    return InMemoryUserStore()


@pytest.fixture
def service(store: InMemoryUserStore, clock: FakeClock) -> AccountService:
    return AccountService(store, passwords=FAST_PASSWORDS, now=clock)


def _register(service: AccountService, email: str = "Ana@Correo.com", **changes: object):
    data = {
        "display_name": "  Ana   María ",
        "email": email,
        "password": PASSWORD,
        "accepts_data_policy": True,
    } | changes
    return service.register(**data)


def _code(action) -> ErrorCode:
    with pytest.raises(AppError) as raised:
        action()
    return raised.value.code


def test_register_creates_the_account_and_a_session(service: AccountService) -> None:
    grant = _register(service)

    assert grant.user.email == "ana@correo.com"  # normalizado
    assert grant.user.display_name == "Ana María"  # espacios repetidos unidos
    assert grant.user.password_hash.startswith("$argon2id$")  # [SC-201]
    assert PASSWORD not in grant.user.password_hash
    assert service.authenticate(grant.token) == grant.user


def test_email_is_unique_ignoring_case(service: AccountService) -> None:
    """[CU-H1-E3]"""
    _register(service)

    assert _code(lambda: _register(service, email=" ANA@correo.COM ")) is (
        ErrorCode.EMAIL_ALREADY_REGISTERED
    )


@pytest.mark.parametrize(
    ("changes", "code"),
    [
        ({"email": "sin-arroba.com"}, ErrorCode.INVALID_EMAIL),
        ({"email": "ana@correo"}, ErrorCode.INVALID_EMAIL),
        ({"email": "a" * 250 + "@x.co"}, ErrorCode.INVALID_EMAIL),
        ({"display_name": "   "}, ErrorCode.INVALID_DISPLAY_NAME),
        ({"display_name": "x" * 61}, ErrorCode.INVALID_DISPLAY_NAME),
        ({"password": "1234567"}, ErrorCode.WEAK_PASSWORD),
        ({"password": "x" * 129}, ErrorCode.WEAK_PASSWORD),
        ({"password": "        "}, ErrorCode.WEAK_PASSWORD),
        ({"accepts_data_policy": False}, ErrorCode.DATA_POLICY_NOT_ACCEPTED),
    ],
)
def test_invalid_registrations_are_rejected_with_their_reason(
    service: AccountService, store: InMemoryUserStore, changes: dict, code: ErrorCode
) -> None:
    """[CU-H1-E4] [CU-H1-E5] Y la cuenta no se crea."""
    assert _code(lambda: _register(service, **changes)) is code
    assert store.users == {}


def test_login_with_correct_credentials(service: AccountService) -> None:
    """[CU-H1-E6]"""
    registered = _register(service)

    grant = service.login(email="  ANA@correo.com", password=PASSWORD)

    assert grant.user.id == registered.user.id
    assert grant.token != registered.token  # cada ingreso es una sesión nueva


def test_unknown_email_and_wrong_password_look_identical(service: AccountService) -> None:
    """[CU-H1-E7] [SC-203]"""
    _register(service)

    with pytest.raises(AppError) as wrong_password:
        service.login(email="ana@correo.com", password="otra-clave-999")
    with pytest.raises(AppError) as unknown_email:
        service.login(email="nadie@correo.com", password=PASSWORD)

    assert wrong_password.value.code is unknown_email.value.code is ErrorCode.INVALID_CREDENTIALS
    assert wrong_password.value.message == unknown_email.value.message


def test_five_failures_lock_login_for_15_minutes(service: AccountService, clock: FakeClock) -> None:
    """[CU-H1-E8] [SC-204] Ni la contraseña correcta entra durante el bloqueo."""
    _register(service)
    for _ in range(5):
        _code(lambda: service.login(email="ana@correo.com", password="mala-clave-1"))

    assert _code(lambda: service.login(email="ana@correo.com", password=PASSWORD)) is (
        ErrorCode.TOO_MANY_ATTEMPTS
    )
    clock.advance(minutes=14)
    assert _code(lambda: service.login(email="ana@correo.com", password=PASSWORD)) is (
        ErrorCode.TOO_MANY_ATTEMPTS
    )

    clock.advance(minutes=2)
    assert service.login(email="ana@correo.com", password=PASSWORD).token


def test_a_successful_login_resets_the_failure_count(service: AccountService) -> None:
    _register(service)
    for _ in range(4):
        _code(lambda: service.login(email="ana@correo.com", password="mala-clave-1"))
    service.login(email="ana@correo.com", password=PASSWORD)

    for _ in range(4):
        _code(lambda: service.login(email="ana@correo.com", password="mala-clave-1"))

    assert service.login(email="ana@correo.com", password=PASSWORD).token


def test_sessions_last_30_days(service: AccountService, clock: FakeClock) -> None:
    """[CU-H1-E9] [CU-H2-E5]"""
    token = _register(service).token
    clock.advance(days=29, hours=23)
    assert service.authenticate(token)

    clock.advance(hours=2)
    assert _code(lambda: service.authenticate(token)) is ErrorCode.UNAUTHENTICATED


def test_logout_invalidates_the_token(service: AccountService) -> None:
    """[CU-H2-E1]"""
    token = _register(service).token

    service.logout(token)

    assert _code(lambda: service.authenticate(token)) is ErrorCode.UNAUTHENTICATED


def test_delete_account_requires_the_password(
    service: AccountService, store: InMemoryUserStore
) -> None:
    """[CU-H2-E3] [CU-H2-E4] [SC-205]"""
    grant = _register(service)

    assert _code(lambda: service.delete_account(grant.user, "otra-clave-999")) is (
        ErrorCode.INVALID_CREDENTIALS
    )
    assert store.users  # la cuenta sigue

    service.delete_account(grant.user, PASSWORD)

    assert store.users == {}
    assert store.sessions == {}
    assert _code(lambda: service.authenticate(grant.token)) is ErrorCode.UNAUTHENTICATED
