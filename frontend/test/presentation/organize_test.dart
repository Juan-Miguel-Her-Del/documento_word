// Pruebas de organizar documentos (tareas T903 a T906; spec 010).

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:handtext_ai/models/export_format.dart';
import 'package:handtext_ai/models/history_entry.dart';
import 'package:handtext_ai/state/document_history.dart';

import '../support/app_tester.dart';
import '../support/fakes.dart';
import '../support/strings_es.dart';

final _biology = HistoryEntry(
  id: 'doc-2',
  title: 'Apuntes de biología',
  text: 'Apuntes de biología\nLa CÉLULA es la unidad básica',
  formats: {ExportFormat.docx},
  savedAt: DateTime(2026, 11, 4, 10, 0),
);
final _guide = HistoryEntry(
  id: 'doc-1',
  title: 'Guía de la semana',
  text: 'Guía de la semana\nEjercicios de fracciones',
  formats: {ExportFormat.pdf},
  savedAt: DateTime(2026, 11, 3, 9, 0),
);

TestHarness _withHistory() =>
    TestHarness()..historyStore.stored = [_biology, _guide];

/// Captura lo que la app copia al portapapeles.
List<String> _captureClipboard(WidgetTester tester) {
  final copied = <String>[];
  tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
    SystemChannels.platform,
    (call) async {
      if (call.method == 'Clipboard.setData') {
        copied.add((call.arguments as Map)['text'] as String);
      }
      return null;
    },
  );
  addTearDown(
    () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.platform,
      null,
    ),
  );
  return copied;
}

Future<void> _reachEditor(WidgetTester tester, TestHarness h) async {
  await tapText(tester, es.pickFromGallery);
  await tapText(tester, es.acceptAndRecognize);
  await tapText(tester, es.consentAccept);
}

Future<void> _openMenu(WidgetTester tester) async {
  await tester.tap(find.byTooltip(es.moreActionsTooltip));
  await tester.pumpAndSettle();
}

void main() {
  group('Historia 1: nombre del archivo', () {
    testWidgets('[OR-H1-E1] el diálogo para guardar propone el título', (
      tester,
    ) async {
      final h = TestHarness();
      await pumpHandTextApp(tester, h);
      await _reachEditor(tester, h);

      await tapText(tester, es.export);
      await tapText(tester, es.wordOption);

      // El arnés reconoce «Texto reconocido».
      expect(h.fileSaver.savedNames.single, 'Texto reconocido.docx');
    });

    test('[OR-H1-E4] un documento renombrado propone su nombre', () async {
      final h = TestHarness()..historyStore.stored = [_guide];
      await h.controller.initialize();
      await h.controller.history.rename(_guide.id, 'Fracciones 5.º');
      await h.controller.openFromHistory(h.controller.history.entries.single);

      await h.controller.export(ExportFormat.pdf);

      expect(h.fileSaver.savedNames.single, 'Fracciones 5.º.pdf');
    });
  });

  group('Historia 2: copiar todo el texto', () {
    testWidgets('[OR-H2-E1] [SC-1002] copia exactamente el texto del editor', (
      tester,
    ) async {
      final copied = _captureClipboard(tester);
      final h = TestHarness();
      await pumpHandTextApp(tester, h);
      await _reachEditor(tester, h);
      await tester.enterText(find.byType(TextField), 'Línea 1\n\nLínea 2 ✓');
      await tester.pumpAndSettle();

      await _openMenu(tester);
      await tapText(tester, es.copyAllText);

      expect(copied, ['Línea 1\n\nLínea 2 ✓']);
      expect(find.text(es.textCopied), findsOneWidget);
    });

    testWidgets('[OR-H2-E2] con el texto vacío no se ofrece', (tester) async {
      final h = TestHarness();
      await pumpHandTextApp(tester, h);
      await _reachEditor(tester, h);
      await tester.enterText(find.byType(TextField), '   ');
      await tester.pumpAndSettle();

      await _openMenu(tester);

      expect(find.text(es.copyAllText), findsNothing);
      expect(find.text(es.processAnotherImage), findsOneWidget);
    });
  });

  group('Historia 3: buscar y renombrar', () {
    test('[OR-H3-E1] [SC-1003] buscar ignora mayúsculas y tildes', () {
      expect(_biology.matchesQuery('celula'), isTrue); // texto con «CÉLULA»
      expect(_biology.matchesQuery('BIOLOGIA'), isTrue); // título con tilde
      expect(_guide.matchesQuery('guia'), isTrue);
      expect(_guide.matchesQuery('célula'), isFalse);
      expect(_guide.matchesQuery('  '), isTrue); // vacía: todos
    });

    testWidgets('[OR-H3-E1] [OR-H3-E2] la lista se filtra y avisa si no hay', (
      tester,
    ) async {
      await pumpHandTextApp(tester, _withHistory());
      await tapText(tester, es.historyTitle);

      await tester.enterText(find.byType(TextField), 'celula');
      await tester.pumpAndSettle();
      expect(find.text(_biology.title), findsOneWidget);
      expect(find.text(_guide.title), findsNothing);

      await tester.enterText(find.byType(TextField), 'química');
      await tester.pumpAndSettle();
      expect(find.text(es.historyNoResults('química')), findsOneWidget);

      await tester.enterText(find.byType(TextField), '');
      await tester.pumpAndSettle();
      expect(find.text(_guide.title), findsOneWidget);
    });

    testWidgets('[OR-H3-E3] renombrar cambia el título; cancelar no', (
      tester,
    ) async {
      final h = _withHistory();
      await pumpHandTextApp(tester, h);
      await tapText(tester, es.historyTitle);

      await tester.tap(find.byTooltip(es.historyRename(_guide.title)));
      await tester.pumpAndSettle();
      await tapText(tester, es.cancel);
      expect(find.text(_guide.title), findsOneWidget);

      await tester.tap(find.byTooltip(es.historyRename(_guide.title)));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.widgetWithText(TextField, es.historyRenameLabel),
        '  Fracciones  ',
      );
      await tapText(tester, es.historyRenameConfirm);

      expect(find.text('Fracciones'), findsOneWidget);
      final stored = h.historyStore.stored.firstWhere((e) => e.id == _guide.id);
      expect(stored.title, 'Fracciones');
      expect(stored.text, _guide.text); // [SC-1004] el texto no cambia
    });

    testWidgets('un nombre vacío no se acepta', (tester) async {
      await pumpHandTextApp(tester, _withHistory());
      await tapText(tester, es.historyTitle);
      await tester.tap(find.byTooltip(es.historyRename(_guide.title)));
      await tester.pumpAndSettle();

      await tester.enterText(
        find.widgetWithText(TextField, es.historyRenameLabel),
        '   ',
      );
      await tester.pumpAndSettle();

      final save = tester.widget<FilledButton>(
        find.widgetWithText(FilledButton, es.historyRenameConfirm),
      );
      expect(save.onPressed, isNull);
    });

    test(
      '[OR-H3-E4] [SC-1004] el nombre se conserva al volver a guardar',
      () async {
        final store = InMemoryHistoryStore()..stored = [_guide];
        final history = DocumentHistory(store: store);
        await history.load();
        await history.rename(_guide.id, 'Fracciones');

        await history.record(
          id: _guide.id,
          text: 'Otra primera línea\nEjercicios corregidos',
          format: ExportFormat.docx,
          savedAt: DateTime(2026, 11, 5),
        );

        expect(history.entries.single.title, 'Fracciones');
        expect(store.stored.single.renamed, isTrue);
      },
    );
  });
}
