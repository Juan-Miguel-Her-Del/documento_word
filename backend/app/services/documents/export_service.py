"""Servicio de exportación: elige el generador según el formato (tarea T034).

Constitución §2: la generación de archivos es un servicio independiente de las rutas.
Esta función se puede probar sin la API ni la app móvil.

Flujo:
1. ensure_exportable: rechaza el texto vacío o demasiado largo y normaliza los saltos
   de línea (Historia 1, escenario 10; SC-007).
2. Llama al generador de Word o de PDF.
3. Devuelve los bytes con el tipo MIME y la extensión reales del formato: contenido,
   extensión y tipo coinciden (constitución §3; SC-001).
"""

from __future__ import annotations

from collections.abc import Callable
from dataclasses import dataclass

from app.schemas import ExportFormat
from app.services.documents.docx_builder import build_docx
from app.services.documents.pdf_builder import build_pdf
from app.services.documents.text_rules import ensure_exportable

DOCX_MEDIA_TYPE = "application/vnd.openxmlformats-officedocument.wordprocessingml.document"
PDF_MEDIA_TYPE = "application/pdf"

# Formato -> (generador, tipo MIME).
_BUILDERS: dict[str, tuple[Callable[[str], bytes], str]] = {
    "docx": (build_docx, DOCX_MEDIA_TYPE),
    "pdf": (build_pdf, PDF_MEDIA_TYPE),
}


@dataclass(frozen=True)
class ExportedDocument:
    """Archivo generado, listo para enviarlo a la app."""

    content: bytes
    media_type: str
    extension: str


def export_document(text: str, export_format: ExportFormat) -> ExportedDocument:
    """Genera el archivo en el formato pedido a partir del texto confirmado por el usuario."""
    clean_text = ensure_exportable(text)
    builder, media_type = _BUILDERS[export_format]
    return ExportedDocument(
        content=builder(clean_text), media_type=media_type, extension=export_format
    )
