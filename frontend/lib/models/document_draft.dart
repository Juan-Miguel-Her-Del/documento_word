// Contenido del borrador local (tarea T208; spec 003, módulo 1; research.md de 003, R5).
//
// Desde 003 el borrador guarda el texto y las marcas de palabras dudosas que quedaban,
// para recuperarlas juntas [EX-H1-E7].
// Spec 007 (tarea T609): también el documento del historial al que pertenece, si ya se
// guardó [HD-H2-E4].

import 'package:flutter/services.dart';

/// Lo que se guarda del documento en edición para recuperarlo si la app se cierra:
/// el texto, las palabras dudosas que quedaban y, si ya se guardó, su documento en
/// Mis documentos.
class DocumentDraft {
  const DocumentDraft(
    this.text, {
    this.uncertainRanges = const [],
    this.historyId,
  });

  /// Texto en edición, tal como lo dejó la persona.
  final String text;

  /// Marcas pendientes, en posiciones UTF-16 de [text].
  final List<TextRange> uncertainRanges;

  /// Spec 007: entrada del historial de este documento; null si no se guardó.
  final String? historyId;
}
