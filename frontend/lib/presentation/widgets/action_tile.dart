// Tarjeta de acción grande del inicio (tareas T132 y T142): ícono en una insignia azul,
// título, subtítulo y flecha. Se usa para las opciones del inicio y para los consejos
// en Ajustes.

import 'package:flutter/material.dart';

import '../../theme/aurora.dart';
import 'surface_card.dart';

/// Tarjeta grande y tocable con ícono, título, subtítulo y flecha. Es la forma de las
/// opciones principales: «Escanear hoja», «Tomar fotografía», «Elegir imagen
/// guardada» y «Mis documentos».
class ActionTile extends StatelessWidget {
  const ActionTile({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  /// Ícono de la insignia azul.
  final IconData icon;
  /// Texto principal.
  final String title;
  /// Explicación corta, debajo del título.
  final String subtitle;

  /// null = desactivada (por ejemplo, mientras hay una operación en curso).
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Opacity(
      opacity: onTap == null ? 0.5 : 1,
      child: SurfaceCard(
        padding: EdgeInsets.zero,
        child: Material(
          type: MaterialType.transparency,
          child: InkWell(
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: Aurora.iconBadge,
                      borderRadius: BorderRadius.circular(Aurora.radiusSmall),
                    ),
                    child: Icon(icon, color: Aurora.blueLight),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: textTheme.titleMedium?.copyWith(
                            color: Aurora.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          subtitle,
                          style: textTheme.bodySmall?.copyWith(
                            color: Aurora.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Icon(Icons.chevron_right, color: Aurora.textMuted),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
