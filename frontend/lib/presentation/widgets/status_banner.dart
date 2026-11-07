// Aviso de estado de una operación (tareas T042 y T133; spec 001, módulo 5).
//
// Muestra con color, ícono y texto si una operación está en curso, terminó bien, falló o
// es solo información. Si trae una acción («Reintentar», «Elegir otra imagen»…), muestra
// el botón. `liveRegion` hace que los lectores de pantalla lo anuncien al cambiar.
//
// Estilo Aurora (spec 002): sobre el fondo azul marino ([onAurora] = true) el aviso es
// translúcido con borde del color del estado; en el editor usa los colores del tema. El
// ícono de éxito aparece con un pequeño «rebote».

import 'package:flutter/material.dart';

import '../../models/operation_status.dart';
import '../../theme/aurora.dart';
import '../strings.dart';
import 'motion.dart';

/// Aviso de estado: color, ícono, texto y, si hay, un botón de acción.
class StatusBanner extends StatelessWidget {
  const StatusBanner({
    super.key,
    required this.status,
    this.actionLabel,
    this.onAction,
    this.onAurora = false,
  });

  /// Qué mostrar: el tipo de aviso, qué pasó y, si falló, el motivo.
  final OperationStatus status;

  /// Texto del botón de acción (si hay acción).
  final String? actionLabel;

  /// Qué hacer al tocar el botón de acción.
  final VoidCallback? onAction;

  /// true sobre el fondo Aurora; false en pantallas con el tema normal.
  final bool onAurora;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final icon = switch (status.kind) {
      StatusKind.failure => Icons.error_outline,
      StatusKind.success => Icons.check_circle_outline,
      StatusKind.inProgress => Icons.hourglass_top,
      StatusKind.info => Icons.info_outline,
    };
    final Color background;
    final Color border;
    final Color foreground;
    if (onAurora) {
      final accent = switch (status.kind) {
        StatusKind.failure => Aurora.danger,
        StatusKind.success => Aurora.success,
        StatusKind.inProgress => Aurora.sky,
        StatusKind.info => Aurora.blueLight,
      };
      background = accent.withValues(alpha: 0.14);
      border = accent.withValues(alpha: 0.45);
      foreground = Colors.white;
    } else {
      (background, foreground) = switch (status.kind) {
        StatusKind.failure => (colors.errorContainer, colors.onErrorContainer),
        StatusKind.success => (
          colors.primaryContainer,
          colors.onPrimaryContainer,
        ),
        StatusKind.inProgress => (
          colors.secondaryContainer,
          colors.onSecondaryContainer,
        ),
        StatusKind.info => (colors.surfaceContainerHighest, colors.onSurface),
      };
      border = Colors.transparent;
    }
    final label = actionLabel;

    return Semantics(
      liveRegion: true,
      child: Container(
        padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
        decoration: BoxDecoration(
          color: background,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: border),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _PopIn(
              enabled: status.kind == StatusKind.success,
              child: Icon(icon, color: foreground),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    context.strings.statusText(status),
                    style: TextStyle(color: foreground),
                  ),
                  if (label != null && onAction != null)
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        style: TextButton.styleFrom(
                          foregroundColor: foreground,
                        ),
                        onPressed: onAction,
                        child: Text(label),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Hace aparecer el ícono con un rebote (solo en los avisos de éxito).
class _PopIn extends StatelessWidget {
  const _PopIn({required this.enabled, required this.child});

  final bool enabled;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    if (!enabled) return child;
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.4, end: 1),
      duration: motionDuration(context, const Duration(milliseconds: 500)),
      curve: Curves.elasticOut,
      builder: (context, scale, child) =>
          Transform.scale(scale: scale, child: child),
      child: child,
    );
  }
}
