"""Utilidades compartidas por las pruebas del backend (tareas T010 y T109).

Constitución §6: las muestras de prueba DEBEN ser sintéticas, públicas o anonimizadas.
Todas las imágenes de estas pruebas se generan aquí con Pillow; no se usa ningún
documento real ni se llama a Google (el OCR se reemplaza por FakeOcrProvider).

Cuentas (spec 002):
- Por defecto, cada cliente de prueba trae una cuenta registrada y su token, porque el
  reconocimiento y la exportación exigen sesión.
- `postgres_conninfo` levanta un PostgreSQL real y temporal con pgserver (una vez por
  ejecución) y le aplica las migraciones de db/migrations.
"""

from __future__ import annotations

import io
import struct
import zlib
from collections.abc import Callable, Iterator
from datetime import datetime

import pytest
from argon2 import PasswordHasher
from fastapi.testclient import TestClient
from PIL import Image, ImageDraw

from app.config import Settings
from app.main import create_app
from app.persistence.migrations import apply_migrations
from app.persistence.user_store import UserStore
from app.services.accounts.passwords import PasswordService
from app.services.ocr import OcrProvider, OcrResult
from app.services.ocr.base import UncertainSpan
from tests.memory_store import InMemoryUserStore

# Argon2id con parámetros mínimos para que las pruebas sean rápidas. La API real usa
# los parámetros predeterminados de argon2-cffi.
FAST_PASSWORDS = PasswordService(PasswordHasher(time_cost=1, memory_cost=1024, parallelism=1))
TEST_EMAIL = "persona@handtext.test"
TEST_PASSWORD = "clave-de-prueba-123"


class FakeOcrProvider:
    """Proveedor de OCR falso: devuelve un texto fijo o lanza el error indicado.

    [uncertain] son las palabras dudosas que «encontró» (spec 003).
    """

    def __init__(
        self,
        text: str = "",
        error: Exception | None = None,
        uncertain: tuple[UncertainSpan, ...] = (),
    ) -> None:
        self.text = text
        self.error = error
        self.uncertain = uncertain
        self.received: list[bytes] = []  # imágenes que «recibió», para comprobarlas

    async def recognize(self, image_jpeg: bytes) -> OcrResult:
        self.received.append(image_jpeg)
        if self.error is not None:
            raise self.error
        return OcrResult(text=self.text, uncertain_spans=self.uncertain)


def make_client(
    provider: OcrProvider | None,
    *,
    authenticated: bool = True,
    store: UserStore | None = None,
    clock: Callable[[], datetime] | None = None,
) -> TestClient:
    """Cliente de prueba de la API.

    - provider=None simula la falta de la clave de Google.
    - authenticated=True registra una cuenta y envía su token en cada solicitud.
    """
    app = create_app(
        settings=Settings(google_vision_api_key=None),
        ocr_provider=provider,
        user_store=store if store is not None else InMemoryUserStore(),
        password_service=FAST_PASSWORDS,
        clock=clock,
    )
    client = TestClient(app)
    if authenticated:
        grant = app.state.accounts.register(
            display_name="Persona de prueba",
            email=TEST_EMAIL,
            password=TEST_PASSWORD,
            accepts_data_policy=True,
        )
        client.headers["Authorization"] = f"Bearer {grant.token}"
    return client


@pytest.fixture(scope="session")
def postgres_conninfo(tmp_path_factory: pytest.TempPathFactory) -> Iterator[str]:
    """PostgreSQL real y temporal (pgserver) con las migraciones aplicadas."""
    pgserver = pytest.importorskip("pgserver")
    server = pgserver.get_server(str(tmp_path_factory.mktemp("postgres")), cleanup_mode="delete")
    try:
        conninfo = server.get_uri()
        apply_migrations(conninfo)
        yield conninfo
    finally:
        server.cleanup()


def make_image_bytes(
    width: int,
    height: int,
    image_format: str = "PNG",
    mode: str = "RGB",
    color: str | tuple[int, ...] = "white",
    exif: Image.Exif | None = None,
) -> bytes:
    """Genera una imagen sintética (una hoja con una palabra) en memoria."""
    image = Image.new(mode, (width, height), color)
    if mode == "RGB":
        ImageDraw.Draw(image).text((10, 10), "Apuntes", fill="black")
    buffer = io.BytesIO()
    extra = {"exif": exif} if exif is not None else {}
    image.save(buffer, format=image_format, **extra)
    return buffer.getvalue()


def make_noisy_jpeg(width: int = 800, height: int = 800) -> bytes:
    """JPEG con ruido: pesa bastante, útil para simular un archivo cortado a la mitad."""
    image = Image.effect_noise((width, height), 64).convert("RGB")
    buffer = io.BytesIO()
    image.save(buffer, format="JPEG", quality=95)
    return buffer.getvalue()


def make_png_header_only(width: int, height: int) -> bytes:
    """PNG que solo declara sus dimensiones (sin píxeles); sirve para probar límites."""

    def chunk(kind: bytes, data: bytes) -> bytes:
        crc = zlib.crc32(kind + data) & 0xFFFFFFFF
        return struct.pack(">I", len(data)) + kind + data + struct.pack(">I", crc)

    header = struct.pack(">IIBBBBB", width, height, 8, 2, 0, 0, 0)
    return b"\x89PNG\r\n\x1a\n" + chunk(b"IHDR", header) + chunk(b"IEND", b"")
