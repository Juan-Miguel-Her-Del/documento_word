// Identidad visual «Aurora»: colores, degradado del fondo y medidas (tareas T110 y T140).
//
// Spec 002, módulo 5; research.md de 002, R9. Desde el 2026-10-28 usa la paleta «azul
// corporativo»: fondo azul marino casi plano, botones de azul sólido, acento celeste
// solo para el escaneo y tarjetas sólidas con borde fino.
// Todas las pantallas toman sus colores de aquí: si la profesora pregunta «¿dónde se
// define el diseño?», es este archivo junto con app_theme.dart (constitución §2: temas
// centralizados). El contraste de cada par de colores se prueba en
// test/theme/aurora_contrast_test.dart [SC-208].

import 'package:flutter/material.dart';

abstract final class Aurora {
  // --- Fondo y superficies ------------------------------------------------------
  /// Azul marino casi negro: parte de arriba del fondo.
  static const Color backgroundTop = Color(0xFF0B1220);

  /// Azul marino: parte de abajo del fondo y encabezado del editor.
  static const Color backgroundBottom = Color(0xFF0F1E36);

  /// Tarjetas sobre el fondo.
  static const Color surface = Color(0xFF14223A);

  /// Borde fino de tarjetas y campos.
  static const Color surfaceBorder = Color(0xFF2A3B57);

  /// Relleno de los campos de texto (un poco más oscuro que la tarjeta).
  static const Color fieldFill = Color(0xFF0F1B2F);

  // --- Colores de marca ---------------------------------------------------------
  /// Azul corporativo: botón principal, avatar y casillas marcadas.
  static const Color blue = Color(0xFF2563EB);

  /// Azul claro: enlaces, íconos destacados y borde del campo con foco.
  static const Color blueLight = Color(0xFF60A5FA);

  /// Celeste: solo la línea de escaneo y lo relacionado con «leer» la imagen.
  static const Color sky = Color(0xFF38BDF8);

  /// Fondo de las insignias de íconos: azul corporativo al 18 %.
  static const Color iconBadge = Color(0x2E2563EB);

  // --- Estados ------------------------------------------------------------------
  static const Color success = Color(0xFF34D399);
  static const Color warning = Color(0xFFFBBF24);
  static const Color danger = Color(0xFFF87171);

  // --- Texto sobre el fondo -----------------------------------------------------
  static const Color textPrimary = Colors.white;
  static const Color textSecondary = Color(0xFFCBD5E1);
  static const Color textMuted = Color(0xFF94A3B8);

  // --- Modo claro (editor, diálogos y hojas) ------------------------------------
  // Grises pizarra neutros: sin el tinte lila que agrega Material por defecto.
  static const Color lightBackground = Color(0xFFF8FAFC);
  static const Color lightSurfaceAlt = Color(0xFFF1F5F9);
  static const Color lightBorder = Color(0xFFE2E8F0);

  /// Borde de campos y botones delineados en modo claro.
  static const Color lightOutline = Color(0xFF64748B);
  static const Color lightText = Color(0xFF0F172A);
  static const Color lightTextSecondary = Color(0xFF475569);

  // --- Palabras dudosas (spec 003, SC-306) --------------------------------------
  // Fondo ámbar y subrayado ondulado: la marca no depende solo del color.
  static const Color uncertainFillLight = Color(0x59FBBF24); // ámbar al 35 %
  static const Color uncertainFillDark = Color(0x4DFBBF24); // ámbar al 30 %
  static const Color uncertainUnderlineLight = Color(0xFFB45309);
  static const Color uncertainUnderlineDark = warning;

  // --- Degradado ----------------------------------------------------------------
  /// Fondo de las pantallas Aurora: de arriba hacia abajo, casi plano.
  static const LinearGradient background = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [backgroundTop, backgroundBottom],
  );

  // --- Formas -------------------------------------------------------------------
  static const double radiusLarge = 20;
  static const double radius = 16;
  static const double radiusSmall = 12;
}
