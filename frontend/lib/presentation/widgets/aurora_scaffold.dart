// Estructura común de las pantallas Aurora (tarea T111).
//
// Aplica el tema oscuro de Aurora, el fondo fijo (AuroraBackground), íconos claros en
// la barra de estado de Android y el área segura (para no quedar debajo de la cámara
// o la barra de navegación).

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../theme/app_theme.dart';
import 'aurora_background.dart';

/// Estructura de las pantallas Aurora: tema oscuro, fondo, barra de estado clara y
/// área segura.
class AuroraScaffold extends StatelessWidget {
  const AuroraScaffold({super.key, required this.body});

  /// Contenido de la pantalla.
  final Widget body;

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light, // íconos blancos sobre el fondo oscuro
      child: Theme(
        data: AppTheme.onAurora(),
        child: AuroraBackground(
          child: Scaffold(
            backgroundColor: Colors.transparent,
            body: SafeArea(child: body),
          ),
        ),
      ),
    );
  }
}
