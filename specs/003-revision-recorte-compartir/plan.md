# Implementation Plan: Revisión asistida, recorte y compartir

**Branch**: `01-constitucion` | **Date**: 2026-10-28 | **Spec**: [spec.md](spec.md)

**Input**: Feature specification from `/specs/003-revision-recorte-compartir/spec.md`

## Summary

Tres mejoras sobre el flujo de 001 y 002:

1. **Palabras dudosas**:
   - el adaptador de Google Cloud Vision lee la seguridad de cada palabra y calcula sus
     posiciones en el texto;
   - la API las devuelve en `uncertain_words`;
   - la app las resalta en el editor, las ajusta al editar y las guarda con el borrador.
2. **Recorte y giro**: la vista previa abre el editor nativo uCrop (image_cropper) sobre
   la copia de trabajo y valida el resultado con las reglas de 001.
3. **Compartir**: después de guardar, el aviso de éxito ofrece «Compartir», que abre el
   selector de Android con una copia temporal del archivo exportado (share_plus).

Las decisiones técnicas están en [research.md](research.md).

## Technical Context

**Language/Version**: las mismas de 001 y 002 (Dart 3.9.2 con Flutter 3.35.4; Python 3.12).

**Primary Dependencies** (nuevas, solo en la app):
- image_cropper 12.2.1, que incluye uCrop 2.2.11 (R6).
- share_plus 12.0.2 (R7).

La API no agrega dependencias.

**Storage**:
- No hay cambios en PostgreSQL.
- En el teléfono: borrador en formato 2 (JSON, R5) y las carpetas temporales de R8.

**Testing**:
- *pytest*: lectura de la seguridad, posiciones con caracteres fuera del plano básico y
  respuesta de la API.
- *flutter_test*: ajuste de marcas, borrador, controlador y pantallas, con servicios de
  recorte y de compartir falsos.

**Target Platform**: Android con minSdk 24 (sin cambios).

**Project Type**: mobile-app + API REST.

**Performance Goals**: el ajuste de las marcas tarda menos de 1 ms por tecla en un
texto de 10 000 caracteres; es lineal en el largo del texto.

**Constraints**:
- Las marcas nunca cambian el texto ni se exportan.
- El recorte no toca el archivo original.
- Los temporales se borran según R8.

**Scale/Scope**:
- Un campo nuevo en la respuesta de la API.
- Dos servicios nuevos en la app (recorte y compartir).
- Una barra de revisión en el editor.
- Dos acciones nuevas en la vista previa.
- Una acción nueva en el aviso de éxito.

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

| Regla | Cómo se cumple | Estado |
|-------|----------------|--------|
| §1 Alcance con especificación aprobada | Spec 003 con Clarifications; supuestos 4 y 7 de 001 anotados | ⚠️ falta la aprobación del responsable (CHK309, CHK310) |
| §2 Lógica separada de los widgets | `adjustRanges` y el parser de marcas son funciones puras; recorte y compartir son servicios con interfaz | ✅ |
| §2 Dependencias trazables | image_cropper (R6) y share_plus (R7), registradas en `pubspec.yaml` y `pubspec.lock` | ✅ |
| §3 Conservación del original | uCrop trabaja sobre la copia de trabajo; la original de la sesión se conserva hasta reconocer | ✅ |
| §3 Fidelidad | Las marcas no alteran el texto ni el archivo exportado (SC-303) | ✅ |
| §3 Privacidad | Recortar no envía nada; compartir lo inicia siempre la persona | ✅ |
| §3 Retención | Tabla de R8; purga al abrir la app y al cerrar sesión | ✅ |
| §5 Validación | El recorte se valida con las mismas reglas de 001; el backend vuelve a validar al reconocer | ✅ |
| §5 OCR | Si faltan los datos de seguridad, el texto se devuelve igual y sin marcas; los errores de 001 no cambian | ✅ justificado en R1 |
| §6 Pruebas de OCR e integraciones | Pruebas del adaptador con respuestas simuladas de Vision, del ajuste de marcas y de los servicios falsos | ✅ |

**Revisión posterior al diseño**: sin violaciones nuevas.

## Project Structure

```text
backend/app/
├── config.py                       # UNCERTAIN_WORD_CONFIDENCE
├── schemas.py                      # UncertainWord y RecognitionResponse.uncertain_words
├── api/recognitions.py             # devuelve uncertain_words
└── services/ocr/
    ├── base.py                     # UncertainSpan y OcrResult.uncertain_spans
    ├── google_vision.py            # lee la seguridad de cada palabra
    └── uncertain_words.py          # posiciones de las palabras dudosas en el texto

frontend/lib/
├── models/recognition_result.dart  # uncertainRanges
├── services/
│   ├── uncertain_ranges.dart       # conversión de posiciones, validación y adjustRanges
│   ├── draft_storage.dart          # borrador formato 2
│   ├── image_editor_service.dart   # recorte y giro (image_cropper)
│   └── share_service.dart          # compartir (share_plus)
├── state/document_flow_controller.dart
└── presentation/
    ├── screens/editor_screen.dart  # barra de revisión
    ├── screens/preview_screen.dart # «Recortar o girar» y «Usar la imagen original»
    └── widgets/review_text_controller.dart
```

**Structure Decision**: se mantienen las carpetas de 001 y 002; no se crean capas nuevas.

## Complexity Tracking

| Elemento | Por qué se necesita | Alternativa más simple descartada |
|----------|---------------------|-----------------------------------|
| image_cropper (nativo) | Recortar fotos de hasta 10 000 px sin agotar la memoria | Recorte en Dart puro: decodifica la imagen completa |
| Borrador en JSON | Guardar texto y marcas en una sola escritura atómica | Dos archivos: pueden quedar desincronizados |
