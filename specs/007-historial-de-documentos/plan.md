# Implementation Plan: Historial de documentos

**Branch**: `01-constitucion` | **Date**: 2026-10-29 | **Spec**: [spec.md](spec.md)

**Input**: Feature specification from `/specs/007-historial-de-documentos/spec.md`

## Summary

Cada guardado correcto queda en un historial local de la cuenta. La pantalla «Mis
documentos» permite:
- ver lo guardado;
- abrir un documento en el editor;
- borrar uno o todos.

El historial es un JSON por cuenta en la carpeta privada de la app, como el borrador. La
API no cambia. Las decisiones están en [research.md](research.md) y los datos en
[data-model.md](data-model.md).

## Technical Context

**Language/Version**: Dart 3.9.2 con Flutter 3.35.4.

**Primary Dependencies**: ninguna nueva.

**Storage**: `history_<id>.json` en la carpeta de soporte de la app (R1 y R2).

**Testing**: flutter_test (almacén, controlador, pantallas y accesibilidad).

**Target Platform**: Android, minSdk 24.

**Project Type**: mobile-app.

**Performance Goals**: con 50 documentos, abrir la lista y un documento en menos de 1 s
(SC-705, emulador Android 16).

**Constraints**:
- El servidor no guarda documentos.
- Un fallo del historial no cambia el resultado del guardado.

**Scale/Scope**:
- Un modelo, un almacén, un controlador del historial y una pantalla.
- Cambios en el controlador de documentos, el borrador, el inicio, el menú de cuenta
  (eliminar la cuenta) y la privacidad.

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

| Regla | Cómo se cumple | Estado |
|-------|----------------|--------|
| §1 Historial no implícito | Funcionalidad propia con spec; aprobación de la profesora pendiente (CHK709) | ⚠️ pendiente de aprobación |
| §2 PostgreSQL para el historial | La base del servidor sigue siendo PostgreSQL; este historial no está en el servidor sino en el teléfono, como el borrador de 001 (R1). Si se sincroniza en el futuro, irá en PostgreSQL | ✅ |
| §2 Dependencias | Ninguna nueva | ✅ |
| §3 Privacidad y acceso | Archivo privado por cuenta; otra cuenta no lo ve; sin copias de seguridad | ✅ |
| §3 Retención | Ubicación, permisos, retención y eliminación definidos en data-model.md | ✅ |
| §3 Consistencia | Solo se registra un guardado correcto (R4) | ✅ |
| §3 Operaciones destructivas | «Eliminar» y «Borrar todo» piden confirmación | ✅ |
| §6 Pruebas | Almacén (incluido archivo dañado), controlador, pantallas y accesibilidad | ✅ |

**Revisión posterior al diseño**: sin violaciones; queda la aprobación de §1.

## Project Structure

```text
frontend/
├── lib/
│   ├── models/history_entry.dart              # NUEVO
│   ├── models/document_draft.dart             # + historyId
│   ├── services/history_store.dart            # NUEVO: history_<id>.json
│   ├── services/draft_storage.dart            # + historyId en el JSON
│   ├── state/document_history.dart            # NUEVO: lista, registrar y borrar
│   ├── state/document_flow_controller.dart    # registrar al guardar, abrir, historyId
│   └── presentation/
│       ├── screens/history_screen.dart        # NUEVA: «Mis documentos»
│       ├── screens/start_screen.dart          # acceso a «Mis documentos»
│       └── widgets/account_menu.dart          # eliminar la cuenta borra el historial
└── test/
    ├── services/history_store_test.dart       # NUEVO
    ├── state/history_flow_test.dart           # NUEVO
    └── presentation/history_screen_test.dart  # NUEVO
```

## Complexity Tracking

No hay elementos que justificar.
