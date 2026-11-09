"""Pruebas de las rutas de cuentas y de la protección de la API (tareas T113 y T129).

Spec 002; contracts/auth-api.md. Cada prueba indica el escenario o criterio que verifica.
"""

from __future__ import annotations

import logging

import pytest
from fastapi.testclient import TestClient

from app.config import Settings
from app.main import create_app
from app.persistence.user_store import StoreUnavailableError
from tests.conftest import (
    TEST_EMAIL,
    TEST_PASSWORD,
    FakeOcrProvider,
    make_client,
    make_image_bytes,
)
from tests.memory_store import InMemoryUserStore

NEW_ACCOUNT = {
    "display_name": "Ana",
    "email": "ana@correo.com",
    "password": "clave-segura-123",
    "accepts_data_policy": True,
}


def _anonymous():
    return make_client(FakeOcrProvider(text="Hola"), authenticated=False)


def _code(response) -> str:
    return response.json()["error"]["code"]


def test_register_returns_a_working_session() -> None:
    """[CU-H1-E2]"""
    client = _anonymous()

    response = client.post("/api/v1/auth/register", json=NEW_ACCOUNT)

    assert response.status_code == 201
    body = response.json()
    assert body["user"]["email"] == "ana@correo.com"
    assert body["user"]["display_name"] == "Ana"
    assert "password" not in str(body)
    me = client.get("/api/v1/auth/me", headers={"Authorization": f"Bearer {body['token']}"})
    assert me.json()["user"]["id"] == body["user"]["id"]


@pytest.mark.parametrize(
    ("changes", "status", "code"),
    [
        ({"email": "no-es-correo"}, 400, "INVALID_EMAIL"),
        ({"password": "corta"}, 400, "WEAK_PASSWORD"),
        ({"display_name": ""}, 400, "INVALID_DISPLAY_NAME"),
        ({"accepts_data_policy": False}, 400, "DATA_POLICY_NOT_ACCEPTED"),
        ({"accepts_data_policy": "sí"}, 422, "VALIDATION_ERROR"),
    ],
)
def test_register_rejections(changes: dict, status: int, code: str) -> None:
    """[CU-H1-E4] [CU-H1-E5]"""
    response = _anonymous().post("/api/v1/auth/register", json=NEW_ACCOUNT | changes)

    assert response.status_code == status
    assert _code(response) == code


def test_duplicate_email_returns_409() -> None:
    """[CU-H1-E3]"""
    client = _anonymous()
    client.post("/api/v1/auth/register", json=NEW_ACCOUNT)

    response = client.post("/api/v1/auth/register", json=NEW_ACCOUNT | {"email": "ANA@correo.com"})

    assert response.status_code == 409
    assert _code(response) == "EMAIL_ALREADY_REGISTERED"


def test_schema_errors_never_echo_the_password() -> None:
    secret = "MI-CLAVE-SECRETA-999"

    response = _anonymous().post(
        "/api/v1/auth/login", json={"email": "a@b.co", "password": secret, "extra": 1}
    )

    assert response.status_code == 422
    assert secret not in response.text


def test_login_and_identical_errors() -> None:
    """[CU-H1-E6] [CU-H1-E7] [SC-203]"""
    client = make_client(FakeOcrProvider())  # ya tiene una cuenta registrada

    ok = client.post("/api/v1/auth/login", json={"email": TEST_EMAIL, "password": TEST_PASSWORD})
    wrong = client.post("/api/v1/auth/login", json={"email": TEST_EMAIL, "password": "mala-123"})
    unknown = client.post(
        "/api/v1/auth/login", json={"email": "nadie@x.co", "password": TEST_PASSWORD}
    )

    assert ok.status_code == 200 and ok.json()["token"]
    assert wrong.status_code == unknown.status_code == 401
    assert wrong.json()["error"]["message"] == unknown.json()["error"]["message"]
    assert wrong.headers["WWW-Authenticate"] == "Bearer"


def test_login_lockout_returns_429() -> None:
    """[CU-H1-E8] [SC-204]"""
    client = make_client(FakeOcrProvider())
    for _ in range(5):
        client.post("/api/v1/auth/login", json={"email": TEST_EMAIL, "password": "mala-123"})

    response = client.post(
        "/api/v1/auth/login", json={"email": TEST_EMAIL, "password": TEST_PASSWORD}
    )

    assert response.status_code == 429
    assert _code(response) == "TOO_MANY_ATTEMPTS"


