// Fondo de las pantallas Aurora (tareas T111 y T141; spec 002, módulo 5).
//
// Paleta «azul corporativo»: un degradado casi plano de azul marino (arriba más oscuro)
// con un reflejo azul muy tenue en la parte superior para dar profundidad. Es fijo: no
// tiene luces de colores ni movimiento.

import 'package:flutter/material.dart';

import '../../theme/aurora.dart';

/// Fondo azul marino de las pantallas Aurora; [child] se dibuja encima.
class AuroraBackground extends StatelessWidget {
  const AuroraBackground({super.key, required this.child});

  /// Contenido de la pantalla.
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(gradient: Aurora.background),
      child: DecoratedBox(
        // Reflejo: azul corporativo al 10 % que se desvanece hacia abajo.
        decoration: BoxDecoration(
          gradient: RadialGradient(
            center: const Alignment(0, -1.1),
            radius: 1.2,
            colors: [
              Aurora.blue.withValues(alpha: 0.10),
              Aurora.blue.withValues(alpha: 0),
            ],
          ),
        ),
        child: child,
      ),
    );
  }
}
