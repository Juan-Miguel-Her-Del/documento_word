# Implementation Plan: Ajustes, «Acerca de» y versión final

**Branch**: `01-constitucion` | **Date**: 2026-10-29 | **Spec**: [spec.md](spec.md)

**Input**: Feature specification from `/specs/005-ajustes-y-version-final/spec.md`

## Summary

La app agrega dos pantallas:
- **Ajustes**: tema y tamaño de letra del editor, guardados en un JSON local;
- **Acerca de**: versión, privacidad y licencias.

Además se prepara la versión final:
- firmada con una clave fuera del repositorio;
- solo HTTPS, salvo una compilación de demostración pedida de forma explícita;
- APK por procesador.

La API no cambia. Las decisiones están en [research.md](research.md).

## Technical Context

**Language/Version**: Dart 3.9.2 con Flutter 3.35.4; Kotlin DSL de Gradle para la firma.

**Primary Dependencies**: ninguna nueva.

**Storage**: `settings.json` en la carpeta privada de soporte (R1).

**Testing**: flutter_test (almacenamiento, controlador, pantallas y versión contra
`pubspec.yaml`).

**Target Platform**: Android, minSdk 24.

**Project Type**: mobile-app.

**Performance Goals**: la versión final abre en menos de 5 s en frío en el emulador
(SC-504).

**Constraints**:
- La clave de firma y sus contraseñas, fuera del repositorio.
- La versión final usa solo HTTPS (salvo la demostración local).

**Scale/Scope**:
- Un controlador, un almacén y tres pantallas (Ajustes, Acerca de y Privacidad).
- Cambios en el menú de cuenta, la bienvenida, el editor y Gradle.

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

| Regla | Cómo se cumple | Estado |
|-------|----------------|--------|
| §2 Secretos fuera del repositorio | Clave en `%USERPROFILE%\.handtext`; contraseñas en `key.properties`, excluido por `.gitignore` | ✅ |
| §2 Dependencias | Ninguna nueva | ✅ |
| §2 Temas centralizados | El tema elegido solo cambia `themeMode`; los colores siguen en `AppTheme` | ✅ |
| §3 Privacidad | Texto de privacidad visible antes de crear la cuenta; HTTPS en la versión final | ✅ |
| §6 Pruebas | Almacén, controlador, pantallas y versión | ✅ |

**Revisión posterior al diseño**: sin violaciones.

## Project Structure

```text
frontend/
├── lib/
│   ├── config/app_config.dart              # appVersion y appBuild
│   ├── models/app_settings.dart            # tema y tamaño de letra
│   ├── services/settings_store.dart        # settings.json
│   ├── state/settings_controller.dart
│   └── presentation/
│       ├── settings_scope.dart             # da acceso a los ajustes en toda la app
│       └── screens/settings_screen.dart, about_screen.dart, privacy_screen.dart
├── assets/fonts/OFL-Poppins.txt            # licencia registrada al arrancar
└── android/
    ├── app/build.gradle.kts                # firma y HTTP según el tipo de compilación
    └── key.properties                      # NO se sube (lo excluye .gitignore)
```

## Complexity Tracking

No hay elementos que justificar.
