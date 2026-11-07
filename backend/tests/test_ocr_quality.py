"""Pruebas de la herramienta de medición de calidad (tarea T058; spec 001, SC-010).

research.md de 001, R15: CER y WER con distancia de Levenshtein sobre textos
normalizados, y precisión y cobertura de las marcas de palabras dudosas (spec 003).
No se sale a internet: el proveedor de OCR es falso.
"""

from __future__ import annotations

import asyncio
from pathlib import Path

import pytest

from app.services.ocr.base import UncertainSpan
from tests.conftest import FakeOcrProvider, make_image_bytes
from tools.measure_ocr_quality import (
    edit_distance,
    evaluate_page,
    format_report,
    main,
    measure_folder,
    normalize,
)


def test_normalize_joins_whitespace_and_composes_accents() -> None:
    # «e» + tilde combinable (2 caracteres) se convierte en «é» (1 carácter).
    assert normalize("  Tema 1:\n\nla  célula \t") == "Tema 1: la célula"


def test_edit_distance_counts_insertions_deletions_and_substitutions() -> None:
    assert edit_distance("casa", "casa") == 0
    assert edit_distance("casa", "cosa") == 1  # sustitución
    assert edit_distance("casa", "casas") == 1  # inserción
    assert edit_distance("casa", "asa") == 1  # borrado
    assert edit_distance(["la", "casa"], ["la", "cosa", "azul"]) == 2  # por palabras


def test_a_perfect_page_has_no_errors() -> None:
    page = evaluate_page("hoja", "Tema 1: la célula", "Tema 1:\nla célula", ())

    assert page.cer == 0
    assert page.wer == 0


def test_errors_are_counted_against_the_reference() -> None:
    # Falta la tilde: 1 carácter de 17 y 1 palabra de 4.
    page = evaluate_page("hoja", "Tema 1: la célula", "Tema 1: la celula", ())

    assert page.char_errors == 1
    assert page.reference_chars == 17
    assert page.word_errors == 1
    assert page.reference_words == 4


def test_marks_on_wrong_words_are_counted() -> None:
    # «celula» está mal y marcada; «unidad» está bien pero también marcada.
    recognized = "la celula es la unidad"
    marks = (UncertainSpan(3, 9), UncertainSpan(16, 22))

    page = evaluate_page("hoja", "la célula es la unidad", recognized, marks)

    assert page.marked_words == 2
    assert page.marked_wrong == 1  # precisión: 1 de 2
    assert page.wrong_words == 1
    assert page.marked_wrong / page.wrong_words == 1  # cobertura: el único error


def test_report_shows_numbers_but_never_the_text() -> None:
    # Constitución §3: el informe no debe contener el contenido de las hojas.
    page = evaluate_page(
        "apuntes_1.jpg", "Texto privado del alumno", "Texto privado del alumna", ()
    )

    report = format_report([page], target_cer=0.10)

    assert "apuntes_1.jpg" in report
    assert "privado" not in report
    assert "SC-010" in report


def test_the_global_result_says_whether_the_target_is_met() -> None:
    good = evaluate_page("a", "abcdefghij", "abcdefghij", ())
    bad = evaluate_page("b", "abcdefghij", "xxxxxxxxxx", ())

    assert "CUMPLE" in format_report([good], target_cer=0.10)
    assert "NO CUMPLE" in format_report([good, bad], target_cer=0.10)


def _write_page(folder: Path, name: str, reference: str | None) -> None:
    (folder / f"{name}.png").write_bytes(make_image_bytes(800, 600))
    if reference is not None:
        (folder / f"{name}.txt").write_text(reference, encoding="utf-8")


def test_measure_folder_uses_each_image_with_its_transcription(tmp_path: Path) -> None:
    _write_page(tmp_path, "hoja1", "Hola mundo")
    _write_page(tmp_path, "hoja2", "Hola mundo")
    _write_page(tmp_path, "sin_texto", None)  # sin .txt: se omite
    provider = FakeOcrProvider(text="Hola mundo")

    results, skipped = asyncio.run(measure_folder(tmp_path, provider))

    assert [page.name for page in results] == ["hoja1.png", "hoja2.png"]
    assert all(page.cer == 0 for page in results)
    assert len(provider.received) == 2  # solo se envían las que tienen transcripción
    assert any("sin_texto.png" in reason for reason in skipped)


def test_an_invalid_image_is_skipped_with_its_reason(tmp_path: Path) -> None:
    (tmp_path / "rota.jpg").write_bytes(b"no es una imagen")
    (tmp_path / "rota.txt").write_text("algo", encoding="utf-8")

    results, skipped = asyncio.run(measure_folder(tmp_path, FakeOcrProvider(text="x")))

    assert results == []
    assert any("rota.jpg" in reason for reason in skipped)


def test_without_explicit_consent_nothing_is_sent(
    tmp_path: Path, capsys: pytest.CaptureFixture[str]
) -> None:
    # Constitución §3: el envío a Google debe autorizarse expresamente.
    _write_page(tmp_path, "hoja1", "Hola")

    exit_code = main([str(tmp_path)])

    assert exit_code == 2
    assert "--acepto-enviar" in capsys.readouterr().out
