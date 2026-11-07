"""Posiciones de las palabras dudosas dentro del texto (tarea T204; spec 003, módulo 1).

research.md de 003, R1 y R2. Recibe las palabras en el orden en que las leyó el
proveedor, con su seguridad (de 0 a 1), y busca cada una en el texto a partir de donde
terminó la anterior. Así:
- dos apariciones de la misma palabra no se confunden;
- las posiciones salen ordenadas y sin superponerse;
- si una palabra no aparece, solo se pierde su marca y se sigue con las demás.

No depende de ningún proveedor: el adaptador de Google Vision le entrega las palabras.
"""

from __future__ import annotations

from collections.abc import Iterable

from app.services.ocr.base import UncertainSpan


def locate_uncertain_words(
    text: str,
    words: Iterable[tuple[str, float]],
    threshold: float,
) -> tuple[UncertainSpan, ...]:
    """Devuelve las posiciones de las palabras con seguridad menor a `threshold`.

    [EX-H1-E2] Solo cuentan las palabras con al menos una letra o un número: los signos
    de puntuación sueltos nunca se marcan.
    """
    spans: list[UncertainSpan] = []
    cursor = 0
    for word, confidence in words:
        if not word:
            continue
        start = text.find(word, cursor)
        if start < 0:
            continue  # no está en el texto: se omite la marca, nunca se falla
        cursor = start + len(word)
        if confidence < threshold and any(char.isalnum() for char in word):
            spans.append(UncertainSpan(start=start, end=cursor))
    return tuple(spans)
