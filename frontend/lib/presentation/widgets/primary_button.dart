// Botón principal (tareas T111 y T141).
//
// Azul corporativo sólido con texto blanco (contraste 5,2:1, SC-208). Al presionarlo se
// encoge un 2 % (microinteracción). Mientras [isLoading] es true muestra un indicador y
// no se puede volver a tocar [SC-008].

import 'package:flutter/material.dart';

import '../../theme/aurora.dart';
import 'motion.dart';

/// Botón principal azul de cada pantalla («Ingresar», «Exportar»…).
class PrimaryButton extends StatefulWidget {
  const PrimaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.isLoading = false,
  });

  /// Texto del botón.
  final String label;

  /// null = botón desactivado.
  final VoidCallback? onPressed;
  /// Ícono a la izquierda del texto (opcional).
  final IconData? icon;
  /// Mientras es true, muestra un indicador y no se puede tocar [SC-008].
  final bool isLoading;

  @override
  State<PrimaryButton> createState() => _PrimaryButtonState();
}

class _PrimaryButtonState extends State<PrimaryButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final enabled = widget.onPressed != null && !widget.isLoading;
    final shape = BorderRadius.circular(Aurora.radiusSmall);
    const textStyle = TextStyle(
      color: Colors.white,
      fontWeight: FontWeight.w600,
      fontSize: 16,
    );

    return Semantics(
      button: true,
      enabled: enabled,
      child: AnimatedScale(
        scale: _pressed ? 0.98 : 1,
        duration: motionDuration(context, const Duration(milliseconds: 120)),
        child: AnimatedOpacity(
          opacity: enabled || widget.isLoading ? 1 : 0.45,
          duration: motionDuration(context, const Duration(milliseconds: 200)),
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: Aurora.blue,
              borderRadius: shape,
              boxShadow: const [
                BoxShadow(
                  color: Color(0x33000000), // negro al 20 %
                  blurRadius: 8,
                  offset: Offset(0, 3),
                ),
              ],
            ),
            child: Material(
              type: MaterialType.transparency,
              child: InkWell(
                borderRadius: shape,
                onTap: enabled ? widget.onPressed : null,
                onHighlightChanged: (pressed) =>
                    setState(() => _pressed = pressed),
                child: SizedBox(
                  height: 54,
                  child: Center(
                    child: widget.isLoading
                        ? const SizedBox.square(
                            dimension: 24,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.5,
                              color: Colors.white,
                            ),
                          )
                        : Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (widget.icon != null) ...[
                                Icon(widget.icon, color: Colors.white),
                                const SizedBox(width: 10),
                              ],
                              Flexible(
                                child: Text(
                                  widget.label,
                                  style: textStyle,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
