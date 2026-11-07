-- Migración 0001: cuentas de usuario y sesiones (spec 002; data-model.md; tarea T103).
-- Se aplica con:  python -m app.persistence.migrations   (desde la carpeta backend)
--
-- Reglas de privacidad (spec 002, módulo 3; SC-201):
-- - users.password_hash guarda solo el hash Argon2id, nunca la contraseña.
-- - sessions.token_hash guarda solo el SHA-256 del token, nunca el token.
-- - Al borrar un usuario se borran sus sesiones (ON DELETE CASCADE; SC-205).

CREATE TABLE users (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    email TEXT NOT NULL UNIQUE CHECK (char_length(email) BETWEEN 3 AND 254),
    display_name TEXT NOT NULL CHECK (char_length(display_name) BETWEEN 1 AND 60),
    password_hash TEXT NOT NULL,
    data_policy_accepted_at TIMESTAMPTZ NOT NULL,
    failed_login_attempts INTEGER NOT NULL DEFAULT 0 CHECK (failed_login_attempts >= 0),
    locked_until TIMESTAMPTZ,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE sessions (
    token_hash TEXT PRIMARY KEY,
    user_id UUID NOT NULL REFERENCES users (id) ON DELETE CASCADE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    expires_at TIMESTAMPTZ NOT NULL
);

CREATE INDEX sessions_user_id_idx ON sessions (user_id);