@pytest.mark.parametrize("path", ["/api/v1/recognitions", "/api/v1/exports"])
@pytest.mark.parametrize("authorization", [None, "Bearer token-inventado", "Basic abc"])
def test_protected_routes_reject_missing_or_invalid_sessions(
    path: str, authorization: str | None
) -> None:
    """[SC-202] Sin sesión válida no se reconoce ni se exporta, y no se llama a Google."""
    provider = FakeOcrProvider(text="Hola")
    client = make_client(provider, authenticated=False)
    headers = {"Authorization": authorization} if authorization else {}

    response = client.post(path, content=make_image_bytes(800, 600), headers=headers)

    assert response.status_code == 401
    assert _code(response) == "UNAUTHENTICATED"
    assert provider.received == []


def test_authenticated_recognition_still_works() -> None:
    response = make_client(FakeOcrProvider(text="Hola")).post(
        "/api/v1/recognitions",
        content=make_image_bytes(800, 600),
        headers={"Content-Type": "image/png"},
    )

    assert response.status_code == 200
    assert response.json()["text"] == "Hola"


def test_local_dev_token_allows_documents_without_enabling_account_access() -> None:
    token = "local-test-secret-" + "x" * 40
    app = create_app(
        settings=Settings(
            google_vision_api_key=None,
            local_dev_token=token,
        ),
        ocr_provider=FakeOcrProvider(text="Hola"),
    )
    client = TestClient(app)
    client.headers["X-HandText-Local-Dev"] = token

    recognition = client.post(
        "/api/v1/recognitions",
        content=make_image_bytes(800, 600),
        headers={"Content-Type": "image/png"},
    )
    export = client.post("/api/v1/exports", json={"text": "Hola", "format": "docx"})
    account = client.get("/api/v1/auth/me")

    assert recognition.status_code == 200
    assert export.status_code == 200
    assert export.headers["Cache-Control"] == "no-store"
    assert account.status_code == 503
    assert _code(account) == "ACCOUNTS_UNAVAILABLE"


def test_local_dev_token_is_disabled_by_default() -> None:
    client = make_client(FakeOcrProvider(text="Hola"), authenticated=False)

    response = client.post(
        "/api/v1/recognitions",
        content=make_image_bytes(800, 600),
        headers={
            "Content-Type": "image/png",
            "X-HandText-Local-Dev": "local-test-secret-" + "x" * 40,
        },
    )

    assert response.status_code == 401


def test_logout_invalidates_the_session() -> None:
    """[CU-H2-E1]"""
    client = make_client(FakeOcrProvider())

    assert client.post("/api/v1/auth/logout").status_code == 204
    assert client.get("/api/v1/auth/me").status_code == 401


def test_delete_account_with_wrong_and_right_password() -> None:
    """[CU-H2-E3] [CU-H2-E4] [SC-205]"""
    store = InMemoryUserStore()
    client = make_client(FakeOcrProvider(), store=store)

    wrong = client.request("DELETE", "/api/v1/account", json={"password": "mala-123"})
    assert wrong.status_code == 401
    assert store.users

    right = client.request("DELETE", "/api/v1/account", json={"password": TEST_PASSWORD})
    assert right.status_code == 204
    assert store.users == {} and store.sessions == {}
    assert client.get("/api/v1/auth/me").status_code == 401


def test_without_database_accounts_return_503() -> None:
    client = TestClient(create_app(settings=Settings(google_vision_api_key=None)))

    response = client.post("/api/v1/auth/login", json={"email": "a@b.co", "password": "x"})

    assert response.status_code == 503
    assert _code(response) == "ACCOUNTS_UNAVAILABLE"


def test_database_failure_returns_503_without_details() -> None:
    class BrokenStore(InMemoryUserStore):
        def find_user_by_email(self, email: str):
            raise StoreUnavailableError

    client = make_client(FakeOcrProvider(), authenticated=False, store=BrokenStore())

    response = client.post("/api/v1/auth/login", json={"email": "a@b.co", "password": "x"})

    assert response.status_code == 503
    assert _code(response) == "ACCOUNTS_UNAVAILABLE"


def test_oversized_auth_body_returns_413() -> None:
    response = _anonymous().post(
        "/api/v1/auth/login",
        content=b"x" * (17 * 1024),
        headers={"Content-Type": "application/json"},
    )

    assert response.status_code == 413
    assert _code(response) == "REQUEST_TOO_LARGE"


def test_logs_never_contain_email_password_or_token(caplog: pytest.LogCaptureFixture) -> None:
    """[SC-201] Los registros identifican la cuenta solo por su id."""
    caplog.set_level(logging.INFO, logger="handtext")
    client = _anonymous()

    token = client.post("/api/v1/auth/register", json=NEW_ACCOUNT).json()["token"]
    client.post("/api/v1/auth/login", json={"email": "ana@correo.com", "password": "mala-123"})
    client.post("/api/v1/auth/logout", headers={"Authorization": f"Bearer {token}"})

    logs = "\n".join(record.getMessage() for record in caplog.records)
    assert "account_registered" in logs
    for secret in ("ana@correo.com", NEW_ACCOUNT["password"], "mala-123", token):
        assert secret not in logs
