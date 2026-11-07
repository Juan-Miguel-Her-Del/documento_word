// Tarjeta sólida de las pantallas Aurora (tarea T141; research.md de 002, R9).
//
// Azul marino un poco más claro que el fondo, con borde fino y una sombra suave. Agrupa
// formularios y acciones sin efectos de vidrio ni desenfoque.

import 'package:flutter/material.dart';

import '../../theme/aurora.dart';

/// Tarjeta azul marino de las pantallas Aurora: agrupa formularios y acciones.
class SurfaceCard extends StatelessWidget {
  const SurfaceCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(20),
    this.radius = Aurora.radius,
  });

  /// Contenido de la tarjeta.
  final Widget child;
  /// Espacio interior.
  final EdgeInsetsGeometry padding;
  /// Redondeo de las esquinas.
  final double radius;

  @override
  Widget build(BuildContext context) {
    final shape = BorderRadius.circular(radius);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Aurora.surface,
        borderRadius: shape,
        border: Border.all(color: Aurora.surfaceBorder),
        boxShadow: const [
          BoxShadow(
            color: Color(0x40000000), // negro al 25 %
            blurRadius: 16,
            offset: Offset(0, 6),
          ),
        ],
      ),
      // Recorta el efecto al tocar (InkWell) con la forma de la tarjeta.
      child: ClipRRect(
        borderRadius: shape,
        child: Padding(padding: padding, child: child),
      ),
    );
  }
}
