"""Configuración del backend de HandText AI (tarea T005).

Aquí están, en un solo lugar, los valores que el spec acordó el 2026-10-26
(sección Clarifications) y las decisiones técnicas del plan:

- Imágenes (spec, módulo 1): JPEG y PNG, hasta 10 MB, de 600 a 10 000 px por lado.
- Idiomas (spec, módulo 2): español e inglés.
- Espera (spec, módulo 2 y SC-009): la app espera 60 s. El backend corta la llamada al
  proveedor a los 45 s para alcanzar a responder un error claro (research.md, R10).
- La clave del proveedor y la conexión a la base llegan por variables de entorno y nunca
  se escriben en el código (constitución §2: los secretos permanecen en el backend y se
  suministran por configuración externa).
- Cuentas (spec 002): duración de la sesión, bloqueo por intentos fallidos y límites de
  los datos de la cuenta.
"""

from __future__ import annotations

import os
from dataclasses import dataclass
from datetime import timedelta

# --- Límites de imagen acordados en el spec (módulo 1) -------------------------------
MAX_IMAGE_BYTES = 10 * 1024 * 1024  # 10 MB
MIN_IMAGE_SIDE_PX = 600
MAX_IMAGE_SIDE_PX = 10_000

# Lado mayor de la copia que se envía al OCR (research.md, R3). Una imagen de 10 MB en
# base64 superaría el límite de 10 MB por solicitud de Google Cloud Vision.
OCR_IMAGE_MAX_SIDE_PX = 3_000
OCR_IMAGE_JPEG_QUALITY = 90

# --- Reconocimiento (spec, módulo 2) -------------------------------------------------
OCR_LANGUAGE_HINTS = ("es", "en")  # español e inglés (Clarifications 2026-10-26)
OCR_TIMEOUT_SECONDS = 45.0  # menor que los 60 s que espera la app (research.md, R10)

# Spec 003, módulo 1 (supuesto 1): una palabra es «dudosa» si el proveedor la leyó con
# una seguridad menor al 80 %.
UNCERTAIN_WORD_CONFIDENCE = 0.80

# --- Exportación: protección del servicio (research.md, R14) -------------------------
MAX_EXPORT_TEXT_CHARS = 200_000
MAX_EXPORT_BODY_BYTES = 3 * 1024 * 1024  # 3 MB de JSON

# --- Cuentas de usuario (spec 002; research.md de 002; tarea T104) ---------------
SESSION_DURATION = timedelta(days=30)  # supuesto 2 de la spec 002
MAX_FAILED_LOGINS = 5  # supuesto 3: tras 5 fallos seguidos...
LOGIN_LOCK_DURATION = timedelta(minutes=15)  # ...se bloquea 15 minutos
PASSWORD_MIN_CHARS = 8  # supuesto 4: longitud, no símbolos
PASSWORD_MAX_CHARS = 128
DISPLAY_NAME_MAX_CHARS = 60
EMAIL_MAX_CHARS = 254
MAX_AUTH_BODY_BYTES = 16 * 1024  # 16 KB: los formularios de cuenta son pequeños

# Nombres de las variables de entorno con los secretos de la API.
GOOGLE_VISION_API_KEY_ENV = "HANDTEXT_GOOGLE_VISION_API_KEY"
DATABASE_URL_ENV = "HANDTEXT_DATABASE_URL"


@dataclass(frozen=True)
class Settings:
    """Valores que dependen del entorno donde corre la API (no del código)."""

    # Clave de Google Cloud Vision. Si falta, el reconocimiento responde 503
    # OCR_NOT_CONFIGURED en lugar de fallar de forma confusa.
    google_vision_api_key: str | None
    # Conexión a PostgreSQL, por ejemplo
    # postgresql://handtext:clave@localhost:5432/handtext. Si falta, las cuentas
    # responden 503 ACCOUNTS_UNAVAILABLE.
    database_url: str | None = None

    @classmethod
    def from_environment(cls) -> Settings:
        """Lee la configuración desde las variables de entorno del proceso."""
        key = os.environ.get(GOOGLE_VISION_API_KEY_ENV, "").strip()
        database_url = os.environ.get(DATABASE_URL_ENV, "").strip()
        return cls(google_vision_api_key=key or None, database_url=database_url or None)
