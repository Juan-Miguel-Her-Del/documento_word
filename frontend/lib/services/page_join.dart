// Unión del texto de varias páginas en un documento (tarea T302; spec 004, módulo 3;
// research.md de 004, R4).
//
// - Con una sola página, el texto queda exactamente como lo devolvió el servicio (001).
// - Con varias, a cada página se le quitan los espacios del final y se unen con una
//   línea en blanco, en el orden elegido [SC-401].
// - Las marcas de palabras dudosas (003) se desplazan a su lugar en el texto unido
//   [SC-404].
// - Las páginas sin texto se omiten y se informan [VP-H3-E4].

import 'package:flutter/services.dart';

import '../models/recognition_result.dart';

/// Texto unido, con sus marcas y las páginas que no tenían texto.
class JoinedText {
  const JoinedText({
    required this.text,
    required this.uncertainRanges,
    required this.emptyPages,
  });

  final String text;
  final List<TextRange> uncertainRanges;

  /// Números de página (desde 1) que no tenían texto.
  final List<int> emptyPages;

  bool get hasText => text.trim().isNotEmpty;
}

/// Separador entre páginas: una línea en blanco.
const pageSeparator = '\n\n';

JoinedText joinPages(List<RecognitionResult> pages) {
  final withText = [
    for (final page in pages)
      if (page.hasText && page.text.trim().isNotEmpty) page,
  ];
  final emptyPages = [
    for (var i = 0; i < pages.length; i++)
      if (!pages[i].hasText || pages[i].text.trim().isEmpty) i + 1,
  ];
  if (pages.length == 1 && withText.length == 1) {
    // Una sola página: igual que en 001, sin tocar el texto.
    return JoinedText(
      text: withText.single.text,
      uncertainRanges: withText.single.uncertainRanges,
      emptyPages: const [],
    );
  }

  final buffer = StringBuffer();
  final ranges = <TextRange>[];
  for (final page in withText) {
    if (buffer.isNotEmpty) buffer.write(pageSeparator);
    final offset = buffer.length;
    final text = page.text.trimRight();
    buffer.write(text);
    for (final range in page.uncertainRanges) {
      // Una marca que quedara en los espacios quitados no tiene palabra: se omite.
      if (range.end <= text.length) {
        ranges.add(
          TextRange(start: range.start + offset, end: range.end + offset),
        );
      }
    }
  }
  return JoinedText(
    text: buffer.toString(),
    uncertainRanges: ranges,
    emptyPages: emptyPages,
  );
}
