"""Tokens de sesión (tarea T114; research.md de 002, R2).

- El token es aleatorio (256 bits) y la app lo recibe una sola vez.
- La base guarda solo su SHA-256: si se filtrara, no serviría para entrar (SC-201).
"""

from __future__ import annotations

import hashlib
import secrets


def new_session_token() -> str:
    """Token impredecible, seguro para usar en una cabecera HTTP."""
    return secrets.token_urlsafe(32)


def hash_session_token(token: str) -> str:
    """Huella SHA-256 del token: es lo único que se guarda en sessions.token_hash."""
    return hashlib.sha256(token.encode("utf-8")).hexdigest()
