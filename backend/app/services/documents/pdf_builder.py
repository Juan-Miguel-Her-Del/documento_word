"""Generador de archivos PDF (tarea T051; Historia 3).

- Página A4, márgenes de 20 mm, letra DejaVu Sans de 12 pt y alineación izquierda.
- Cada línea del texto es un párrafo; las líneas largas se ajustan al ancho de la página
  y el texto continúa en páginas nuevas cuando hace falta. Nada se trunca (Historia 3,
  escenario 2).
- DejaVu Sans va incrustada en el PDF y cubre tildes, ñ, ¿, ¡, comillas tipográficas y
  miles de caracteres más. Si el texto trae caracteres que la fuente no puede dibujar
  (por ejemplo, emojis), se rechaza con un mensaje que los enumera, en lugar de generar
  un PDF con cuadros vacíos.
- Las tabulaciones se dibujan como cuatro espacios, porque PDF no tiene tabulaciones.
"""

from __future__ import annotations

from functools import lru_cache
from pathlib import Path

from fontTools.ttLib import TTFont
from fpdf import FPDF
from fpdf.enums import Align, XPos, YPos

from app.services.documents.text_rules import split_into_paragraphs, unsupported_characters_error

# backend/app/assets/fonts/DejaVuSans.ttf (licencia en LICENSE-DejaVu.txt, misma carpeta).
FONT_PATH = Path(__file__).resolve().parents[2] / "assets" / "fonts" / "DejaVuSans.ttf"
FONT_FAMILY = "DejaVuSans"
FONT_SIZE_PT = 12
LINE_HEIGHT_MM = 6
MARGIN_MM = 20
TAB_AS_SPACES = "    "


@lru_cache(maxsize=1)
def _font_codepoints() -> frozenset[int]:
    """Códigos Unicode que la fuente sabe dibujar. Se lee una sola vez."""
    font = TTFont(FONT_PATH)
    try:
        return frozenset(font.getBestCmap().keys())
    finally:
        font.close()


def find_unrenderable_characters(text: str) -> list[str]:
    """Caracteres distintos que la fuente no puede dibujar (sin contar \\n ni \\t)."""
    codepoints = _font_codepoints()
    return sorted({c for c in text if c not in "\n\t" and ord(c) not in codepoints})


def build_pdf(text: str) -> bytes:
    """Genera el PDF en memoria y devuelve sus bytes."""
    missing = find_unrenderable_characters(text)
    if missing:
        raise unsupported_characters_error(missing, "PDF")

    pdf = FPDF(orientation="portrait", unit="mm", format="A4")
    pdf.set_title("Documento digitalizado")
    pdf.set_author("HandText AI")
    pdf.set_creator("HandText AI")
    pdf.set_margins(left=MARGIN_MM, top=MARGIN_MM, right=MARGIN_MM)
    pdf.set_auto_page_break(auto=True, margin=MARGIN_MM)
    pdf.add_font(FONT_FAMILY, fname=FONT_PATH)
    pdf.set_font(FONT_FAMILY, size=FONT_SIZE_PT)
    pdf.add_page()

    for line in split_into_paragraphs(text):
        # multi_cell ajusta la línea al ancho disponible (w=0) y salta de página sola.
        # Una línea vacía también ocupa su renglón, así que la separación se conserva.
        pdf.multi_cell(
            w=0,
            h=LINE_HEIGHT_MM,
            text=line.replace("\t", TAB_AS_SPACES),
            align=Align.L,
            new_x=XPos.LMARGIN,
            new_y=YPos.NEXT,
        )

    return bytes(pdf.output())
