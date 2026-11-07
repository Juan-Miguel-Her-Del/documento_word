# Data Model: Revisión asistida, recorte y compartir

La funcionalidad no agrega tablas ni migraciones: nada nuevo se guarda en PostgreSQL.

## Servidor (Python)

### UncertainSpan (`app/services/ocr/base.py`)

| Campo | Tipo | Regla |
|-------|------|-------|
| `start` | int | Posición de inicio en el texto, en puntos de código; ≥ 0 |
| `end` | int | Posición siguiente al final; `start < end ≤ len(text)` |

### OcrResult (ampliado)

| Campo | Tipo | Regla |
|-------|------|-------|
| `text` | str | Igual que en 001: el texto tal como lo entregó el proveedor |
| `uncertain_spans` | tuple[UncertainSpan, …] | Ordenadas y sin superponerse; vacía por omisión |

### RecognitionResponse (ampliado)

El campo nuevo es `uncertain_words: list[UncertainWord]`, con `start` y `end`
([contrato](contracts/recognition-api.md)).

## App (Dart)

### RecognitionResult (ampliado)

| Campo | Tipo | Regla |
|-------|------|-------|
| `uncertainRanges` | List<TextRange> | En unidades UTF-16, ya validadas; vacía si no hay marcas |

### Estado del documento en DocumentFlowController

| Campo | Tipo | Cambia cuando |
|-------|------|---------------|
| `documentText` | String? | Igual que en 001 |
| `uncertainRanges` | List<TextRange> | Se reconoce (se reemplaza), se edita (`adjustRanges`), se toca «Está bien» (se quita una), se descarta o se cierra sesión (se vacía) |
| `originalImage` | PickedImage? | Se recorta por primera vez (guarda la imagen anterior). Se vacía al reconocer, cancelar o volver a la original |
| `lastExport` | ExportedDocument? | Se guarda con éxito (se llena). Se vacía al editar, al exportar de nuevo, al descartar o al cerrar sesión |

### ExportedDocument (solo en memoria)

| Campo | Tipo |
|-------|------|
| `bytes` | Uint8List — el archivo tal como lo devolvió la API |
| `fileName` | String — el nombre propuesto al guardar (`HandText_AAAAMMDD_HHMM.ext`) |
| `format` | ExportFormat — docx o pdf, para el tipo MIME |

### Borrador (archivo `draft_<id>.txt`, formato 2)

```json
{ "version": 2, "text": "Tema 1: la célula", "uncertain": [[11, 17]] }
```

- `uncertain` guarda pares [inicio, fin] en unidades UTF-16.
- Si el archivo no es este JSON, se lee como texto plano (formato 1, de 001 y 002).

## Archivos temporales

Ver [research.md](research.md), R8: resultado de uCrop, copias de trabajo y copia para
compartir.
