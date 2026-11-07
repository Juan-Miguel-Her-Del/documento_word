# Implementation Plan: Bloqueo con huella o rostro

**Branch**: `01-constitucion` | **Date**: 2026-11-05 | **Spec**: [spec.md](spec.md)

**Input**: Feature specification from `/specs/011-bloqueo-con-huella/spec.md`

## Summary

Un ajuste nuevo activa el bloqueo, y Android verifica a la persona con
`BiometricPrompt`:
- con sesión, la app se bloquea al abrirse y al volver después de más de 1 minuto;
- la pantalla de bloqueo reemplaza al flujo de documentos sin destruirlo.

La API no cambia. Las decisiones están en [research.md](research.md).

## Technical Context

**Language/Version**: Dart 3.9.2 con Flutter 3.35.4; Kotlin para `MainActivity`.

**Primary Dependencies**: `local_auth` 3.0.1 (nueva; R1).

**Storage**: un campo nuevo, `appLock`, en `settings.json` (R2).

**Testing**: flutter_test con un verificador falso y la hora inyectada; emulador con PIN y
huella simulada.

**Target Platform**: Android, minSdk 24.

**Project Type**: mobile-app.

**Performance Goals**: no aplica.

**Constraints**:
- Apagado por omisión.
- La huella nunca llega a la app.

**Scale/Scope**:
- Un servicio, un controlador y una pantalla.
- Cambios en los ajustes, la zona con sesión y `MainActivity`.

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

| Regla | Cómo se cumple | Estado |
|-------|----------------|--------|
| §2 Dependencias | `local_auth` registrada en `pubspec.yaml` y `pubspec.lock`, con la necesidad en R1 | ✅ |
| §3 Privacidad | La huella la verifica Android; la app no la recibe; nada se envía | ✅ |
| §3 Acceso | Bloqueada, no se ve ningún documento (R4) | ✅ |
| §5 Mensajes | Explica cuando el teléfono no tiene cómo verificar | ✅ |
| §6 Pruebas | Ajuste, controlador del bloqueo y pantallas con un verificador falso | ✅ |

**Revisión posterior al diseño**: sin violaciones.

## Project Structure

```text
frontend/
├── android/app/src/main/kotlin/…/MainActivity.kt   # FlutterFragmentActivity (R1)
├── lib/
│   ├── models/app_settings.dart                    # + appLock
│   ├── services/settings_store.dart                # + appLock en el JSON
│   ├── services/device_authenticator.dart          # NUEVO: local_auth (R1)
│   ├── state/settings_controller.dart              # + setAppLock
│   ├── state/app_lock_controller.dart              # NUEVO: cuándo bloquear (R3)
│   ├── app.dart                                    # AppLockGate sobre todas las pantallas (R4)
│   └── presentation/
│       ├── app_lock_scope.dart                     # NUEVO: el controlador para las pantallas
│       ├── screens/lock_screen.dart                # NUEVA: AppLockGate y LockScreen
│       └── screens/settings_screen.dart            # el interruptor
└── test/presentation/app_lock_test.dart            # NUEVO
```

## Complexity Tracking

No hay elementos que justificar.
