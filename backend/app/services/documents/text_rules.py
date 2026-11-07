"""Reglas del texto que se va a exportar (tarea T032; spec, módulo 4).

- El texto vacío o compuesto solo por espacios no se exporta (Historia 1, escenario 10;
  SC-007).
- Límite técnico de 200 000 caracteres (research.md, R14). El texto nunca se trunca: si
  es más largo, se rechaza.
- Los saltos de línea de Windows (\\r\\n) y de Mac antiguo (\\r) se convierten en \\n,
  y cada línea pasa a ser un párrafo. Así se conservan el orden y la separación.
- Si hay caracteres que el formato no puede representar, se responde con un mensaje que
  los enumera, en lugar de generar un archivo dañado o incompleto.
"""

from __future__ import annotations

from collections.abc import Sequence

from app.config import MAX_EXPORT_TEXT_CHARS
from app.errors import AppError, ErrorCode

# Cuántos caracteres problemáticos se enumeran como máximo en el mensaje.
_MAX_LISTED_CHARACTERS = 10


def normalize_newlines(text: str) -> str:
    """Unifica los saltos de línea en \\n."""
    return text.replace("\r\n", "\n").replace("\r", "\n")


def ensure_exportable(text: str) -> str:
    """Valida las reglas comunes y devuelve el texto con los saltos de línea normalizados."""
    # str.strip() quita espacios, tabulaciones y saltos de línea (también los Unicode).
    if not text.strip():
        raise AppError(ErrorCode.EMPTY_TEXT)
    if len(text) > MAX_EXPORT_TEXT_CHARS:
        raise AppError(ErrorCode.TEXT_TOO_LARGE)
    return normalize_newlines(text)


def split_into_paragraphs(text: str) -> list[str]:
    """Una entrada por línea; las líneas vacías se conservan para respetar la separación."""
    return normalize_newlines(text).split("\n")


def _is_xml_compatible(character: str) -> bool:
    """Caracteres permitidos en XML 1.0, el formato interno de los archivos .docx."""
    code = ord(character)
    return (
        code in (0x9, 0xA, 0xD)
        or 0x20 <= code <= 0xD7FF
        or 0xE000 <= code <= 0xFFFD
        or 0x10000 <= code <= 0x10FFFF
    )


def find_xml_incompatible_characters(text: str) -> list[str]:
    """Caracteres distintos que Word no puede guardar (por ejemplo, controles invisibles)."""
    return sorted({character for character in text if not _is_xml_compatible(character)})


def describe_character(character: str) -> str:
    """Describe un carácter para el usuario: visible entre comillas y con su código."""
    code = f"U+{ord(character):04X}"
    return f"«{character}» ({code})" if character.isprintable() else code


def unsupported_characters_error(characters: Sequence[str], format_name: str) -> AppError:
    """Error UNSUPPORTED_CHARACTERS con la lista de caracteres que impiden exportar."""
    listed = ", ".join(describe_character(c) for c in characters[:_MAX_LISTED_CHARACTERS])
    if len(characters) > _MAX_LISTED_CHARACTERS:
        listed += " y otros"
    return AppError(
        ErrorCode.UNSUPPORTED_CHARACTERS,
        f"El texto contiene caracteres que no se pueden incluir en el archivo {format_name}: "
        f"{listed}. Elimínelos o exporte en el otro formato.",
    )
