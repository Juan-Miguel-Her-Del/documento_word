# Implementation Plan: Varias páginas por documento

**Branch**: `01-constitucion` | **Date**: 2026-10-29 | **Spec**: [spec.md](spec.md)

**Input**: Feature specification from `/specs/004-varias-paginas/spec.md`

## Summary

La vista previa pasa a manejar de 1 a 10 páginas:
- elegirlas juntas de la galería o agregarlas de a una con la cámara;
- verlas en miniatura, ordenarlas, quitarlas, recortarlas o reemplazarlas;
- reconocerlas una por una, sin reenviar las que ya se leyeron.

El editor recibe un solo texto con las páginas en orden. La API no cambia. Las decisiones
están en [research.md](research.md).

## Technical Context

**Language/Version**: Dart 3.9.2 con Flutter 3.35.4 (sin cambios en Python).

**Primary Dependencies**: ninguna nueva; se usa `pickMultiImage` de image_picker.

**Storage**: sin cambios. Las copias de trabajo de 001, una por página.

**Testing**: flutter_test con servicios falsos (galería con varias imágenes y API que
falla en una página).

**Target Platform**: Android, minSdk 24.

**Project Type**: mobile-app (la API se usa igual que en 001).

**Performance Goals**: cada página espera como máximo 60 s (SC-405). Las miniaturas se
decodifican a 160 px para no ocupar memoria de más.

**Constraints**:
- Máximo 10 páginas.
- Una autorización por envío.
- Sin reenviar páginas ya reconocidas.

**Scale/Scope**:
- Un modelo nuevo (`DocumentPage`) y una función pura (`joinPages`).
- Cambios en el controlador y en la vista previa, y una tira de miniaturas.

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

| Regla | Cómo se cumple | Estado |
|-------|----------------|--------|
| §1 Varias páginas solo con especificación aprobada | Spec 004 con Clarifications; Non-Goals de 001 y 003 anotados | ⚠️ falta la aprobación del responsable (CHK408, CHK409) |
| §2 Lógica separada de los widgets | `joinPages` es una función pura; las páginas se manejan en el controlador | ✅ |
| §2 Dependencias | Ninguna nueva | ✅ |
| §3 Conservación del original | Cada página trabaja sobre su copia | ✅ |
| §3 Privacidad | Una autorización que dice cuántas imágenes se envían | ✅ |
| §3 Integridad | Un fallo conserva las páginas y sus resultados; nunca se anuncia éxito parcial | ✅ |
| §3 Retención | R7 | ✅ |
| §5 Mensajes | Cada fallo dice qué página y qué hacer | ✅ |
| §6 Pruebas | Controlador, `joinPages` y pantalla con servicios falsos | ✅ |

**Revisión posterior al diseño**: sin violaciones nuevas.

## Project Structure

```text
frontend/lib/
├── models/document_page.dart          # página: imagen, original y resultado
├── models/operation_status.dart       # página, total y páginas sin texto
├── services/image_source_service.dart # pickMultipleFromGallery
├── services/page_join.dart            # joinPages
├── state/document_flow_controller.dart
└── presentation/
    ├── screens/preview_screen.dart
    └── widgets/page_strip.dart        # miniaturas y acciones de página
```

**Structure Decision**: se mantienen las carpetas de 001 a 003.

## Complexity Tracking

No hay elementos que justificar.
