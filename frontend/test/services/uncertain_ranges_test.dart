// Pruebas de las marcas de palabras dudosas (tarea T206; spec 003, módulo 1).
//
// rangesFromApi convierte y valida las posiciones de la API; adjustRanges mantiene cada
// marca sobre su palabra mientras la persona edita [EX-H1-E4] [SC-302].

import 'dart:math';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:handtext_ai/services/uncertain_ranges.dart';

/// Texto de cada marca.
List<String> _words(String text, List<TextRange> ranges) => [
  for (final range in ranges) range.textInside(text),
];

void main() {
  group('rangesFromApi', () {
    test('convierte las posiciones de la API en marcas del texto', () {
      const text = 'Tema 1: la célula';
      final ranges = rangesFromApi(text, [
        {'start': 11, 'end': 17},
      ]);

      expect(_words(text, ranges), ['célula']);
    });

    test('caso límite: un emoji antes de la palabra no corre la marca', () {
      // En puntos de código el emoji ocupa 1; en UTF-16 (Dart), 2.
      const text = '😀 Hola mundo';
      final ranges = rangesFromApi(text, [
        {'start': 7, 'end': 12},
      ]);

      expect(_words(text, ranges), ['mundo']);
    });

    test('descarta las marcas inválidas y conserva las válidas', () {
      const text = 'uno dos tres';
      final ranges = rangesFromApi(text, [
        {'start': 0, 'end': 3}, // uno
        {'start': 2, 'end': 5}, // se superpone con la anterior
        {'start': 4, 'end': 4}, // vacía
        {'start': 8, 'end': 99}, // fuera del texto
        {'start': '4', 'end': 7}, // tipo incorrecto
        'no es un objeto',
        {'start': 8, 'end': 12}, // tres
      ]);

      expect(_words(text, ranges), ['uno', 'tres']);
    });

    test('sin lista o con otro tipo, no hay marcas', () {
      expect(rangesFromApi('Hola', null), isEmpty);
      expect(rangesFromApi('Hola', {'start': 0}), isEmpty);
    });
  });

  group('adjustRanges', () {
    const text = 'la celula es la unidad';
    const celula = TextRange(start: 3, end: 9);
    const unidad = TextRange(start: 16, end: 22);
    const marks = [celula, unidad];

    test('escribir antes de una marca la desplaza', () {
      const after = 'Hoy la celula es la unidad';

      expect(_words(after, adjustRanges(text, after, marks)), [
        'celula',
        'unidad',
      ]);
    });

    test('escribir entre dos marcas solo desplaza la segunda', () {
      const after = 'la celula no es la unidad';

      expect(_words(after, adjustRanges(text, after, marks)), [
        'celula',
        'unidad',
      ]);
    });

    test('[EX-H1-E4] corregir dentro de la palabra quita su marca', () {
      const after = 'la célula es la unidad';
      final adjusted = adjustRanges(text, after, marks);

      expect(_words(after, adjusted), ['unidad']);
    });

    test('[EX-H1-E4] borrar una parte de la palabra quita su marca', () {
      const after = 'la cel es la unidad';

      expect(_words(after, adjustRanges(text, after, marks)), ['unidad']);
    });

    test(
      '[EX-H1-E4] pegarle letras al final o al principio quita su marca',
      () {
        const atEnd = 'la celulas es la unidad';
        const atStart = 'la xcelula es la unidad';

        expect(_words(atEnd, adjustRanges(text, atEnd, marks)), ['unidad']);
        expect(_words(atStart, adjustRanges(text, atStart, marks)), ['unidad']);
      },
    );

    test('un espacio o un signo junto a la palabra no quita su marca', () {
      const after = 'la celula, es la unidad';

      expect(_words(after, adjustRanges(text, after, marks)), [
        'celula',
        'unidad',
      ]);
    });

    test('reemplazar todo el texto quita todas las marcas', () {
      expect(adjustRanges(text, 'otro texto', marks), isEmpty);
    });

    test(
      '[SC-302] tras cualquier edición, cada marca sigue sobre su palabra',
      () {
        // Prueba con 2000 ediciones al azar (semilla fija, siempre las mismas):
        // inserciones, borrados y reemplazos en cualquier posición.
        final random = Random(42);
        const alphabet = 'abc á,. \n';
        const original = 'uno dos tres dos uno cuatro';
        final words = [
          const TextRange(start: 0, end: 3),
          const TextRange(start: 4, end: 7),
          const TextRange(start: 8, end: 12),
          const TextRange(start: 13, end: 16),
          const TextRange(start: 21, end: 27),
        ];

        for (var i = 0; i < 2000; i++) {
          var before = original;
          var tracked = [
            for (final range in words) (range, range.textInside(before)),
          ];
          for (var step = 0; step < 5; step++) {
            final start = random.nextInt(before.length + 1);
            final end = start + random.nextInt(before.length - start + 1);
            final inserted = String.fromCharCodes([
              for (var k = 0; k < random.nextInt(3); k++)
                alphabet.codeUnitAt(random.nextInt(alphabet.length)),
            ]);
            final after = before.replaceRange(start, end, inserted);

            // Cada marca se ajusta por separado para saber de qué palabra viene.
            tracked = [
              for (final (range, word) in tracked)
                for (final moved in adjustRanges(before, after, [range]))
                  (moved, word),
            ];
            for (final (range, word) in tracked) {
              expect(range.textInside(after), word);
            }
            before = after;
          }
        }
      },
    );
  });

  test('validRanges descarta las marcas que no caben en el texto', () {
    final valid = validRanges('Hola mundo', const [
      TextRange(start: 0, end: 4),
      TextRange(start: 2, end: 6), // se superpone
      TextRange(start: 5, end: 50), // fuera del texto
    ]);

    expect(valid, const [TextRange(start: 0, end: 4)]);
  });
}
