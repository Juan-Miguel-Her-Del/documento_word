"""Genera el ícono de la app en todos los tamaños de Android (tarea T146; spec 002,
Clarifications 2026-10-29).

Dibuja el mismo logo-escáner de la app (lib/presentation/widgets/scanner_logo.dart):
- una hoja blanca con renglones;
- las esquinas del marco del escáner;
- la línea de escaneo celeste.

Usa los colores de lib/theme/aurora.dart y escribe en android/app/src/main/res/:
- mipmap-*/ic_launcher.png: ícono clásico (cuadrado redondeado azul), para Android 7.
- mipmap-*/ic_launcher_foreground.png: dibujo del ícono adaptable (Android 8 o más). El
  fondo azul está en values/colors.xml.
- mipmap-*/ic_launcher_monochrome.png: silueta para los íconos con tema (Android 13+).
- mipmap-anydpi-v26/ic_launcher.xml: une el fondo, el dibujo y la silueta.

Uso (desde la carpeta frontend, con Pillow; la del backend sirve):
    ..\\backend\\.venv\\Scripts\\python tool\\generate_launcher_icon.py
"""

from __future__ import annotations

import pathlib

from PIL import Image, ImageDraw

RES = pathlib.Path(__file__).resolve().parent.parent / "android" / "app" / "src" / "main" / "res"

# Colores de lib/theme/aurora.dart.
BLUE = (0x25, 0x63, 0xEB, 255)
NAVY = (0x0F, 0x1E, 0x36, 255)
MUTED = (0x94, 0xA3, 0xB8, 255)
SKY = (0x38, 0xBD, 0xF8, 255)
WHITE = (255, 255, 255, 255)

# Tamaño en píxeles de cada densidad: ícono clásico (48 dp) y adaptable (108 dp).
DENSITIES = {"mdpi": 1.0, "hdpi": 1.5, "xhdpi": 2.0, "xxhdpi": 3.0, "xxxhdpi": 4.0}
SUPERSAMPLE = 4  # se dibuja 4 veces más grande y se reduce: bordes suaves


def draw_logo(draw: ImageDraw.ImageDraw, x: float, y: float, w: float, *, mono: bool) -> None:
    """Dibuja hoja, renglones, marco y línea de escaneo en el cuadrado (x, y, w, w).

    Mismas proporciones que _ScannerPainter (scanner_logo.dart), con la línea de escaneo
    quieta a dos tercios de la hoja. En la versión monocromática todo es blanco y la
    hoja se dibuja solo con su contorno.
    """
    # Hoja.
    page = (x + 0.30 * w, y + 0.22 * w, x + 0.70 * w, y + 0.78 * w)
    page_w = page[2] - page[0]
    page_h = page[3] - page[1]
    if mono:
        draw.rounded_rectangle(page, radius=0.04 * w, outline=WHITE, width=round(0.03 * w))
    else:
        draw.rounded_rectangle(page, radius=0.04 * w, fill=WHITE)

    # Renglones (el primero, más oscuro, es el título).
    stroke = max(1, round(0.028 * w))
    for i, width in enumerate([0.55, 0.85, 0.70, 0.80, 0.50]):
        line_y = page[1] + page_h * (0.18 + i * 0.16)
        left = page[0] + page_w * 0.16
        right = left + page_w * 0.68 * width
        color = WHITE if mono else (NAVY if i == 0 else MUTED)
        draw.line((left, line_y, right, line_y), fill=color, width=stroke)
        for cx in (left, right):  # extremos redondeados
            r = stroke / 2
            draw.ellipse((cx - r, line_y - r, cx + r, line_y + r), fill=color)

    # Esquinas del marco del escáner.
    frame = (x + 0.20 * w, y + 0.13 * w, x + 0.80 * w, y + 0.87 * w)
    corner = 0.10 * w
    frame_stroke = max(1, round(0.03 * w))
    frame_color = WHITE
    left, top, right, bottom = frame
    for points in (
        [(left, top + corner), (left, top), (left + corner, top)],
        [(right - corner, top), (right, top), (right, top + corner)],
        [(right, bottom - corner), (right, bottom), (right - corner, bottom)],
        [(left + corner, bottom), (left, bottom), (left, bottom - corner)],
    ):
        draw.line(points, fill=frame_color, width=frame_stroke, joint="curve")
        for cx, cy in (points[0], points[2]):
            r = frame_stroke / 2
            draw.ellipse((cx - r, cy - r, cx + r, cy + r), fill=frame_color)

    # Línea de escaneo.
    scan_y = page[1] + page_h * 0.62
    scan_stroke = max(1, round(0.022 * w))
    scan_color = WHITE if mono else SKY
    draw.line(
        (left + 0.04 * w, scan_y, right - 0.04 * w, scan_y),
        fill=scan_color,
        width=scan_stroke,
    )


def render(size_px: int, painter) -> Image.Image:
    """Dibuja en grande con `painter(draw, lado)` y reduce a `size_px` con buena calidad."""
    big = size_px * SUPERSAMPLE
    image = Image.new("RGBA", (big, big), (0, 0, 0, 0))
    painter(ImageDraw.Draw(image), big)
    return image.resize((size_px, size_px), Image.Resampling.LANCZOS)


def legacy_icon(draw: ImageDraw.ImageDraw, side: int) -> None:
    """Ícono clásico: cuadrado redondeado azul con el logo."""
    draw.rounded_rectangle((0, 0, side - 1, side - 1), radius=0.22 * side, fill=BLUE)
    draw_logo(draw, 0, 0, side, mono=False)


def adaptive_foreground(draw: ImageDraw.ImageDraw, side: int, *, mono: bool = False) -> None:
    """Dibujo del ícono adaptable: el logo ocupa el 63 % central (zona segura de 66 dp
    sobre 108 dp, que el sistema nunca recorta)."""
    logo = 0.63 * side
    offset = (side - logo) / 2
    draw_logo(draw, offset, offset, logo, mono=mono)


def main() -> None:
    for density, scale in DENSITIES.items():
        folder = RES / f"mipmap-{density}"
        folder.mkdir(parents=True, exist_ok=True)
        render(round(48 * scale), legacy_icon).save(folder / "ic_launcher.png")
        render(round(108 * scale), adaptive_foreground).save(
            folder / "ic_launcher_foreground.png"
        )
        render(
            round(108 * scale), lambda d, s: adaptive_foreground(d, s, mono=True)
        ).save(folder / "ic_launcher_monochrome.png")

    anydpi = RES / "mipmap-anydpi-v26"
    anydpi.mkdir(exist_ok=True)
    (anydpi / "ic_launcher.xml").write_text(
        '<?xml version="1.0" encoding="utf-8"?>\n'
        "<!-- Ícono adaptable de HandText AI (tarea T146). Lo genera\n"
        "     frontend/tool/generate_launcher_icon.py; no se edita a mano. -->\n"
        '<adaptive-icon xmlns:android="http://schemas.android.com/apk/res/android">\n'
        '    <background android:drawable="@color/ic_launcher_background"/>\n'
        '    <foreground android:drawable="@mipmap/ic_launcher_foreground"/>\n'
        '    <monochrome android:drawable="@mipmap/ic_launcher_monochrome"/>\n'
        "</adaptive-icon>\n",
        encoding="utf-8",
    )
    print("Íconos generados en", RES)


if __name__ == "__main__":
    main()
