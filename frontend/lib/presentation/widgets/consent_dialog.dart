// Diálogo de autorización de envío (tarea T042; spec 001, módulo 6; research.md, R13).
//
// [H1-E3] Antes de enviar la imagen, se informa al usuario que irá al servidor de
// HandText AI y a Google Cloud Vision, y se le pide autorización. Se pregunta antes
// de CADA envío (supuesto 5). Si no autoriza, devuelve false y nada se envía [H1-E4].
// Spec 004 (tarea T307): con varias páginas, dice cuántas imágenes se enviarán
// [VP-H1-E3].

import 'package:flutter/material.dart';

import '../../theme/aurora.dart';
import '../strings.dart';

/// Devuelve true solo si el usuario tocó «Autorizar y enviar».
Future<bool> showConsentDialog(
  BuildContext context, {
  int imageCount = 1,
}) async {
  final authorized = await showDialog<bool>(
    context: context,
    // Tocar fuera del diálogo no debe contar como respuesta.
    barrierDismissible: false,
    builder: (context) => AlertDialog(
      // Insignia con el escudo de privacidad. Center evita que el diálogo la estire
      // a todo el ancho.
      icon: Center(
        child: Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            color: Aurora.blue.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(Aurora.radius),
          ),
          child: Icon(
            Icons.privacy_tip_outlined,
            color: Theme.of(context).brightness == Brightness.dark
                ? Aurora.blueLight
                : Aurora.blue,
            size: 28,
          ),
        ),
      ),
      title: Text(context.strings.consentTitleFor(imageCount)),
      content: Text(context.strings.consentMessageFor(imageCount)),
      // Si los botones no caben en una fila, se apilan centrados y con la acción
      // principal arriba.
      actionsOverflowAlignment: OverflowBarAlignment.center,
      actionsOverflowDirection: VerticalDirection.up,
      actionsOverflowButtonSpacing: 8,
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: Text(context.strings.consentDecline),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(true),
          child: Text(context.strings.consentAccept),
        ),
      ],
    ),
  );
  return authorized ?? false; // cerrar con «atrás» = no autoriza
}
