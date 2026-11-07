// Pruebas de pantallas de la funcionalidad 003 (tareas T210, T213 y T216).
//
// Barra de revisión de palabras dudosas, «Recortar o girar» en la vista previa y
// «Compartir» en el aviso de éxito, con servicios falsos y animaciones reducidas.

import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:handtext_ai/models/recognition_result.dart';
import 'package:handtext_ai/services/image_rules.dart';
import 'package:image_picker/image_picker.dart';

import '../support/strings_es.dart';
import '../support/app_tester.dart';
import '../support/fakes.dart';

const _text = 'la celula es la unidad';
const _celula = TextRange(start: 3, end: 9);
const _unidad = TextRange(start: 16, end: 22);

/// Abre la app y llega al editor con dos palabras dudosas.
Future<TestHarness> _editorWithMarks(WidgetTester tester) async {
  final h = TestHarness();
  h.api.recognitionResult = const RecognitionResult(
    hasText: true,
    text: _text,
    uncertainRanges: [_celula, _unidad],
  );
  await pumpHandTextApp(tester, h);
  await tapText(tester, es.pickFromGallery);
  await tapText(tester, es.acceptAndRecognize);
  await tapText(tester, es.consentAccept);
  return h;
}

TextSelection _selection(WidgetTester tester) =>
    tester.widget<TextField>(find.byType(TextField)).controller!.selection;

void main() {
  group('palabras dudosas (Historia 1)', () {
    testWidgets(
      '[EX-H1-E1] [EX-H1-E3] la barra cuenta las marcas y «Siguiente» '
      'recorre las palabras',
      (tester) async {
        await _editorWithMarks(tester);

        expect(find.text(es.uncertainWordsCount(2)), findsOneWidget);

        await tapText(tester, es.nextUncertainWord);
        expect(_selection(tester), _selectionOf(_celula));

        await tapText(tester, es.nextUncertainWord);
        expect(_selection(tester), _selectionOf(_unidad));

        await tapText(tester, es.nextUncertainWord); // vuelve a la primera
        expect(_selection(tester), _selectionOf(_celula));
      },
    );

    testWidgets(
      '[EX-H1-E5] [EX-H1-E9] «Está bien» quita la marca y, sin marcas, '
      'la barra desaparece',
      (tester) async {
        final h = await _editorWithMarks(tester);

        await tapText(tester, es.nextUncertainWord);
        await tapText(tester, es.acceptUncertainWord);
        expect(find.text(es.uncertainWordsCount(1)), findsOneWidget);

        await tapText(tester, es.nextUncertainWord);
        await tapText(tester, es.acceptUncertainWord);

        expect(find.text(es.nextUncertainWord), findsNothing);
        expect(h.controller.documentText, _text); // el texto no cambió
      },
    );

    testWidgets('[EX-H1-E4] al corregir una palabra, el contador baja', (
      tester,
    ) async {
      await _editorWithMarks(tester);

      await tester.enterText(find.byType(TextField), 'la célula es la unidad');
      await tester.pumpAndSettle();

      expect(find.text(es.uncertainWordsCount(1)), findsOneWidget);
    });

    testWidgets('sin palabras dudosas no hay barra de revisión', (
      tester,
    ) async {
      final h = TestHarness();
      await pumpHandTextApp(tester, h);
      await tapText(tester, es.pickFromGallery);
      await tapText(tester, es.acceptAndRecognize);
      await tapText(tester, es.consentAccept);

      expect(find.text(es.nextUncertainWord), findsNothing);
    });
  });

  testWidgets(
    '[EX-H2-E1] [EX-H2-E5] «Recortar o girar» y luego «Usar la imagen '
    'original»',
    (tester) async {
      final cropped = Uint8List.fromList([0xFF, 0xD8, 0xFF, 1, 2, 3]);
      final h = TestHarness(
        readDimensions: (bytes) async => bytes.length == cropped.length
            ? const ImageDimensions(900, 700)
            : const ImageDimensions(1200, 1600),
      );
      h.imageEditor.result = XFile.fromData(cropped, name: 'r.jpg');
      await pumpHandTextApp(tester, h);
      await tapText(tester, es.pickFromGallery);
      expect(find.text(es.restoreOriginalImage), findsNothing);

      await tapText(tester, es.editImage);

      expect(find.textContaining('900 × 700 px'), findsOneWidget);
      await tapText(tester, es.restoreOriginalImage);
      expect(find.textContaining('1200 × 1600 px'), findsOneWidget);
      expect(find.text(es.restoreOriginalImage), findsNothing);
    },
  );

  testWidgets('[EX-H3-E1] [EX-H3-E2] el aviso de guardado ofrece «Compartir»', (
    tester,
  ) async {
    final h = TestHarness();
    await pumpHandTextApp(tester, h);
    await tapText(tester, es.pickFromGallery);
    await tapText(tester, es.acceptAndRecognize);
    await tapText(tester, es.consentAccept);

    await tapText(tester, es.export);
    await tapText(tester, es.pdfOption);
    await tapText(tester, es.share);

    expect(h.sharer.shared.single.$2, h.fileSaver.savedNames.single);
  });
}

TextSelection _selectionOf(TextRange range) =>
    TextSelection(baseOffset: range.start, extentOffset: range.end);
