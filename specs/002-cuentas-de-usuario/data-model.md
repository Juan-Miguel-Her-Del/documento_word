# Data Model: Cuentas de usuario

**Fecha**: 2026-10-27 | **Esquema**: [db/migrations/0001_users_and_sessions.sql](../../db/migrations/0001_users_and_sessions.sql)

## Tabla `users`

| Columna | Tipo | Regla |
|---------|------|-------|
| `id` | `UUID` | Clave primaria, `gen_random_uuid()`; no es adivinable |
| `email` | `TEXT` | Único; se guarda normalizado (sin espacios y en minúsculas); máximo 254 |
| `display_name` | `TEXT` | 1 a 60 caracteres |
| `password_hash` | `TEXT` | Hash Argon2id (nunca la contraseña) |
| `data_policy_accepted_at` | `TIMESTAMPTZ` | Momento en que se autorizó el tratamiento de datos |
| `failed_login_attempts` | `INTEGER` | Fallos seguidos (0 a 4) |
| `locked_until` | `TIMESTAMPTZ` | Bloqueo vigente, o `NULL` |
| `created_at` | `TIMESTAMPTZ` | Fecha de creación |

## Tabla `sessions`

| Columna | Tipo | Regla |
|---------|------|-------|
| `token_hash` | `TEXT` | Clave primaria: SHA-256 del token (nunca el token) |
| `user_id` | `UUID` | Referencia a `users`; `ON DELETE CASCADE` |
| `created_at` | `TIMESTAMPTZ` | Inicio de la sesión |
| `expires_at` | `TIMESTAMPTZ` | Inicio + 30 días; vencida no autentica |

## En el teléfono

| Dato | Dónde | Retención |
|------|-------|-----------|
| Token y datos visibles (id, nombre y correo) | Almacenamiento seguro (Android Keystore) | Hasta cerrar sesión, eliminar la cuenta o recibir 401 |
| Borrador | `draft_<id>.txt` en el almacenamiento privado | Como en 001; además se borra al cerrar sesión (confirmado) o al eliminar la cuenta |

## Estados de la sesión en la app

```text
[Comprobando] ──sin sesión guardada──▶ [Sin sesión] ──registro o ingreso──▶ [Con sesión]
      │                                     ▲                                    │
      └──sesión guardada (válida o sin red)─┼────────────────────────────────────┤
                                            └── cerrar sesión · eliminar cuenta · 401 ┘
```
