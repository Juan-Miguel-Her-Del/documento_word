# Implementation Plan: Organizar documentos

**Branch**: `01-constitucion` | **Date**: 2026-11-05 | **Spec**: [spec.md](spec.md)

**Input**: Feature specification from `/specs/010-organizar-documentos/spec.md`

## Summary

- El nombre propuesto al guardar pasa a ser el título del documento, limpio y corto.
- El editor gana «Copiar todo el texto».
- Mis documentos gana búsqueda (sin tildes ni mayúsculas) y «Renombrar».

La API no cambia. Las decisiones están en [research.md](research.md).

## Technical Context

**Language/Version**: Dart 3.9.2 con Flutter 3.35.4.

**Primary Dependencies**: ninguna nueva.

**Storage**: un campo opcional, `renamed`, en `history_<id>.json` (R4).

**Testing**: flutter_test (nombre, historial, controlador y pantallas).

**Target Platform**: Android, minSdk 24.

**Project Type**: mobile-app.

**Performance Goals**: búsqueda en memoria sobre 50 documentos como máximo.

**Constraints**: renombrar no toca el texto ni los archivos guardados.

**Scale/Scope**: cambios en `suggestedFileName`, `HistoryEntry`, `DocumentHistory`, el
editor y Mis documentos.

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

| Regla | Cómo se cumple | Estado |
|-------|----------------|--------|
| §1 Alcance | Buscar y renombrar eran Non-Goals de 007: aprobación pendiente (supuesto 3) | ⚠️ pendiente de aprobación |
| §2 Dependencias | Ninguna nueva | ✅ |
| §3 Autoridad del texto editado | Copiar y renombrar no cambian el texto | ✅ |
| §3 Formatos de salida | El nombre conserva la extensión del formato (.docx o .pdf) | ✅ |
| §3 Privacidad | La privacidad avisa que lo copiado queda en el portapapeles (R2) | ✅ |
| §6 Pruebas | Nombre, búsqueda, renombrar, copiar y pantallas | ✅ |

**Revisión posterior al diseño**: sin violaciones; queda la aprobación del alcance.

## Project Structure

```text
frontend/
├── lib/
│   ├── models/history_entry.dart              # + renamed, matchesQuery (R3, R4)
│   ├── services/history_store.dart            # + renamed en el JSON
│   ├── state/document_history.dart            # + rename; record conserva el nombre
│   ├── state/document_flow_controller.dart    # suggestedFileName con el título (R1)
│   └── presentation/
│       ├── screens/editor_screen.dart         # «Copiar todo el texto» (R2)
│       └── screens/history_screen.dart        # búsqueda y «Renombrar» (R3, R5)
└── test/
    ├── services/file_name_test.dart           # NUEVO
    └── presentation/organize_test.dart        # NUEVO
```

## Complexity Tracking

No hay elementos que justificar.
