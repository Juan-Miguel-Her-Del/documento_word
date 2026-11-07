# Contrato: cambios de la API en 003

La funcionalidad 003 solo **agrega** un campo a la respuesta de reconocimiento de
[001](../../001-handtext-mvp/contracts/api.md). Los demás campos, la solicitud y los
errores no cambian, y una app anterior que ignore el campo nuevo sigue funcionando.

## POST /api/v1/recognitions

**Respuesta 200** (`application/json`)

```json
{
  "status": "text_found",
  "text": "Tema 1: la célula",
  "uncertain_words": [{ "start": 11, "end": 17 }],
  "request_id": "3f2a…"
}
```

- `uncertain_words`: palabras con seguridad menor al 80 % (spec 003, módulo 1).
  - `start` y `end` son posiciones dentro de `text`, contadas en **caracteres Unicode**
    (puntos de código). `start` es la primera posición de la palabra y `end`, la
    posición siguiente a la última; en el ejemplo, `text[11:17]` es «célula».
  - La lista está ordenada por `start` y sus intervalos no se superponen.
  - Solo incluye palabras con al menos una letra o un número.
  - Es una lista vacía si no hay palabras dudosas, si el proveedor no informó la
    seguridad o si `status` es `no_text`.

```json
{ "status": "no_text", "text": "", "uncertain_words": [], "request_id": "3f2a…" }
```

## Lo que la app hace con el campo

- Convierte las posiciones a las unidades de Dart (UTF-16).
- Descarta las marcas que no cumplan las reglas de arriba (fuera del texto, vacías,
  desordenadas o superpuestas) y conserva el texto completo.
