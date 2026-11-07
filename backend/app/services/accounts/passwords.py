"""Cifrado y verificación de contraseñas con Argon2id (tarea T114; research.md de 002, R1).

- La base guarda solo el hash (que ya incluye la sal y los parámetros), nunca la
  contraseña (spec 002, módulo 3; SC-201).
- Si el correo no existe, se verifica igual contra un hash ficticio: así la respuesta
  tarda lo mismo y no revela qué correos están registrados (SC-203).
"""

from __future__ import annotations

from argon2 import PasswordHasher
from argon2.exceptions import InvalidHashError, VerificationError, VerifyMismatchError


class PasswordService:
    """Envoltorio de argon2-cffi. Las pruebas pasan un PasswordHasher más rápido."""

    def __init__(self, hasher: PasswordHasher | None = None) -> None:
        # Parámetros predeterminados de argon2-cffi (Argon2id, perfil de RFC 9106).
        self._hasher = hasher or PasswordHasher()
        self._dummy_hash = self._hasher.hash("contraseña-ficticia-para-igualar-tiempos")

    def hash(self, password: str) -> str:
        return self._hasher.hash(password)

    def verify(self, password_hash: str, password: str) -> bool:
        """True solo si la contraseña corresponde al hash."""
        try:
            return self._hasher.verify(password_hash, password)
        except (VerifyMismatchError, VerificationError, InvalidHashError):
            return False

    def verify_dummy(self, password: str) -> None:
        """Gasta el mismo tiempo que una verificación real (correo inexistente)."""
        self.verify(self._dummy_hash, password)
