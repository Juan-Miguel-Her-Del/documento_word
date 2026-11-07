# Implementation Plan: Primer uso y accesibilidad

**Branch**: `01-constitucion` | **Date**: 2026-10-29 | **Spec**: [spec.md](spec.md)

**Input**: Feature specification from `/specs/006-primer-uso-y-accesibilidad/spec.md`

## Summary

La app agrega:
- una pantalla de **consejos para una buena foto**, que aparece sola la primera vez y
  se puede volver a abrir desde el inicio y desde Ajustes;
- arreglos de **accesibilidad** encontrados en una auditoría con pruebas: el botón de la
  cuenta, el editor y un diálogo con letra grande, la palabra dudosa leída por TalkBack
  y los títulos como encabezados.

La API no cambia. Las decisiones están en [research.md](research.md).

## Technical Context

**Language/Version**: Dart 3.9.2 con Flutter 3.35.4.

**Primary Dependencies**: ninguna nueva.

**Storage**: un campo nuevo, `tipsSeen`, en `settings.json` (R1).

**Testing**: flutter_test, con las guías de accesibilidad y la letra al 200 % (R4).

**Target Platform**: Android, minSdk 24.

**Project Type**: mobile-app.

**Performance Goals**: no aplica.

**Constraints**:
- No cambiar el flujo de 001 a 005.
- Letra normal sin cambios visibles en el editor (R5).

**Scale/Scope**:
- Una pantalla nueva (consejos).
- Cambios en los ajustes, la zona con sesión, el inicio, Ajustes, el editor, el menú de
  cuenta y los títulos.

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

| Regla | Cómo se cumple | Estado |
|-------|----------------|--------|
| §2 Dependencias | Ninguna nueva | ✅ |
| §2 Temas centralizados | Los consejos usan los colores y widgets Aurora existentes | ✅ |
| §3 Privacidad | Los consejos no piden permisos ni envían datos; `tipsSeen` no es un dato personal | ✅ |
| §5 Estados | Los avisos de procesamiento, éxito y fallo se siguen distinguiendo, ahora también por voz | ✅ |
| §6 Pruebas | Ajustes, pantalla de consejos y guías de accesibilidad al 100 % y al 200 % | ✅ |

**Revisión posterior al diseño**: sin violaciones.

## Project Structure

```text
frontend/
├── lib/
│   ├── models/app_settings.dart                  # + tipsSeen
│   ├── services/settings_store.dart              # + tipsSeen en el JSON
│   ├── state/settings_controller.dart            # + markTipsSeen
│   └── presentation/
│       ├── screens/tips_screen.dart              # NUEVA: los cuatro consejos
│       ├── screens/app_root.dart                 # consejos la primera vez (R2)
│       ├── screens/start_screen.dart             # enlace a los consejos
│       ├── screens/settings_screen.dart          # enlace a los consejos
│       ├── screens/editor_screen.dart            # avisos desplazables (R5) y anuncio (R7)
│       └── widgets/account_menu.dart             # avatar de 48 dp (R9) y diálogo (R6)
└── test/presentation/accessibility_test.dart     # NUEVA: auditoría al 100 % y al 200 %
```

## Complexity Tracking

No hay elementos que justificar.
