---

description: "Tareas de la funcionalidad 011: bloqueo con huella o rostro"
---

# Tasks: Bloqueo con huella o rostro

**Input**: [plan.md](plan.md), [spec.md](spec.md), [research.md](research.md)

**Tests**: incluidas (constitución §6). Los identificadores siguen desde T1001.

## Phase 1: Base

- [X] T1001 Dependencia local_auth 3.0.1; MainActivity como FlutterFragmentActivity; DeviceAuthenticator en frontend/lib/services/device_authenticator.dart y uno falso en frontend/test/support/fakes.dart

## Phase 2: User Story 1 - Activar (Priority: P1) 🎯

- [X] T1002 [P] [US1] Pruebas del ajuste appLock (por omisión, guardar, JSON anterior) y de la pantalla de Ajustes (activar con verificación, cancelar, teléfono sin verificación)
- [X] T1003 [US1] appLock en AppSettings, almacén y controlador; interruptor en frontend/lib/presentation/screens/settings_screen.dart

## Phase 3: User Story 2 - Abrir bloqueada (Priority: P2)

- [X] T1004 [P] [US2] Pruebas: bloqueada al abrir, desbloquear conserva el estado, cancelar sigue bloqueada, más y menos de 1 minuto en segundo plano, sin sesión no se bloquea, en frontend/test/presentation/app_lock_test.dart
- [X] T1005 [US2] AppLockController (R3) en frontend/lib/state/app_lock_controller.dart, pantalla frontend/lib/presentation/screens/lock_screen.dart y AppLockGate en frontend/lib/app.dart (R4); textos en español e inglés

## Phase 4: User Story 3 - Desactivar (Priority: P3)

- [X] T1006 [US3] Prueba: al desactivarlo, la app deja de bloquearse

## Phase 5: Polish

- [X] T1007 Privacidad, accesibilidad (006) e inglés (008) de la pantalla de bloqueo; quickstart.md, README.md y MAPA_DEL_CODIGO.md
- [ ] T1008 Formateador, analizador, todas las pruebas y recorrido en el emulador con PIN y huella simulada; registro de verificación al final de este archivo (parcial: falta el recorrido en un teléfono; ver el registro)

## Dependencies & Execution Order

Base → US1 → US2 → US3 → Polish.

## Registro de verificación (T1007 y T1008, 2026-11-06)

Constitución §6, Entrega: verificaciones ejecutadas, resultados y limitaciones.

| Verificación | Comando o entorno | Resultado |
|--------------|-------------------|-----------|
| Formato y analizador de la app | `dart format` y `flutter analyze` (incluye `integration_test`) | Sin problemas |
| Pruebas del backend | `pytest` y `ruff` | 155 superadas; sin problemas (009 a 012 no cambian la API) |
| Pruebas de la app | `flutter test` | 337 superadas en total, 9 omitidas (contrato). De 011: 12 en `app_lock_test.dart`, una de ellas con las guías de 006 y en inglés (008), al 100 % y 200 % |
| Versión final | `flutter build apk --release` | Compila con `FlutterFragmentActivity` y los temas AppCompat (R1). `aapt2` muestra los permisos `USE_BIOMETRIC` y `USE_FINGERPRINT` |
| Emulador (Android 16) | Versión final | Incompleto (ver limitaciones) |

**Cambios hechos en esta verificación**:
- **Prueba nueva**: con Mis documentos abierto, la app se bloquea al volver después de
  más de 1 minuto. El documento queda tapado y, al desbloquear, sigue ahí [SC-1101]
  [SC-1103]. Comprueba la decisión R4: el bloqueo va encima de todas las pantallas.
- **Orden real de Android**: las pruebas pasaban de «paused» a «resumed» directamente, y
  un componente de Flutter de Mis documentos rechazó ese salto. Ahora siguen el orden del
  teléfono: inactive → hidden → paused y, al volver, hidden → inactive → resumed.
- **La prueba detecta lo que debe** (comprobado a propósito): si al volver «hidden»
  reiniciara la cuenta (`=` en lugar de `??=` en `didChangeAppLifecycleState`), el
  bloqueo nunca llegaría en un teléfono. Con ese cambio fallan las 2 pruebas del minuto.
  Se dejó el código original.
- **Documentos corregidos**: el plan y R4 decían que el bloqueo iba en la zona con sesión
  (`app_root.dart`). El código lo pone en `MaterialApp.builder` (`app.dart`); R4 ahora lo
  explica, con la alternativa descartada.

**Limitaciones**:
- En el emulador se configuró el PIN (`locksettings set-pin 1234`) y se desbloqueó la
  pantalla de Android, pero el recorrido de la app no se terminó.
- El emulador dejó de responder (errores «no responde» del sistema y de los servicios de
  Google) por falta de memoria en el computador, y se cerró.
- **No se vio en un teléfono**: el cuadro de Android que pide la huella o el PIN sobre la
  app, ni el bloqueo después de 1 minuto. Las pruebas lo cubren con un verificador falso.
- Falta probarlo en un teléfono con huella ([quickstart.md](quickstart.md), §2).
- Los supuestos 1 a 3 siguen pendientes de validación (CHK1108).
