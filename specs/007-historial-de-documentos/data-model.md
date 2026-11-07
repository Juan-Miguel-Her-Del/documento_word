# Data Model: Historial de documentos

Todo vive en el teléfono; la API y la base de datos no cambian.

## HistoryEntry (un documento guardado)

| Campo | Tipo | Regla |
|-------|------|-------|
| `id` | texto | Se asigna en el primer guardado; no cambia (R3) |
| `title` | texto | Primera línea con texto, hasta 60 caracteres (R5) |
| `text` | texto | El texto del último guardado; nunca vacío (la exportación rechaza el texto vacío) |
| `formats` | lista de `docx` / `pdf` | Formatos en que se guardó, sin repetir |
| `savedAt` | fecha y hora | Hora del último guardado correcto |

La cantidad de palabras se calcula del texto al mostrarla; no se guarda.

## Archivo `history_<id>.json`

```json
{
  "version": 1,
  "entries": [
    {
      "id": "1793302965123456-48213",
      "title": "Apuntes de biología",
      "text": "Apuntes de biología\nLa célula es…",
      "formats": ["docx", "pdf"],
      "savedAt": "2026-10-29T15:30:00.000"
    }
  ]
}
```

- Orden: el más reciente primero. Máximo 50 entradas.
- Retención: hasta que la persona lo borre o elimine su cuenta (R8).
- Ubicación y permisos: carpeta privada de soporte de la app; sin copias de seguridad.

## Borrador (cambio)

El borrador de 003 («formato 2») suma un campo opcional:
`{"version": 2, "text": …, "uncertain": […], "historyId": "…"}`. Sin el campo, el
documento todavía no se guardó.

## Estado del controlador de documentos

| Dato | Cuándo cambia |
|------|---------------|
| `historyId` | Se asigna al guardar por primera vez o al abrir desde el historial. Vuelve a `null` con un reconocimiento correcto, al descartar y al cerrar sesión |
