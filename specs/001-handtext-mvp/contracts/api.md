# Contrato de la API REST — HandText AI

**Base**: `http(s)://<servidor>/api/v1` | **Formato de errores**: común a todos los endpoints.

Todas las respuestas incluyen la cabecera `X-Request-ID`. FastAPI publica la descripción
interactiva en `/docs` mientras el servidor está en marcha.

## POST /api/v1/recognitions

Reconoce el texto manuscrito de una imagen. La imagen viaja como cuerpo binario.

**Solicitud**

- Cabecera `Content-Type`: `image/jpeg` o `image/png`. El formato real se decide por el
  contenido, no por esta cabecera.
- Cuerpo: bytes de la imagen (JPEG o PNG, ≤ 10 MB, de 600 a 10 000 px por lado).

**Respuesta 200** (`application/json`)

```json
{ "status": "text_found", "text": "Texto reconocido…", "request_id": "3f2a…" }
```

```json
{ "status": "no_text", "text": "", "request_id": "3f2a…" }
```

`no_text` no es un error: la imagen se procesó, pero no tenía texto reconocible.

**Errores**

| HTTP | `code` | Cuándo |
|------|--------|--------|
| 400 | `IMAGE_UNREADABLE` | Cuerpo vacío, imagen dañada o incompleta |
| 400 | `IMAGE_DIMENSIONS_OUT_OF_RANGE` | Algún lado menor de 600 px o mayor de 10 000 px |
| 413 | `IMAGE_TOO_LARGE` | Más de 10 MB |
| 415 | `UNSUPPORTED_IMAGE_TYPE` | El contenido no es JPEG ni PNG |
| 502 | `OCR_PROVIDER_ERROR` | El proveedor rechazó la solicitud o no respondió correctamente |
| 502 | `OCR_INVALID_RESPONSE` | El proveedor devolvió una respuesta con formato inesperado |
| 503 | `OCR_NOT_CONFIGURED` | El servidor no tiene configurada la clave del proveedor |
| 504 | `OCR_TIMEOUT` | El proveedor no respondió en 45 s |

## POST /api/v1/exports

Genera un archivo Word o PDF con el texto revisado. No guarda nada en el servidor.

**Solicitud** (`application/json`, ≤ 3 MB)

```json
{ "text": "Texto revisado por el usuario…", "format": "docx" }
```

- `text`: no vacío ni compuesto solo por espacios; hasta 200 000 caracteres.
- `format`: `docx` o `pdf`.
- No se admiten campos adicionales.

**Respuesta 200**

| `format` | `Content-Type` | Contenido |
|----------|----------------|-----------|
| `docx` | `application/vnd.openxmlformats-officedocument.wordprocessingml.document` | Un párrafo por línea; las líneas vacías se conservan |
| `pdf` | `application/pdf` | A4, DejaVu Sans de 12 pt, salto de página automático |

La respuesta también incluye `Content-Disposition: attachment; filename="handtext.<ext>"`
y `Cache-Control: no-store`.

**Errores**

| HTTP | `code` | Cuándo |
|------|--------|--------|
| 400 | `EMPTY_TEXT` | El texto está vacío o solo tiene espacios |
| 400 | `UNSUPPORTED_CHARACTERS` | Hay caracteres que el formato no puede representar; el mensaje los enumera |
| 413 | `TEXT_TOO_LARGE` | Más de 200 000 caracteres o un cuerpo de más de 3 MB |
| 422 | `VALIDATION_ERROR` | JSON mal formado, campos faltantes o adicionales, o formato distinto de `docx`/`pdf` |

## Formato común de error

```json
{
  "error": {
    "code": "IMAGE_TOO_LARGE",
    "message": "La imagen supera el tamaño máximo permitido de 10 MB.",
    "request_id": "3f2a…"
  }
}
```

- `code`: estable. La app decide qué mostrar según este valor.
- `message`: en español y sin rutas, trazas, consultas ni credenciales.
- Otros códigos genéricos: `NOT_FOUND` (404), `METHOD_NOT_ALLOWED` (405) e
  `INTERNAL_ERROR` (500).
