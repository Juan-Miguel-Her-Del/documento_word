"""Ejecutor de migraciones SQL (tarea T108; research.md de 002, R4).

Aplica en orden los archivos db/migrations/NNNN_nombre.sql que todavía no se aplicaron y
los anota en la tabla schema_migrations. Volver a ejecutarlo no repite nada.

Uso (desde la carpeta backend, con HANDTEXT_DATABASE_URL definida):
    python -m app.persistence.migrations
"""

from __future__ import annotations

import sys
from pathlib import Path

import psycopg

from app.config import Settings

# documento_word/db/migrations (constitución §4: esquemas y migraciones en /db).
MIGRATIONS_DIR = Path(__file__).resolve().parents[3] / "db" / "migrations"


def apply_migrations(conninfo: str, directory: Path = MIGRATIONS_DIR) -> list[str]:
    """Aplica las migraciones pendientes y devuelve sus nombres."""
    applied: list[str] = []
    # Todo ocurre en una transacción: si algo falla, no queda nada a medias.
    with psycopg.connect(conninfo) as connection:
        connection.execute(
            "CREATE TABLE IF NOT EXISTS schema_migrations ("
            "version TEXT PRIMARY KEY, applied_at TIMESTAMPTZ NOT NULL DEFAULT now())"
        )
        done = {row[0] for row in connection.execute("SELECT version FROM schema_migrations")}
        for path in sorted(directory.glob("*.sql")):
            if path.stem in done:
                continue
            connection.execute(path.read_text(encoding="utf-8"))
            connection.execute("INSERT INTO schema_migrations (version) VALUES (%s)", (path.stem,))
            applied.append(path.stem)
    return applied


def main() -> int:
    settings = Settings.from_environment()
    if settings.database_url is None:
        print("Defina HANDTEXT_DATABASE_URL antes de aplicar las migraciones.")
        return 1
    applied = apply_migrations(settings.database_url)
    print(f"Migraciones aplicadas: {', '.join(applied) if applied else 'ninguna pendiente'}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
