// Pruebas del nombre propuesto al guardar (tarea T901; spec 010, Historia 1; research.md
// de 010, R1).

import 'package:flutter_test/flutter_test.dart';
import 'package:handtext_ai/models/export_format.dart';
import 'package:handtext_ai/state/document_flow_controller.dart';

final _moment = DateTime(2026, 11, 5, 15, 30);

void main() {
  test('[OR-H1-E1] el título del documento es el nombre del archivo', () {
    expect(
      suggestedFileName(
        ExportFormat.docx,
        _moment,
        title: 'Apuntes de biología',
      ),
      'Apuntes de biología.docx',
    );
  });

  test(
    '[OR-H1-E2] [SC-1001] se quitan los caracteres que Android no acepta',
    () {
      expect(
        suggestedFileName(
          ExportFormat.pdf,
          _moment,
          title: 'Tema 1: ¿qué es la célula?',
        ),
        'Tema 1 ¿qué es la célula.pdf',
      );
      expect(
        suggestedFileName(
          ExportFormat.pdf,
          _moment,
          title:
              r'a/b\c*d"e<f>g|h'
              '\t'
              'i...',
        ),
        'abcdefgh i.pdf',
      );
    },
  );

  test(
    '[SC-1001] el nombre mide como máximo 60 caracteres más la extensión',
    () {
      final name = suggestedFileName(
        ExportFormat.docx,
        _moment,
        title: 'á' * 80,
      );

      expect(name, endsWith('.docx'));
      expect(name.replaceAll('.docx', '').runes.length, 60);
    },
  );

  test('[OR-H1-E3] sin un título útil, el nombre de siempre', () {
    for (final title in [null, '', '   ', '???', ':/*']) {
      expect(
        suggestedFileName(ExportFormat.docx, _moment, title: title),
        'HandText_20261105_1530.docx',
      );
    }
  });
}
