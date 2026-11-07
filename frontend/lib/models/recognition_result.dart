// Resultado del reconocimiento (tareas T015 y T207; contracts/api.md; en 003,
// contracts/recognition-api.md).

import 'package:flutter/services.dart';

/// Lo que devuelve la API al reconocer una página: si había texto, el texto y sus
/// palabras dudosas.
class RecognitionResult {
  const RecognitionResult({
    required this.hasText,
    required this.text,
    this.uncertainRanges = const [],
  });

  /// `false` cuando la imagen no tenía texto reconocible (Historia 1, escenario 7).
  final bool hasText;

  /// Texto tal como lo devolvió el servicio (fidelidad, constitución §3).
  final String text;

  /// Spec 003: palabras dudosas, en posiciones UTF-16 de [text] ya validadas.
  final List<TextRange> uncertainRanges;
}
