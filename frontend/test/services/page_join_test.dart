// Pruebas de la unión del texto de varias páginas (tarea T301; spec 004).

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:handtext_ai/models/recognition_result.dart';
import 'package:handtext_ai/services/page_join.dart';

RecognitionResult _page(String text, [List<TextRange> marks = const []]) =>
    RecognitionResult(
      hasText: text.trim().isNotEmpty,
      text: text,
      uncertainRanges: marks,
    );

void main() {
  test('una sola página queda exactamente igual que en 001', () {
    final joined = joinPages([_page('Hola mundo\n')]);

    expect(joined.text, 'Hola mundo\n');
    expect(joined.emptyPages, isEmpty);
  });

  test('[SC-401] las páginas se unen en orden con una línea en blanco', () {
    final joined = joinPages([
      _page('Página uno\n'),
      _page('Página dos  \n\n'),
      _page('Página tres'),
    ]);

    expect(joined.text, 'Página uno\n\nPágina dos\n\nPágina tres');
  });

  test('[SC-404] las marcas se desplazan a su lugar en el texto unido', () {
    final joined = joinPages([
      _page('la celula', const [TextRange(start: 3, end: 9)]),
      _page('el nucleo', const [TextRange(start: 3, end: 9)]),
    ]);

    expect(
      [for (final r in joined.uncertainRanges) r.textInside(joined.text)],
      ['celula', 'nucleo'],
    );
  });

  test('[VP-H3-E4] las páginas sin texto se omiten y se informan', () {
    final joined = joinPages([_page('uno'), _page('  '), _page('tres')]);

    expect(joined.text, 'uno\n\ntres');
    expect(joined.emptyPages, [2]);
    expect(joined.hasText, isTrue);
  });

  test('[VP-H3-E5] si ninguna página tiene texto, no hay texto', () {
    final joined = joinPages([_page(''), _page('\n')]);

    expect(joined.hasText, isFalse);
    expect(joined.emptyPages, [1, 2]);
  });
}
