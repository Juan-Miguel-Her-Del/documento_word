// Encabezado de las pantallas secundarias Aurora (tarea T404; spec 005): botón «Volver»
// y título. Lo usan Ajustes, Acerca de, Privacidad y Mis documentos.
// Spec 006: el título es un encabezado para TalkBack [PA-H2-E5].
// Spec 007: puede llevar acciones a la derecha («Borrar todo» en Mis documentos).

import 'package:flutter/material.dart';

import '../strings.dart';

/// Encabezado de las pantallas secundarias: «Volver», el título y, si hay, acciones
/// a la derecha.
class AuroraHeader extends StatelessWidget {
  const AuroraHeader({super.key, required this.title, this.actions = const []});

  /// Título de la pantalla; TalkBack lo anuncia como encabezado.
  final String title;

  /// Botones a la derecha del título.
  final List<Widget> actions;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 4, 16, 8),
      child: Row(
        children: [
          IconButton(
            tooltip: context.strings.back,
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () => Navigator.of(context).maybePop(),
          ),
          const SizedBox(width: 4),
          Expanded(
            child: Semantics(
              // Nodo propio: no se mezcla con los botones vecinos.
              container: true,
              header: true,
              child: Text(
                title,
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(color: Colors.white),
              ),
            ),
          ),
          ...actions,
        ],
      ),
    );
  }
}
