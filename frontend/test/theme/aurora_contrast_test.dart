// Contraste de la paleta «azul corporativo» (tarea T139; spec 002, SC-208).
//
// Usa la fórmula de WCAG 2.1: (L1 + 0,05) / (L2 + 0,05), con L la luminancia relativa
// de cada color (Color.computeLuminance). Mínimos del nivel AA:
// - 4,5:1 para todo el texto (principal, secundario, tenue, enlaces, botones y avisos).
// - 3:1 para los bordes de los campos con foco y los íconos.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:handtext_ai/theme/aurora.dart';

/// Contraste entre dos colores opacos, de 1:1 (iguales) a 21:1 (negro y blanco).
double contrast(Color a, Color b) {
  final la = a.computeLuminance();
  final lb = b.computeLuminance();
  final (light, dark) = la > lb ? (la, lb) : (lb, la);
  return (light + 0.05) / (dark + 0.05);
}

void main() {
  // Todo lo que puede quedar detrás del texto en las pantallas Aurora.
  const backgrounds = {
    'fondo arriba': Aurora.backgroundTop,
    'fondo abajo': Aurora.backgroundBottom,
    'tarjeta': Aurora.surface,
    'campo': Aurora.fieldFill,
  };

  group('[SC-208] texto: mínimo 4,5:1', () {
    const texts = {
      'principal': Aurora.textPrimary,
      'secundario': Aurora.textSecondary,
      'tenue': Aurora.textMuted,
      'enlace': Aurora.blueLight,
    };
    for (final text in texts.entries) {
      for (final background in backgrounds.entries) {
        test('${text.key} sobre ${background.key}', () {
          expect(
            contrast(text.value, background.value),
            greaterThanOrEqualTo(4.5),
          );
        });
      }
    }

    test('texto blanco sobre el botón principal', () {
      expect(contrast(Colors.white, Aurora.blue), greaterThanOrEqualTo(4.5));
    });

    test('texto blanco sobre los avisos de cada estado', () {
      for (final accent in [
        Aurora.danger,
        Aurora.success,
        Aurora.sky,
        Aurora.blueLight,
      ]) {
        // Los avisos pintan el color del estado al 14 % sobre la tarjeta.
        final banner = Color.alphaBlend(
          accent.withValues(alpha: 0.14),
          Aurora.surface,
        );
        expect(contrast(Colors.white, banner), greaterThanOrEqualTo(4.5));
      }
    });
  });

  group('[SC-208] modo claro (editor, diálogos y hojas)', () {
    const lightBackgrounds = [
      Colors.white,
      Aurora.lightBackground,
      Aurora.lightSurfaceAlt,
    ];

    test('texto principal, secundario y botones de texto: mínimo 4,5:1', () {
      for (final background in lightBackgrounds) {
        for (final text in [
          Aurora.lightText,
          Aurora.lightTextSecondary,
          Aurora.blue,
        ]) {
          expect(contrast(text, background), greaterThanOrEqualTo(4.5));
        }
      }
    });

    test('bordes de campos y botones delineados: mínimo 3:1', () {
      for (final background in lightBackgrounds) {
        expect(
          contrast(Aurora.lightOutline, background),
          greaterThanOrEqualTo(3),
        );
      }
    });
  });

  group('[SC-306] palabras dudosas (spec 003)', () {
    test('el texto marcado se lee con 4,5:1 en modo claro y oscuro', () {
      final light = Color.alphaBlend(Aurora.uncertainFillLight, Colors.white);
      final dark = Color.alphaBlend(
        Aurora.uncertainFillDark,
        Aurora.backgroundBottom,
      );

      expect(contrast(Aurora.lightText, light), greaterThanOrEqualTo(4.5));
      expect(contrast(Aurora.textPrimary, dark), greaterThanOrEqualTo(4.5));
    });

    test('el subrayado se distingue del fondo con 3:1', () {
      expect(
        contrast(Aurora.uncertainUnderlineLight, Colors.white),
        greaterThanOrEqualTo(3),
      );
      expect(
        contrast(Aurora.uncertainUnderlineDark, Aurora.backgroundBottom),
        greaterThanOrEqualTo(3),
      );
    });
  });

  group('[SC-208] íconos y bordes con foco: mínimo 3:1', () {
    test('borde con foco sobre el campo', () {
      expect(
        contrast(Aurora.blueLight, Aurora.fieldFill),
        greaterThanOrEqualTo(3),
      );
    });

    test('ícono azul claro sobre su insignia', () {
      final badge = Color.alphaBlend(Aurora.iconBadge, Aurora.surface);
      expect(contrast(Aurora.blueLight, badge), greaterThanOrEqualTo(3));
    });

    test('colores de estado y de escaneo sobre el fondo y las tarjetas', () {
      for (final accent in [
        Aurora.sky,
        Aurora.success,
        Aurora.warning,
        Aurora.danger,
      ]) {
        for (final background in backgrounds.values) {
          expect(contrast(accent, background), greaterThanOrEqualTo(3));
        }
      }
    });
  });
}
