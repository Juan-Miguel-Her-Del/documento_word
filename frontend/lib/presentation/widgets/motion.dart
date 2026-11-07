// Preferencia de animaciones (tarea T111; spec 002, CU-H3-E3; SC-207).
//
// Si la persona activó «Quitar animaciones» en la accesibilidad de Android, Flutter lo
// informa con MediaQuery.disableAnimations. Todas las animaciones decorativas de la app
// consultan estas funciones y, en ese caso, se quedan quietas.

import 'package:flutter/widgets.dart';

/// ¿Se pueden reproducir animaciones decorativas en este contexto?
bool decorativeMotionEnabled(BuildContext context) =>
    !MediaQuery.disableAnimationsOf(context);

/// Duración de una transición: la indicada o cero si se pidieron menos animaciones.
Duration motionDuration(BuildContext context, Duration normal) =>
    decorativeMotionEnabled(context) ? normal : Duration.zero;

/// Arranca (o detiene) una animación en bucle según la preferencia del sistema.
/// [stillValue] es la posición en la que queda quieta.
void syncLoopingAnimation(
  BuildContext context,
  AnimationController controller, {
  bool reverse = false,
  double stillValue = 0.35,
}) {
  if (decorativeMotionEnabled(context)) {
    if (!controller.isAnimating) controller.repeat(reverse: reverse);
  } else {
    controller
      ..stop()
      ..value = stillValue;
  }
}
