---

description: "Tareas de la funcionalidad 002: cuentas de usuario e identidad visual Aurora"
---

# Tasks: Cuentas de usuario e identidad visual Aurora

**Input**: [plan.md](plan.md), [spec.md](spec.md), [research.md](research.md),
[data-model.md](data-model.md), [contracts/auth-api.md](contracts/auth-api.md)

**Tests**: incluidas, porque la constitución §6 exige pruebas de persistencia y permisos.
Los identificadores siguen desde T101 para no confundirse con los de 001.

## Phase 1: Setup

- [X] T101 Dependencias del backend (psycopg, psycopg-pool y argon2-cffi; pgserver solo en desarrollo) en backend/requirements.txt y backend/requirements-dev.txt
- [X] T102 [P] flutter_secure_storage y la tipografía Poppins en frontend/pubspec.yaml y frontend/assets/fonts/
- [X] T103 [P] Esquema SQL en db/migrations/0001_users_and_sessions.sql y preparación local en db/setup_local_database.sql

## Phase 2: Foundational

- [X] T104 Configuración de la base, la duración de la sesión, el bloqueo y los límites en backend/app/config.py
- [X] T105 Códigos de error de cuentas en backend/app/errors.py
- [X] T106 Contrato del almacén de usuarios en backend/app/persistence/user_store.py
- [X] T107 Almacén PostgreSQL con consultas parametrizadas en backend/app/persistence/postgres_store.py
- [X] T108 Ejecutor de migraciones en backend/app/persistence/migrations.py
- [X] T109 [P] Pruebas de contrato del almacén (memoria y PostgreSQL) en backend/tests/test_user_store.py, con backend/tests/memory_store.py y backend/tests/conftest.py
- [X] T110 [P] Colores, degradados y temas Aurora en frontend/lib/theme/aurora.dart y frontend/lib/theme/app_theme.dart
- [X] T111 [P] Widgets base Aurora en frontend/lib/presentation/widgets/ (aurora_background.dart, glass_card.dart, scanner_logo.dart, gradient_button.dart y motion.dart)

## Phase 3: User Story 1 - Crear una cuenta e ingresar (Priority: P1) 🎯

- [X] T112 [P] [US1] Pruebas del servicio de cuentas en backend/tests/test_account_service.py
- [X] T113 [P] [US1] Pruebas de la API de cuentas y de las rutas protegidas en backend/tests/test_auth_api.py
- [X] T114 [US1] Contraseñas Argon2id y tokens en backend/app/services/accounts/passwords.py y backend/app/services/accounts/tokens.py
- [X] T115 [US1] Reglas de nombre, correo y contraseña en backend/app/services/accounts/rules.py
- [X] T116 [US1] Servicio de cuentas (registro, ingreso, bloqueo y sesiones) en backend/app/services/accounts/account_service.py
- [X] T117 [US1] Rutas /auth y dependencia require_user en backend/app/api/auth.py, con esquemas en backend/app/schemas.py y conexión en backend/app/main.py
- [X] T118 [US1] Protección de reconocimiento y exportación en backend/app/api/recognitions.py y backend/app/api/exports.py
- [X] T119 [P] [US1] Pruebas de la app en frontend/test/services/auth_api_client_test.dart, frontend/test/services/account_rules_test.dart y frontend/test/state/auth_controller_test.dart
- [X] T120 [P] [US1] Modelo de usuario y nuevos fallos en frontend/lib/models/user_account.dart y frontend/lib/models/app_failure.dart
- [X] T121 [P] [US1] Errores de API compartidos en frontend/lib/services/api_errors.dart y token en frontend/lib/services/handtext_api_client.dart
- [X] T122 [P] [US1] Cliente de cuentas en frontend/lib/services/auth_api_client.dart
- [X] T123 [P] [US1] Sesión en el almacenamiento seguro en frontend/lib/services/session_store.dart
- [X] T124 [P] [US1] Reglas de formulario en frontend/lib/services/account_rules.dart
- [X] T125 [US1] Controlador de sesión en frontend/lib/state/auth_controller.dart
- [X] T126 [US1] Pantallas de presentación, bienvenida, ingreso y registro en frontend/lib/presentation/screens/auth/
- [X] T127 [US1] Raíz de la app y conexión de dependencias en frontend/lib/presentation/screens/app_root.dart, frontend/lib/app.dart y frontend/lib/main.dart
- [X] T128 [US1] Pruebas de pantallas de cuentas en frontend/test/presentation/auth_screens_test.dart

