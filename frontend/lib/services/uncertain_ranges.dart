// Marcas de las palabras dudosas (tarea T207; spec 003, módulo 1; research.md de 003,
// R2 y R3).
//
// Funciones puras, sin interfaz, que se prueban por separado:
// - rangesFromApi: convierte las posiciones de la API (puntos de código Unicode) a las
//   de Dart (UTF-16) y descarta las inválidas.
// - validRanges: revisa las marcas leídas del borrador.
// - adjustRanges: mueve o elimina las marcas cuando la persona edita el texto
//   [EX-H1-E4] [SC-302].

import 'dart:math' as math;

import 'package:flutter/services.dart';

/// Convierte la lista `uncertain_words` de la API en posiciones UTF-16 dentro de
/// [text]. Descarta las marcas fuera del texto, vacías, desordenadas o superpuestas; el
/// texto nunca se toca (caso límite del spec).
List<TextRange> rangesFromApi(String text, Object? json) {
  if (json is! List) return const [];

  // utf16Offsets[i] = posición UTF-16 donde empieza el punto de código i. Un emoji
  // ocupa 1 punto de código, pero 2 unidades UTF-16 (caso límite del spec).
  final utf16Offsets = <int>[0];
  for (final rune in text.runes) {
    utf16Offsets.add(utf16Offsets.last + (rune > 0xFFFF ? 2 : 1));
  }
  final codePoints = utf16Offsets.length - 1;

  final ranges = <TextRange>[];
  var previousEnd = 0;
  for (final item in json) {
    if (item case {
      'start': final int start,
      'end': final int end,
    } when start >= previousEnd && start < end && end <= codePoints) {
      ranges.add(TextRange(start: utf16Offsets[start], end: utf16Offsets[end]));
      previousEnd = end;
    }
  }
  return ranges;
}

/// Conserva solo las marcas que caben en [text], en orden y sin superponerse (para el
/// borrador, research.md de 003, R5).
List<TextRange> validRanges(String text, Iterable<TextRange> ranges) {
  final valid = <TextRange>[];
  var previousEnd = 0;
  for (final range in ranges) {
    if (range.start >= previousEnd &&
        range.start < range.end &&
        range.end <= text.length) {
      valid.add(range);
      previousEnd = range.end;
    }
  }
  return valid;
}

/// Ajusta las marcas después de que el texto pasó de [before] a [after].
///
/// 1. La zona editada es lo que queda entre el prefijo y el sufijo comunes.
/// 2. Una marca antes de la zona no cambia; una marca después se desplaza; una marca
///    que se superpone con la zona (o en la que se escribió dentro) se elimina.
/// 3. Si una marca quedó pegada a la zona y ahí se escribió una letra o un número, la
///    palabra cambió («se le pegaron letras») y su marca también se elimina.
List<TextRange> adjustRanges(
  String before,
  String after,
  List<TextRange> ranges,
) {
  if (ranges.isEmpty || before == after) return ranges;

  // 1. Prefijo y sufijo comunes.
  final shorter = math.min(before.length, after.length);
  var prefix = 0;
  while (prefix < shorter &&
      before.codeUnitAt(prefix) == after.codeUnitAt(prefix)) {
    prefix++;
  }
  var suffix = 0;
  while (suffix < shorter - prefix &&
      before.codeUnitAt(before.length - 1 - suffix) ==
          after.codeUnitAt(after.length - 1 - suffix)) {
    suffix++;
  }
  final removedEnd =
      before.length - suffix; // fin de la zona en el texto anterior
  final insertedEnd = after.length - suffix; // fin de la zona en el texto nuevo
  final shift = after.length - before.length;

  final adjusted = <TextRange>[];
  for (final range in ranges) {
    // 2. Antes, después o dentro de la zona editada.
    final TextRange moved;
    if (range.end <= prefix) {
      moved = range;
    } else if (range.start >= removedEnd) {
      moved = TextRange(start: range.start + shift, end: range.end + shift);
    } else {
      continue; // se editó la palabra: su marca desaparece [EX-H1-E4]
    }
    // 3. Letras pegadas al final o al principio de la palabra.
    if (moved.end == prefix && _isLetterOrDigitAt(after, moved.end)) continue;
    if (moved.start == insertedEnd &&
        _isLetterOrDigitAt(after, moved.start - 1)) {
      continue;
    }
    adjusted.add(moved);
  }
  return adjusted;
}

final _letterOrDigit = RegExp(r'[\p{L}\p{N}]', unicode: true);

bool _isLetterOrDigitAt(String text, int index) {
  if (index < 0 || index >= text.length) return false;
  return _letterOrDigit.hasMatch(text[index]);
}
