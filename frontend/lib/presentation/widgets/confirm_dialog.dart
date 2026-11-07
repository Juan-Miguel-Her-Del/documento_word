// Diálogo genérico de confirmación (tarea T042; spec, módulo 3).
//
// «Solicitar confirmación antes de una acción que descarte o sustituya correcciones;
// cancelar esa acción debe conservarlas.» Se usa para «Procesar otra imagen»
// [H1-E13] y «Descartar texto» [H1-E17].

import 'package:flutter/material.dart';

import '../strings.dart';

/// Devuelve true solo si el usuario confirmó. Cancelar o cerrar devuelve false.
Future<bool> showConfirmDialog(
  BuildContext context, {
  required String title,
  required String message,
  required String confirmLabel,
  bool destructive = false,
}) async {
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (context) {
      final colors = Theme.of(context).colorScheme;
      return AlertDialog(
        title: Text(title),
        content: Text(message),
        // Si los botones no caben en una fila, se apilan centrados y con la
        // acción principal arriba.
        actionsOverflowAlignment: OverflowBarAlignment.center,
        actionsOverflowDirection: VerticalDirection.up,
        actionsOverflowButtonSpacing: 8,
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(context.strings.cancel),
          ),
          FilledButton(
            // Las acciones que borran algo se pintan con el color de error.
            style: destructive
                ? FilledButton.styleFrom(
                    backgroundColor: colors.error,
                    foregroundColor: colors.onError,
                  )
                : null,
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(confirmLabel),
          ),
        ],
      );
    },
  );
  return confirmed ?? false;
}
