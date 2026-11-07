# Data Model: Varias páginas por documento

No hay cambios en el servidor ni en PostgreSQL.

## DocumentPage (`frontend/lib/models/document_page.dart`)

| Campo | Tipo | Regla |
|-------|------|-------|
| `image` | PickedImage | Copia de trabajo validada con las reglas de 001 |
| `original` | PickedImage? | La imagen tal como se eligió, si se recortó (003) |
| `result` | RecognitionResult? | Resultado del reconocimiento; se borra si cambia la imagen de la página (R2) |

## Estado de las páginas en DocumentFlowController

| Campo | Tipo | Regla |
|-------|------|-------|
| `pages` | List<DocumentPage> | De 0 a 10 páginas (SC-403) |
| `selectedPageIndex` | int | Página que se ve en grande; siempre válida si hay páginas |
| `pendingImage` | PickedImage? | La imagen de la página elegida (compatibilidad con 001 y 003) |

## OperationStatus (ampliado)

| Campo | Tipo | Uso |
|-------|------|-----|
| `page` | int? | Página en curso o con fallo (desde 1) |
| `pageCount` | int? | Total de páginas del envío |
| `emptyPages` | List<int> | Páginas sin texto (desde 1) |

## JoinedText (resultado de `joinPages`)

| Campo | Tipo |
|-------|------|
| `text` | String: páginas unidas con una línea en blanco |
| `uncertainRanges` | List<TextRange>: marcas desplazadas al texto unido |
| `emptyPages` | List<int>: páginas sin texto (desde 1) |
