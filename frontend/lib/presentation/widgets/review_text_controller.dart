// Controlador del texto del editor que pinta las palabras dudosas (tarea T210; spec
// 003, módulo 1; research.md de 003, R4).
//
// Es un TextEditingController normal (el texto sigue siendo editable) que, al dibujar,
// resalta las marcas con fondo ámbar y subrayado ondulado [EX-H1-E1] [SC-306]. Las
// marcas no forman parte del texto: solo cambian cómo se ve [EX-H1-E6].
// Las marcas las decide DocumentFlowController; este controlador solo las lee.

import 'package:flutter/material.dart';

import '../../services/uncertain_ranges.dart';
import '../../theme/aurora.dart';

/// Controlador del campo de texto del editor que pinta las palabras dudosas.
class ReviewTextController extends TextEditingController {
  ReviewTextController({super.text, required this.uncertainRanges});

  /// Devuelve las marcas actuales del documento.
  final List<TextRange> Function() uncertainRanges;

  @override
  TextSpan buildTextSpan({
    required BuildContext context,
    TextStyle? style,
    required bool withComposing,
  }) {
    final ranges = validRanges(text, uncertainRanges());
    if (ranges.isEmpty) {
      return super.buildTextSpan(
        context: context,
        style: style,
        withComposing: withComposing,
      );
    }

    final dark = Theme.of(context).brightness == Brightness.dark;
    final marked = TextStyle(
      backgroundColor: dark
          ? Aurora.uncertainFillDark
          : Aurora.uncertainFillLight,
      decoration: TextDecoration.underline,
      decorationStyle: TextDecorationStyle.wavy,
      decorationColor: dark
          ? Aurora.uncertainUnderlineDark
          : Aurora.uncertainUnderlineLight,
    );
    // El teclado subraya la palabra que está componiendo; se respeta ese subrayado.
    final composing = withComposing && value.isComposingRangeValid
        ? value.composing
        : null;

    // Se corta el texto en cada borde de una marca o de la composición, y cada
    // trozo recibe su estilo.
    final cuts = <int>{
      0,
      text.length,
      for (final range in ranges) ...[range.start, range.end],
      if (composing != null) ...[composing.start, composing.end],
    }.toList()..sort();
    final children = <TextSpan>[];
    for (var i = 0; i < cuts.length - 1; i++) {
      final start = cuts[i];
      final end = cuts[i + 1];
      final isMarked = ranges.any((r) => r.start <= start && end <= r.end);
      final isComposing =
          composing != null && composing.start <= start && end <= composing.end;
      TextStyle? pieceStyle = isMarked ? marked : null;
      if (isComposing) {
        pieceStyle = (pieceStyle ?? const TextStyle()).merge(
          const TextStyle(decoration: TextDecoration.underline),
        );
      }
      children.add(
        TextSpan(text: text.substring(start, end), style: pieceStyle),
      );
    }
    return TextSpan(style: style, children: children);
  }
}
