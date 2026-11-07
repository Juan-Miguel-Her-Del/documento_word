// Temas centralizados de la app (tareas T013, T110 y T140; constitución §2).
//
// - light() y dark(): pantallas normales (editor, diálogos y hojas), según el modo del
//   sistema [CU-H3-E4]. Ambos usan el azul corporativo como color principal:
//   - en modo claro, con fondos y bordes gris pizarra;
//   - en modo oscuro, con los mismos azules marinos de las pantallas Aurora.
// - onAurora(): pantallas sobre el fondo azul marino (bienvenida, ingreso, registro,
//   inicio y vista previa). Siempre oscuro, con campos rellenos.
// Ninguna pantalla define colores ni tamaños de botón por su cuenta.

import 'package:flutter/material.dart';

import 'aurora.dart';

abstract final class AppTheme {
  /// Tipografía Poppins, incluida en assets/fonts.
  static const String fontFamily = 'Poppins';

  static ThemeData light() => _build(Brightness.light);

  static ThemeData dark() => _build(Brightness.dark);

  /// Tema de las pantallas Aurora (se construye una sola vez).
  static ThemeData onAurora() => _onAurora;

  static final ThemeData _onAurora = _buildOnAurora();

  /// Botones con esquinas moderadas: más sobrios que las píldoras redondas.
  static final RoundedRectangleBorder _buttonShape = RoundedRectangleBorder(
    borderRadius: BorderRadius.circular(Aurora.radiusSmall),
  );

  static ThemeData _build(Brightness brightness) {
    final dark = brightness == Brightness.dark;
    // fromSeed genera los colores de apoyo (contenedores, error…); luego se fijan
    // el azul corporativo y los fondos neutros de la marca.
    final colors =
        ColorScheme.fromSeed(
          seedColor: Aurora.blue,
          brightness: brightness,
          dynamicSchemeVariant: DynamicSchemeVariant.fidelity,
        ).copyWith(
          primary: Aurora.blue,
          onPrimary: Colors.white,
          surface: dark ? Aurora.backgroundTop : Aurora.lightBackground,
          onSurface: dark ? Aurora.textPrimary : Aurora.lightText,
          onSurfaceVariant: dark
              ? Aurora.textSecondary
              : Aurora.lightTextSecondary,
          surfaceContainerLowest: dark ? Aurora.backgroundTop : Colors.white,
          surfaceContainerLow: dark ? Aurora.backgroundBottom : Colors.white,
          surfaceContainer: dark
              ? Aurora.backgroundBottom
              : Aurora.lightSurfaceAlt,
          surfaceContainerHigh: dark ? Aurora.surface : Colors.white,
          surfaceContainerHighest: dark
              ? Aurora.surface
              : Aurora.lightSurfaceAlt,
          outline: dark ? Aurora.textMuted : Aurora.lightOutline,
          outlineVariant: dark ? Aurora.surfaceBorder : Aurora.lightBorder,
        );
    final base = ThemeData(
      colorScheme: colors,
      useMaterial3: true,
      fontFamily: fontFamily,
    );
    // Botones de al menos 52 px de alto: fáciles de tocar con el dedo.
    const minimumButtonSize = Size(64, 52);
    return base.copyWith(
      textTheme: base.textTheme.copyWith(
        headlineMedium: base.textTheme.headlineMedium?.copyWith(
          fontWeight: FontWeight.w700,
        ),
        headlineSmall: base.textTheme.headlineSmall?.copyWith(
          fontWeight: FontWeight.w700,
        ),
        titleLarge: base.textTheme.titleLarge?.copyWith(
          fontWeight: FontWeight.w600,
        ),
        titleMedium: base.textTheme.titleMedium?.copyWith(
          fontWeight: FontWeight.w600,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(Aurora.radiusSmall),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: minimumButtonSize,
          shape: _buttonShape,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: minimumButtonSize,
          shape: _buttonShape,
        ),
      ),
      // En modo oscuro, el azul corporativo como texto no llega a 4,5:1 [SC-208]:
      // los botones de texto usan el azul claro.
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: dark ? Aurora.blueLight : Aurora.blue,
          textStyle: const TextStyle(
            fontFamily: fontFamily,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(Aurora.radius),
          side: BorderSide(color: colors.outlineVariant),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: colors.surfaceContainerHigh,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(Aurora.radiusLarge),
          side: dark
              ? const BorderSide(color: Aurora.surfaceBorder)
              : BorderSide.none,
        ),
      ),
      popupMenuTheme: PopupMenuThemeData(color: colors.surfaceContainerHigh),
      bottomSheetTheme: const BottomSheetThemeData(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(Aurora.radiusLarge),
          ),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(Aurora.radiusSmall),
        ),
      ),
    );
  }

  static ThemeData _buildOnAurora() {
    final base = _build(Brightness.dark);
    final fieldBorder = OutlineInputBorder(
      borderRadius: BorderRadius.circular(Aurora.radiusSmall),
      borderSide: const BorderSide(color: Aurora.surfaceBorder),
    );
    return base.copyWith(
      scaffoldBackgroundColor: Colors.transparent,
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Aurora.fieldFill,
        labelStyle: const TextStyle(color: Aurora.textSecondary),
        floatingLabelStyle: const TextStyle(color: Aurora.blueLight),
        hintStyle: const TextStyle(color: Aurora.textMuted),
        prefixIconColor: Aurora.textMuted,
        suffixIconColor: Aurora.textMuted,
        border: fieldBorder,
        enabledBorder: fieldBorder,
        focusedBorder: fieldBorder.copyWith(
          borderSide: const BorderSide(color: Aurora.blueLight, width: 1.5),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: Aurora.textPrimary,
          minimumSize: const Size(64, 52),
          side: BorderSide(color: Aurora.textMuted.withValues(alpha: 0.6)),
          shape: _buttonShape,
        ),
      ),
      // Spec 005: opciones de Ajustes; la elegida, en azul corporativo.
      segmentedButtonTheme: SegmentedButtonThemeData(
        style: SegmentedButton.styleFrom(
          foregroundColor: Aurora.textPrimary,
          selectedForegroundColor: Colors.white,
          selectedBackgroundColor: Aurora.blue,
          side: const BorderSide(color: Aurora.surfaceBorder),
        ),
      ),
      checkboxTheme: CheckboxThemeData(
        side: const BorderSide(color: Aurora.textSecondary, width: 1.5),
        fillColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? Aurora.blue
              : Colors.transparent,
        ),
      ),
    );
  }
}
