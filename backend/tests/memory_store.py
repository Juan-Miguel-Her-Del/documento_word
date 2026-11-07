"""Almacén de usuarios en memoria para las pruebas (tarea T109).

Cumple el mismo contrato que PostgresUserStore; test_user_store.py ejecuta las mismas
pruebas contra ambos para garantizar que se comportan igual.
"""

from __future__ import annotations

import uuid
from datetime import datetime, timedelta

from app.persistence.user_store import EmailAlreadyRegisteredError, UserRecord


class InMemoryUserStore:
    def __init__(self) -> None:
        self.users: dict[str, dict] = {}  # id -> fila de users
        self.sessions: dict[str, tuple[str, datetime]] = {}  # token_hash -> (user_id, vence)

    def _record(self, row: dict) -> UserRecord:
        return UserRecord(
            id=row["id"],
            email=row["email"],
            display_name=row["display_name"],
            password_hash=row["password_hash"],
            failed_login_attempts=row["failed_login_attempts"],
            locked_until=row["locked_until"],
        )

    def create_user(
        self, *, email: str, display_name: str, password_hash: str, accepted_at: datetime
    ) -> UserRecord:
        if any(row["email"] == email for row in self.users.values()):
            raise EmailAlreadyRegisteredError
        user_id = str(uuid.uuid4())
        self.users[user_id] = {
            "id": user_id,
            "email": email,
            "display_name": display_name,
            "password_hash": password_hash,
            "data_policy_accepted_at": accepted_at,
            "failed_login_attempts": 0,
            "locked_until": None,
        }
        return self._record(self.users[user_id])

    def find_user_by_email(self, email: str) -> UserRecord | None:
        for row in self.users.values():
            if row["email"] == email:
                return self._record(row)
        return None

    def register_failed_login(
        self, user_id: str, *, now: datetime, max_attempts: int, lock_duration: timedelta
    ) -> None:
        row = self.users.get(user_id)
        if row is None:
            return
        if row["failed_login_attempts"] + 1 >= max_attempts:
            row["failed_login_attempts"] = 0
            row["locked_until"] = now + lock_duration
        else:
            row["failed_login_attempts"] += 1

    def reset_failed_logins(self, user_id: str) -> None:
        row = self.users.get(user_id)
        if row is not None:
            row["failed_login_attempts"] = 0
            row["locked_until"] = None

    def create_session(self, *, token_hash: str, user_id: str, expires_at: datetime) -> None:
        self.sessions[token_hash] = (user_id, expires_at)

    def find_user_by_session(self, token_hash: str, *, now: datetime) -> UserRecord | None:
        entry = self.sessions.get(token_hash)
        if entry is None or entry[1] <= now or entry[0] not in self.users:
            return None
        return self._record(self.users[entry[0]])

    def delete_session(self, token_hash: str) -> None:
        self.sessions.pop(token_hash, None)

    def delete_user(self, user_id: str) -> None:
        self.users.pop(user_id, None)
        self.sessions = {k: v for k, v in self.sessions.items() if v[0] != user_id}
