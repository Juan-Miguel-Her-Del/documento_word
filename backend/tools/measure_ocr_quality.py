"""Mide la calidad del reconocimiento con hojas reales (tarea T059; spec 001, SC-010;
research.md de 001, R15).

Uso (desde la carpeta backend, con la clave de Google en la variable de entorno):
    $env:HANDTEXT_GOOGLE_VISION_API_KEY = "<su clave>"
    .venv\\Scripts\\python -m tools.measure_ocr_quality C:\\ruta\\a\\mis_hojas --acepto-enviar

La carpeta tiene pares de archivos con el mismo nombre:
- hoja1.jpg (o .png): la foto de la hoja manuscrita;
- hoja1.txt: lo que dice la hoja, escrito por una persona (la transcripción correcta).

Para cada hoja:
1. Pasa la imagen por la misma validación, preparación y adaptador de Google Cloud
   Vision que usa la API.
2. Compara el texto reconocido con la transcripción y calcula:
   - CER, la tasa de error de caracteres;
   - WER, la tasa de error de palabras;
   - qué tan bien señalan los errores las marcas de palabras dudosas (spec 003).

Privacidad (constitución §3):
- sin `--acepto-enviar` no se envía nada;
- el informe muestra nombres de archivo y números, nunca el texto;
- no se guarda ningún archivo.
"""

from __future__ import annotations

import argparse
import asyncio
import re
import sys
import unicodedata
from collections.abc import Sequence
from dataclasses import dataclass
from pathlib import Path

from app.config import Settings
from app.errors import AppError
from app.services.image_preparation import prepare_for_ocr
from app.services.image_validation import validate_image
from app.services.ocr import OcrError, OcrProvider, build_ocr_provider
from app.services.ocr.base import UncertainSpan

IMAGE_SUFFIXES = (".jpg", ".jpeg", ".png")

# Meta propuesta para SC-010: como máximo un 10 % de caracteres con error (debe
# aprobarla el responsable del proyecto, CHK012).
DEFAULT_TARGET_CER = 0.10


# --- Métricas -------------------------------------------------------------------------


def normalize(text: str) -> str:
    """Unicode NFC y los espacios o saltos de línea seguidos cuentan como uno solo.

    Mayúsculas, tildes y signos se conservan: también cuentan como errores.
    """
    return " ".join(unicodedata.normalize("NFC", text).split())


def edit_distance(reference: Sequence[object], hypothesis: Sequence[object]) -> int:
    """Distancia de Levenshtein: mínimo de inserciones, borrados y sustituciones.

    Sirve para caracteres (cadenas) y para palabras (listas). Guarda solo dos filas de
    la tabla, así la memoria crece con el largo, no con el cuadrado del largo.
    """
    previous = list(range(len(hypothesis) + 1))
    for i, ref_item in enumerate(reference, start=1):
        current = [i]
        for j, hyp_item in enumerate(hypothesis, start=1):
            current.append(
                min(
                    previous[j] + 1,  # borrado
                    current[j - 1] + 1,  # inserción
                    previous[j - 1] + (ref_item != hyp_item),  # sustitución o acierto
                )
            )
        previous = current
    return previous[-1]


def _correct_words(reference: list[str], hypothesis: list[str]) -> list[bool]:
    """Para cada palabra reconocida, indica si coincide con su palabra de la transcripción.

    Recorre hacia atrás la tabla de Levenshtein completa para saber qué palabras se
    alinearon como aciertos.
    """
    rows, cols = len(reference), len(hypothesis)
    table = [[0] * (cols + 1) for _ in range(rows + 1)]
    for i in range(rows + 1):
        table[i][0] = i
    for j in range(cols + 1):
        table[0][j] = j
    for i in range(1, rows + 1):
        for j in range(1, cols + 1):
            table[i][j] = min(
                table[i - 1][j] + 1,
                table[i][j - 1] + 1,
                table[i - 1][j - 1] + (reference[i - 1] != hypothesis[j - 1]),
            )

    correct = [False] * cols
    i, j = rows, cols
    while i > 0 and j > 0:
        same = reference[i - 1] == hypothesis[j - 1]
        if table[i][j] == table[i - 1][j - 1] + (not same):
            correct[j - 1] = same
            i, j = i - 1, j - 1
        elif table[i][j] == table[i][j - 1] + 1:
            j -= 1  # palabra reconocida de más: es un error
        else:
            i -= 1  # palabra de la transcripción que no se reconoció
    return correct


@dataclass(frozen=True)
class PageResult:
    """Números de una hoja; nunca guarda el texto."""

    name: str
    reference_chars: int
    char_errors: int
    reference_words: int
    word_errors: int
    marked_words: int  # palabras reconocidas con marca de dudosa
    marked_wrong: int  # de esas, cuántas tenían de verdad un error
    wrong_words: int  # palabras reconocidas con error (marcadas o no)

    @property
    def cer(self) -> float:
        return self.char_errors / max(self.reference_chars, 1)

    @property
    def wer(self) -> float:
        return self.word_errors / max(self.reference_words, 1)


