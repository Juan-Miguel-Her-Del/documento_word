"""Pruebas de las posiciones de las palabras dudosas (tarea T202; spec 003, SC-301).

research.md de 003, R1 y R2: se marcan las palabras con letras o números y seguridad
menor al umbral; las posiciones cuentan puntos de código dentro del texto.
"""

from __future__ import annotations

from app.services.ocr.base import UncertainSpan
from app.services.ocr.uncertain_words import locate_uncertain_words

THRESHOLD = 0.80


def _marked(text: str, words: list[tuple[str, float]]) -> list[str]:
    spans = locate_uncertain_words(text, words, THRESHOLD)
    return [text[span.start : span.end] for span in spans]


def test_marks_only_words_below_the_threshold() -> None:
    # [EX-H1-E1] [EX-H1-E2] 0,80 justo en el umbral NO se marca; 0,79 sí.
    text = "Tema uno: la célula"
    words = [("Tema", 0.99), ("uno", 0.79), (":", 0.10), ("la", 0.80), ("célula", 0.42)]

    assert _marked(text, words) == ["uno", "célula"]


def test_punctuation_alone_is_never_marked() -> None:
    assert (
        _marked(
            "¿Qué? ¡Sí!",
            [("¿", 0.1), ("Qué", 0.95), ("?", 0.1), ("¡", 0.2), ("Sí", 0.9), ("!", 0.1)],
        )
        == []
    )


def test_words_with_digits_are_marked() -> None:
    assert _marked("Año 2026", [("Año", 0.95), ("2026", 0.5)]) == ["2026"]


def test_repeated_words_mark_the_right_occurrence() -> None:
    # Solo la segunda «casa» es dudosa: la búsqueda avanza desde la palabra anterior.
    text = "casa grande y casa chica"
    words = [("casa", 0.99), ("grande", 0.99), ("y", 0.99), ("casa", 0.3), ("chica", 0.99)]

    spans = locate_uncertain_words(text, words, THRESHOLD)

    assert spans == (UncertainSpan(start=14, end=18),)


def test_positions_count_unicode_characters_not_bytes() -> None:
    # Caso límite: un emoji (fuera del plano básico) antes de la palabra dudosa. En
    # puntos de código ocupa 1 posición (en UTF-16 ocuparía 2; la app convierte).
    text = "😀 Hola mundo"
    spans = locate_uncertain_words(text, [("😀", 0.99), ("Hola", 0.99), ("mundo", 0.5)], THRESHOLD)

    assert spans == (UncertainSpan(start=7, end=12),)
    assert text[7:12] == "mundo"


def test_a_word_that_is_not_in_the_text_is_skipped() -> None:
    # Nunca se falla el reconocimiento por una marca: se omite y se sigue buscando.
    assert _marked("uno dos", [("uno", 0.5), ("xyz", 0.1), ("dos", 0.5)]) == ["uno", "dos"]


def test_spans_are_sorted_and_never_overlap() -> None:
    text = "aa aa aa"
    spans = locate_uncertain_words(text, [("aa", 0.1)] * 3, THRESHOLD)

    assert [(s.start, s.end) for s in spans] == [(0, 2), (3, 5), (6, 8)]


def test_no_words_means_no_marks() -> None:
    assert locate_uncertain_words("Hola", [], THRESHOLD) == ()
