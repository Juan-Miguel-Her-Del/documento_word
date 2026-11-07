# Data Model: HandText AI — MVP

**Fecha**: 2026-10-26 | **Plan**: [plan.md](plan.md)

No hay base de datos. Estas son las entidades que la app y la API manejan durante el
flujo, con sus reglas de validación, su ubicación y su retención.

## Entidades

### Imagen seleccionada (app)

Copia de trabajo de la imagen que el usuario eligió o fotografió.

| Campo | Regla |
|-------|-------|
| `workingCopy.path` | Archivo en `<caché privada>/handtext_work/`; nunca es el original del usuario |
| `bytes` | Contenido completo; ≤ 10 MB |
| `format` | `jpeg` o `png`, detectado por la firma de bytes |
| `width`, `height` | Entre 600 y 10 000 px cada uno, leídos del encabezado |
| `origin` | `gallery` o `camera`; define si se ofrece «Elegir otra imagen» o «Repetir captura» |

**Retención**: se elimina al terminar el reconocimiento con texto, al cancelar o al
reemplazar la imagen; la carpeta se purga al abrir la app.

### Imagen preparada (API, solo en memoria)

Copia creada a partir de los bytes recibidos: JPEG de calidad 90, con la orientación
aplicada, sin metadatos EXIF y con el lado mayor de 3 000 px como máximo. Existe solo
durante la solicitud.

### Resultado de reconocimiento

| Campo | Regla |
|-------|-------|
| `status` | `text_found` o `no_text` (este último si el texto solo tiene espacios o está vacío) |
| `text` | Texto del proveedor sin modificar; vacío cuando `status = no_text` |
| `request_id` | Identificador de la solicitud |

### Documento en edición (app, memoria)

| Campo | Regla |
|-------|-------|
| `documentText` | Versión confirmada, es decir, el contenido actual del editor (supuesto 1) |
| `draftDirty` | `true` si hay cambios no exportados que deben conservarse en el borrador |

### Borrador (app, almacenamiento privado)

Archivo `draft.txt` (UTF-8) en el almacenamiento interno de la app, excluido de las copias
de seguridad. Se escribe con atomicidad (archivo temporal y renombrado).

- **Se crea o actualiza**: tras un reconocimiento con texto, 400 ms después de cada edición
  y al pasar la app a segundo plano.
- **Se elimina**: tras una exportación correcta sin cambios posteriores (SC-011) o al
  descartar el texto con confirmación.
- **Se lee**: al abrir la app; si existe y no está vacío, el editor se abre con ese texto
  (H1-E15).

### Solicitud de exportación

| Campo | Regla |
|-------|-------|
| `text` | No vacío ni compuesto solo por espacios; ≤ 200 000 caracteres; caracteres representables en el formato (XML válido en Word, glifo disponible en PDF) |
| `format` | `docx` o `pdf` |

### Archivo exportado

| Campo | Regla |
|-------|-------|
| `content` | Bytes reales del formato: un .docx empieza por `PK` (ZIP) y un .pdf por `%PDF-` |
| `mediaType` | `application/vnd.openxmlformats-officedocument.wordprocessingml.document` o `application/pdf` |
| `suggestedName` | `HandText_AAAAMMDD_HHMM.docx` o `.pdf`; el usuario puede cambiarlo en el diálogo |

### Error de la API

`{"error": {"code", "message", "request_id"}}`; los códigos están en
[contracts/api.md](contracts/api.md).

## Estados del flujo en la app

```text
             ┌──────────── cancelar / atrás ─────────────┐
             ▼                                           │
 [Inicio] ──elegir o fotografiar imagen válida──▶ [Vista previa]
    ▲  │                                          │  │   ▲
    │  │                    sin autorización ─────┘  │   │ sin texto o fallo:
    │  │                                             │   │ se queda con mensaje
    │  │                                autoriza y   │   │ y opción de reintentar
    │  │                                hay texto    ▼   │
    │  └──── volver al texto actual ────────────▶ [Editor] ──exportar──▶ (diálogo de guardado)
    │                                                │
    └─ «Procesar otra imagen» (con confirmación) ────┤
    └─ «Descartar texto» (con confirmación) ─────────┘
```

- Al abrir la app con un borrador, se empieza en **Editor**.
- Mientras una operación está en curso (`isBusy`), las acciones que podrían duplicarla
  están desactivadas (SC-008).
- «Procesar otra imagen» no borra el texto actual: solo se sustituye cuando el nuevo
  reconocimiento termina con texto (H1-E13).