## Phase 4: User Story 2 - Cerrar sesión y eliminar la cuenta (Priority: P2)

- [X] T129 [P] [US2] Pruebas de cierre, eliminación y sesión vencida en backend/tests/test_auth_api.py, frontend/test/state/auth_controller_test.dart y frontend/test/presentation/auth_screens_test.dart
- [X] T130 [US2] Menú de cuenta y diálogo de eliminación en frontend/lib/presentation/widgets/account_menu.dart
- [X] T131 [US2] Borrador por usuario, limpieza local y aviso de sesión vencida en frontend/lib/services/draft_storage.dart y frontend/lib/state/document_flow_controller.dart

## Phase 5: User Story 3 - Experiencia visual Aurora (Priority: P3)

- [X] T132 [US3] Rediseño de inicio, vista previa, editor y transiciones en frontend/lib/presentation/screens/
- [X] T133 [US3] Rediseño de avisos, diálogos y selector de formato en frontend/lib/presentation/widgets/
- [X] T134 [US3] Animación de escaneo sobre la imagen en frontend/lib/presentation/widgets/scan_overlay.dart
- [X] T135 [P] [US3] Pruebas de pantallas con animaciones reducidas en frontend/test/presentation/flow_screen_test.dart

## Phase 6: Polish

- [X] T136 Guía de ejecución en specs/002-cuentas-de-usuario/quickstart.md, README.md y MAPA_DEL_CODIGO.md
- [X] T137 Formateadores, analizadores y todas las pruebas; registro de verificación al final de este archivo
- [X] T138 APK y recorrido en el emulador con la API y PostgreSQL

## Phase 7: Paleta «azul corporativo» (Clarifications 2026-10-28; research.md, R9)

- [X] T139 [US3] Prueba de contraste de la paleta [SC-208] en frontend/test/theme/aurora_contrast_test.dart
- [X] T140 [US3] Nueva paleta y medidas en frontend/lib/theme/aurora.dart y temas en frontend/lib/theme/app_theme.dart
- [X] T141 [US3] Fondo fijo, tarjeta sólida (surface_card.dart), botón principal (primary_button.dart) y título de marca (brand_title.dart) en frontend/lib/presentation/widgets/; se eliminan glass_card.dart, gradient_button.dart y gradient_text.dart
- [X] T142 [US3] Logo-escáner, animación de escaneo, avisos, menú de cuenta, diálogo de autorización y campo de contraseña con la nueva paleta en frontend/lib/presentation/widgets/
- [X] T143 [US3] Pantallas con la nueva paleta en frontend/lib/presentation/screens/
- [X] T144 [P] [US3] Pantalla de arranque de Android en azul marino en frontend/android/app/src/main/res/
- [X] T145 Documentación (README.md y MAPA_DEL_CODIGO.md), formateadores, analizador, pruebas, APK y revisión en el emulador

## Phase 8: Ícono propio (Clarifications 2026-10-29)

- [X] T146 [US3] Ícono adaptable y monocromático con el logo-escáner: generador en frontend/tool/generate_launcher_icon.py, imágenes en frontend/android/app/src/main/res/mipmap-*/ y fondo en values/colors.xml

Verificado el 2026-10-29: el cajón de apps del emulador muestra «HandText AI» con el logo
azul en lugar del de Flutter. La pantalla de arranque de Android 12+ usa ese mismo ícono.

## Dependencies & Execution Order

Setup → Foundational → US1 → US2 → US3 → Polish → Paleta → Ícono. US2 depende de la sesión de
US1. US3 solo cambia la presentación y puede avanzar en paralelo con las pruebas de US2.
La fase 7 solo cambia la presentación: no toca la API ni las reglas del flujo.

## Registro de verificación (T137 y T138, 2026-10-28)

Constitución §6, Entrega: verificaciones ejecutadas, resultados y limitaciones.

