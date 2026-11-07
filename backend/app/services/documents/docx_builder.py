"""Generador de archivos Word .docx (tarea T033; Historia 1, escenario 9).

- Cada línea del texto es un párrafo de Word, y las líneas vacías son párrafos vacíos.
  Se conservan el orden, los caracteres y la separación de párrafos (SC-002).
- Las tabulaciones se guardan como tabulaciones de Word.
- El archivo es un .docx real (un ZIP con XML) generado por python-docx, no un archivo
  renombrado (constitución §3, Formatos de salida).
- Los metadatos son neutros: no incluyen datos del usuario.
"""

from __future__ import annotations

import io
from datetime import UTC, datetime

from docx import Document
from docx.document import Document as WordDocument

from app.services.documents.text_rules import (
    find_xml_incompatible_characters,
    split_into_paragraphs,
    unsupported_characters_error,
)


def build_docx(text: str) -> bytes:
    """Genera el .docx en memoria y devuelve sus bytes."""
    invalid = find_xml_incompatible_characters(text)
    if invalid:
        raise unsupported_characters_error(invalid, "Word")

    document = Document()
    _set_neutral_properties(document)
    for line in split_into_paragraphs(text):
        document.add_paragraph(line)

    buffer = io.BytesIO()
    document.save(buffer)
    return buffer.getvalue()


def _set_neutral_properties(document: WordDocument) -> None:
    """Reemplaza los metadatos de la plantilla de python-docx («python-docx», 2013, etc.)."""
    now = datetime.now(UTC)
    properties = document.core_properties
    properties.author = "HandText AI"
    properties.last_modified_by = "HandText AI"
    properties.title = "Documento digitalizado"
    properties.comments = ""
    properties.created = now
    properties.modified = now
    properties.revision = 1
