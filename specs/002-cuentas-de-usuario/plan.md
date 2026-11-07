# Implementation Plan: Cuentas de usuario e identidad visual Aurora

**Branch**: `01-constitucion` | **Date**: 2026-10-27 | **Spec**: [spec.md](spec.md)

**Input**: Feature specification from `/specs/002-cuentas-de-usuario/spec.md`

## Summary

La API incorpora cuentas de correo y contraseña guardadas en PostgreSQL:
- contraseñas cifradas con Argon2id;
- sesiones con tokens opacos, de los que la base solo guarda el hash SHA-256;
- bloqueo tras intentos fallidos;
- autenticación obligatoria para reconocer y exportar.

La app añade bienvenida, registro, ingreso, cierre de sesión y eliminación de la cuenta.
Guarda la sesión en el almacenamiento seguro de Android y aplica a todas las pantallas el
estilo «Aurora». Las decisiones técnicas están en [research.md](research.md).

## Technical Context

**Language/Version**: las mismas de 001 (Dart 3.9.2 con Flutter 3.35.4; Python 3.12) y
SQL de PostgreSQL.

**Primary Dependencies**:
- *API*: psycopg 3.3 (`psycopg[binary]`), psycopg-pool 3.3 y argon2-cffi 25.1.
- *Pruebas*: pgserver 0.1.4, un PostgreSQL embebido.
- *App*: flutter_secure_storage 10.3.4 y la tipografía Poppins (OFL).

**Storage**:
- *Servidor*: PostgreSQL 17 (el instalado en el equipo de desarrollo) con las tablas
  `users` y `sessions`. Las migraciones SQL viven en `db/migrations/` (constitución §4).
- *Pruebas*: PostgreSQL 16 embebido con pgserver.
- *Teléfono*: la sesión en el almacenamiento seguro y un borrador por usuario.

**Testing**: pytest (contrato del almacén contra memoria y contra PostgreSQL real) y
flutter_test.

**Target Platform**: Android con minSdk 24 (flutter_secure_storage exige 23 o más).

**Project Type**: mobile-app + API REST + base de datos.

**Performance Goals**: un registro o un ingreso responde en menos de 1 s en el entorno
local. Argon2id tarda unos 100 ms por verificación.

**Constraints**:
- La sesión dura 30 días.
- Bloqueo de 15 minutos tras 5 fallos.
- Contraseñas de 8 a 128 caracteres.
- Cuerpos de autenticación de hasta 16 KB.
- Ninguna contraseña ni token en registros o en texto plano.

**Scale/Scope**: 5 endpoints nuevos, 2 tablas y 4 pantallas nuevas (presentación, bienvenida,
ingreso y registro), más el rediseño de las existentes.

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

| Regla | Cómo se cumple | Estado |
|-------|----------------|--------|
| §1 Autenticación solo con especificación aprobada | Spec 002 con Clarifications; 001 actualizado | ⚠️ falta la aprobación del responsable (CHK208, CHK209) |
| §2 PostgreSQL para usuarios | Tablas `users` y `sessions`; consultas parametrizadas en `app/persistence/` | ✅ |
| §2 Dependencias registradas | `requirements*.txt` y `pubspec.lock` | ✅ |
| §3 Acceso | La API exige `Authorization: Bearer` en cada solicitud protegida | ✅ |
| §3 Privacidad | Argon2id, hash de tokens, registros sin correo ni credenciales, almacenamiento seguro y autorización de datos | ✅ |
| §3 Retención | Eliminar la cuenta borra usuario, sesiones (en cascada) y borrador local | ✅ |
| §4 Estructura | `db/` con migraciones SQL, `backend/app/persistence/` y `services/accounts/` | ✅ |
| §5 Errores | 401, 409, 400 y 503 según la constitución; 429 para el bloqueo (estándar HTTP; la constitución no lo prohíbe) | ✅ justificado |
| §5 Sin eco de datos | Los cuerpos de autenticación se validan a mano: un 422 nunca repite la contraseña | ✅ |
| §6 Pruebas de persistencia y permisos | Contrato del almacén contra PostgreSQL real, servicio, API y pantallas | ✅ |

**Revisión posterior al diseño**: sin violaciones nuevas.

## Project Structure

```text
db/
├── migrations/0001_users_and_sessions.sql   # Esquema (SQL)
└── setup_local_database.sql                 # Crea el rol y la base en PostgreSQL local

backend/app/
├── persistence/          # user_store.py (contrato), postgres_store.py, migrations.py
├── services/accounts/    # passwords.py, tokens.py, rules.py, account_service.py
└── api/auth.py           # /auth/register, /auth/login, /auth/logout, /auth/me, /account

frontend/lib/
├── models/user_account.dart
├── services/             # auth_api_client.dart, api_errors.dart, session_store.dart, account_rules.dart
├── state/auth_controller.dart
├── theme/aurora.dart     # Colores y medidas del estilo Aurora (paleta azul corporativo)
└── presentation/
    ├── screens/          # app_root.dart, auth/ (bienvenida, ingreso y registro) y rediseño de las existentes
    └── widgets/          # fondo aurora, tarjeta, logo escáner, botón principal, título de marca, menú de cuenta…
```

**Structure Decision**: se crea `db/` porque ahora existe persistencia aprobada
(constitución §4).

## Complexity Tracking

| Elemento | Por qué se necesita | Alternativa más simple descartada |
|----------|---------------------|-----------------------------------|
| pgserver (solo en desarrollo) | Probar la persistencia contra un PostgreSQL real sin la contraseña del PostgreSQL instalado | Un almacén en memoria no detecta errores de SQL ni de restricciones |