| Verificación | Comando | Resultado |
|--------------|---------|-----------|
| Estilo del backend | `ruff format --check .` y `ruff check .` | Sin problemas |
| Pruebas del backend | `pytest` (incluye PostgreSQL 16 real con pgserver) | 128 superadas |
| Formato de la app | `dart format --set-exit-if-changed lib test` | Sin cambios |
| Analizador de la app | `flutter analyze` | Sin problemas |
| Pruebas de la app | `flutter test` | 114 superadas; 9 omitidas (las de contrato, que requieren `HANDTEXT_API_URL`) |
| Contrato app ↔ API real | `flutter test test/integration` con Uvicorn y PostgreSQL | 9 superadas; la cuenta temporal se crea y se elimina |
| Compilación Android | `flutter build apk --debug` | `app-debug.apk` generado con la versión final |
| Prueba en emulador (Android 16, API 36) | APK instalado y recorrido con `adb`, API con PostgreSQL | Ver detalle abajo |

**Recorrido en el emulador**:
- La app abre con la presentación Aurora y la bienvenida.
- El registro crea la cuenta e ingresa directamente al inicio ([CU-H1-E1]).
- La vista previa y el diálogo de autorización se ven con el estilo Aurora.
- El reconocimiento se envía con la sesión. Sin clave de Google, la API responde 503 y la app lo explica; no aparece «sesión vencida».
- El borrador se guarda en un archivo propio del usuario y se recupera tras cerrar la app.
- La exportación a PDF guarda un archivo con exactamente el texto corregido y después borra el borrador.
- «Eliminar cuenta» con la contraseña vuelve a la bienvenida, y en la base quedan 0 usuarios y 0 sesiones ([CU-H2-E3]).

**Incidencias resueltas durante la verificación**:
- *Desbordamiento en ingreso y registro*: la fila «¿No tiene cuenta? Crear cuenta» se
  salía del ancho en pantallas estrechas; las pruebas de pantallas lo detectaron. Ahora
  usa `Wrap`.
- *Compilación Android*: un fallo de red al resolver `repo.maven.apache.org` impidió una
  compilación; al repetirla funcionó, sin cambios en el código.
- *Ajuste visual*: los botones de los diálogos se apilan centrados cuando no caben en una
  fila, y el encabezado del menú de cuenta ya no se ve en gris de «desactivado».

**Limitaciones**:
- El recorrido en el emulador se hizo antes del último ajuste visual de los diálogos. Las
  pruebas automáticas y el APK sí corresponden a la versión final.
- No se probó contra Google Cloud Vision real porque no hay una clave configurada en este
  equipo. SC-010 de 001 sigue pendiente.
- Las pruebas usaron el PostgreSQL 16 temporal de pgserver, no el PostgreSQL 17 instalado
  en el equipo, porque su contraseña no se pidió. El esquema solo usa funciones
  disponibles en ambas versiones.
- Quedan para la validación manual: la cámara real, la sobrescritura en el diálogo de
  guardado y el modo oscuro en un teléfono.
- Siguen pendientes CHK208 (validar los supuestos con el responsable del proyecto) y
  CHK209 (aprobación del cambio de alcance).

## Registro de verificación de la fase 7 (T139 a T145, 2026-10-28)

| Verificación | Comando | Resultado |
|--------------|---------|-----------|
| Formato y analizador de la app | `dart format` y `flutter analyze` | Sin problemas |
| Pruebas de la app | `flutter test` | 137 superadas (incluidas las nuevas de contraste [SC-208]); 9 omitidas (contrato) |
| Pruebas del backend | `pytest` | 128 superadas (la fase no cambia el backend) |
| Compilación Android | `flutter build apk --debug` | `app-debug.apk` generado |
| Revisión en el emulador (Android 16) | APK instalado, API con PostgreSQL temporal | Ver detalle abajo |

**Revisión en el emulador**:
- Pantallas revisadas: bienvenida, registro, inicio, vista previa, autorización, aviso
  de servicio no disponible, editor (modo claro y oscuro), hoja de exportación y menú de
  cuenta.
- Se ven el fondo azul marino, los botones azul sólido, las tarjetas con borde fino y
  el logo como ícono azul. No queda rosa, violeta ni luces de colores.

**Incidencias resueltas**:
- *Insignia del diálogo de autorización estirada*: el diálogo forzaba todo el ancho a la
  insignia del ícono. Ahora va dentro de `Center`.
- *Tinte lila en el modo claro*: Material agregaba lila a los diálogos y hojas. Los temas
  claro y oscuro ahora fijan fondos neutros: gris pizarra y azul marino.

**Limitaciones**:
- El destello inicial de Android en azul marino no se capturó en imagen (dura menos de
  un segundo).