def evaluate_page(
    name: str,
    reference: str,
    recognized: str,
    uncertain_spans: Sequence[UncertainSpan],
) -> PageResult:
    """Compara el texto reconocido de una hoja con su transcripción correcta."""
    ref = normalize(reference)
    ref_words = ref.split()

    # Palabras reconocidas con su posición en el texto original, para cruzarlas con las
    # marcas (que usan posiciones de ese mismo texto).
    tokens = [(match.start(), match.end()) for match in re.finditer(r"\S+", recognized)]
    hyp_words = [unicodedata.normalize("NFC", recognized[start:end]) for start, end in tokens]
    hyp = " ".join(hyp_words)

    correct = _correct_words(ref_words, hyp_words)
    marked = [
        any(span.start < end and start < span.end for span in uncertain_spans)
        for start, end in tokens
    ]
    return PageResult(
        name=name,
        reference_chars=len(ref),
        char_errors=edit_distance(ref, hyp),
        reference_words=len(ref_words),
        word_errors=edit_distance(ref_words, hyp_words),
        marked_words=sum(marked),
        marked_wrong=sum(m and not c for m, c in zip(marked, correct, strict=True)),
        wrong_words=sum(not c for c in correct),
    )


# --- Medición e informe ----------------------------------------------------------------


async def measure_folder(folder: Path, provider: OcrProvider) -> tuple[list[PageResult], list[str]]:
    """Reconoce cada imagen que tenga su .txt y devuelve los resultados y lo omitido."""
    results: list[PageResult] = []
    skipped: list[str] = []
    images = sorted(p for p in folder.iterdir() if p.suffix.lower() in IMAGE_SUFFIXES)
    for image_path in images:
        reference_path = image_path.with_suffix(".txt")
        if not reference_path.exists():
            skipped.append(f"{image_path.name}: falta {reference_path.name}")
            continue
        data = image_path.read_bytes()
        try:
            validate_image(data)  # las mismas reglas de la API (spec, módulo 1)
            result = await provider.recognize(prepare_for_ocr(data))
        except AppError as error:
            skipped.append(f"{image_path.name}: imagen rechazada ({error.code.value})")
            continue
        except OcrError as error:
            skipped.append(f"{image_path.name}: fallo del proveedor ({type(error).__name__})")
            continue
        # utf-8-sig: acepta también los .txt guardados con el Bloc de notas (con BOM).
        reference = reference_path.read_text(encoding="utf-8-sig")
        results.append(
            evaluate_page(image_path.name, reference, result.text, result.uncertain_spans)
        )
    return results, skipped


def _percent(value: float) -> str:
    return f"{value * 100:5.1f} %"


def format_report(
    results: Sequence[PageResult],
    target_cer: float,
    skipped: Sequence[str] = (),
) -> str:
    """Informe en texto: una fila por hoja y el resultado global de SC-010."""
    lines = [
        f"{'Hoja':<28} {'Caracteres':>10} {'CER':>8} {'WER':>8} {'Marcadas':>9} {'Con error':>9}",
    ]
    for page in results:
        lines.append(
            f"{page.name[:28]:<28} {page.reference_chars:>10} {_percent(page.cer):>8} "
            f"{_percent(page.wer):>8} {page.marked_words:>9} {page.wrong_words:>9}"
        )
    for reason in skipped:
        lines.append(f"Omitida: {reason}")
    if not results:
        lines.append("No hay hojas para medir.")
        return "\n".join(lines)

    # Promedio ponderado: suma de errores / suma de caracteres de todas las hojas.
    chars = sum(page.reference_chars for page in results)
    cer = sum(page.char_errors for page in results) / max(chars, 1)
    words = sum(page.reference_words for page in results)
    wer = sum(page.word_errors for page in results) / max(words, 1)
    marked = sum(page.marked_words for page in results)
    marked_wrong = sum(page.marked_wrong for page in results)
    wrong = sum(page.wrong_words for page in results)

    verdict = "CUMPLE" if cer <= target_cer else "NO CUMPLE"
    lines += [
        "",
        f"Hojas medidas: {len(results)} (SC-010 pide al menos 10)",
        f"CER global: {_percent(cer).strip()}   WER global: {_percent(wer).strip()}",
        f"SC-010 (CER <= {_percent(target_cer).strip()}): {verdict}",
        "Marcas de palabras dudosas (spec 003):",
        f"  precisión: {marked_wrong} de {marked} marcadas tenían un error",
        f"  cobertura: {marked_wrong} de {wrong} palabras con error estaban marcadas",
    ]
    return "\n".join(lines)


def main(argv: Sequence[str] | None = None) -> int:
    parser = argparse.ArgumentParser(
        prog="python -m tools.measure_ocr_quality",
        description="Mide la calidad del reconocimiento (SC-010) con hojas reales.",
    )
    parser.add_argument("carpeta", type=Path, help="carpeta con pares hoja.jpg + hoja.txt")
    parser.add_argument(
        "--meta",
        type=float,
        default=DEFAULT_TARGET_CER,
        help="CER máximo aceptado, de 0 a 1 (por omisión 0.10, es decir, 10 %%)",
    )
    parser.add_argument(
        "--acepto-enviar",
        action="store_true",
        help="autoriza enviar las imágenes a Google Cloud Vision",
    )
    args = parser.parse_args(argv)

    if not args.acepto_enviar:
        print(
            "Las imágenes se enviarán a Google Cloud Vision para reconocerlas. "
            "Si está de acuerdo, vuelva a ejecutar el comando con --acepto-enviar."
        )
        return 2
    if not args.carpeta.is_dir():
        print(f"No existe la carpeta {args.carpeta}.")
        return 2
    provider = build_ocr_provider(Settings.from_environment())
    if provider is None:
        print("Falta la clave: defina HANDTEXT_GOOGLE_VISION_API_KEY (ver quickstart.md).")
        return 2

    results, skipped = asyncio.run(measure_folder(args.carpeta, provider))
    print(format_report(results, args.meta, skipped))
    return 0


if __name__ == "__main__":
    sys.exit(main())
