# Implementation Plan: Escáner de documentos

**Branch**: `01-constitucion` | **Date**: 2026-11-05 | **Spec**: [spec.md](spec.md)

**Input**: Feature specification from `/specs/009-escaner-de-documentos/spec.md`

## Summary

«Escanear hoja» abre el escáner de documentos de Google ML Kit, que detecta los bordes,
endereza la hoja y deja elegir un filtro. Las hojas llegan a la vista previa como
páginas, por el mismo camino que la galería y la cámara. La API no cambia. Las decisiones
están en [research.md](research.md).

## Technical Context

**Language/Version**: Dart 3.9.2 con Flutter 3.35.4.

**Primary Dependencies**: `google_mlkit_document_scanner` 0.5.0 (nueva; R1).

**Storage**: ninguno nuevo; las hojas pasan a copias de trabajo y los archivos del
escáner se borran enseguida (R4).

**Testing**: flutter_test con un escáner falso (controlador y pantallas); recorrido en el
emulador con el escáner real.

**Target Platform**: Android, minSdk 24 (el complemento pide 21).

**Project Type**: mobile-app.

**Performance Goals**: no aplica.

**Constraints**:
- Sin limpieza automática (R2).
- Nada se envía sin autorización.

**Scale/Scope**:
- Un servicio y un origen de imagen nuevos.
- Cambios en el inicio, la hoja de «Agregar página», los textos y los avisos.

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

| Regla | Cómo se cumple | Estado |
|-------|----------------|--------|
| §2 Dependencias | `google_mlkit_document_scanner` registrada en `pubspec.yaml` y `pubspec.lock`, con la necesidad en R1 | ✅ |
| §3 Conservación del original | Se trabaja con copias; los archivos del escáner se borran (R4) | ✅ |
| §3 Fidelidad | Sin limpieza automática que pueda borrar trazos (R2) | ✅ |
| §3 Privacidad | El escáner trabaja en el teléfono; el envío sigue pidiendo autorización | ✅ |
| §3 Validación antes de procesar | Mismas reglas de formato, tamaño y medidas (R5) | ✅ |
| §5 Mensajes | Escáner no disponible y fallo, con qué hacer (R3, R6) | ✅ |
| §6 Pruebas | Controlador y pantallas con escáner falso; emulador con el real | ✅ |

**Revisión posterior al diseño**: sin violaciones.

## Project Structure

```text
frontend/
├── lib/
│   ├── models/picked_image.dart                 # + ImageOrigin.scanner
│   ├── models/app_failure.dart                  # + scannerUnavailable, scannerFailed
│   ├── models/operation_status.dart             # + StatusAction.takePhoto
│   ├── services/document_scanner_service.dart   # NUEVO: escáner de ML Kit (R1 a R4)
│   ├── state/document_flow_controller.dart      # scanDocument y origen scanner (R5)
│   └── presentation/
│       ├── strings*.dart                        # textos en español e inglés
│       ├── screens/start_screen.dart            # «Escanear hoja» y aviso con acción
│       └── screens/preview_screen.dart          # «Escanear» al agregar página
└── test/state/scanner_flow_test.dart            # NUEVO
```

## Complexity Tracking

No hay elementos que justificar.
