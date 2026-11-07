// Pruebas de la pantalla «Mis documentos» (tareas T606, T608 y T610; spec 007).

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:handtext_ai/models/export_format.dart';
import 'package:handtext_ai/models/history_entry.dart';

import '../support/strings_es.dart';
import '../support/app_tester.dart';
import '../support/fakes.dart';

final _newer = HistoryEntry(
  id: 'doc-2',
  title: 'Apuntes de biología',
  text: 'Apuntes de biología\nLa célula es la unidad básica',
  formats: {ExportFormat.docx, ExportFormat.pdf},
  savedAt: DateTime(2026, 10, 29, 15, 30),
);
final _older = HistoryEntry(
  id: 'doc-1',
  title: 'Guía de la semana',
  text: 'Guía de la semana\nEjercicios',
  formats: {ExportFormat.pdf},
  savedAt: DateTime(2026, 10, 20, 9, 5),
);

/// Arnés con dos documentos guardados (el más reciente primero).
TestHarness _withHistory() =>
    TestHarness()..historyStore.stored = [_newer, _older];

Future<void> _openHistory(WidgetTester tester) =>
    tapText(tester, es.historyTitle);

void main() {
  testWidgets('[HD-H1-E4] sin documentos, un mensaje lo explica', (
    tester,
  ) async {
    await pumpHandTextApp(tester, TestHarness());
    await scrollToText(tester, es.historyCount(0));
    expect(find.text(es.historyCount(0)), findsOneWidget);

    await _openHistory(tester);

    expect(find.text(es.historyEmptyTitle), findsOneWidget);
    expect(find.byTooltip(es.historyClearAll), findsNothing);
  });

  testWidgets(
    '[HD-H1-E1] [HD-H1-E4] lista con título, fecha, formatos y palabras',
    (tester) async {
      await pumpHandTextApp(tester, _withHistory());
      await scrollToText(tester, es.historyCount(2));
      expect(find.text(es.historyCount(2)), findsOneWidget);

      await _openHistory(tester);

      expect(
        find.text('29 oct 2026, 15:30 · Word y PDF · 9 palabras'),
        findsOneWidget,
      );
      expect(
        find.text('20 oct 2026, 09:05 · PDF · 5 palabras'),
        findsOneWidget,
      );
      // El más reciente va primero.
      expect(
        tester.getTopLeft(find.text(_newer.title)).dy,
        lessThan(tester.getTopLeft(find.text(_older.title)).dy),
      );
    },
  );

  testWidgets('[HD-H1-E1] guardar un documento lo agrega a la lista', (
    tester,
  ) async {
    final h = TestHarness();
    await pumpHandTextApp(tester, h);
    await tapText(tester, es.pickFromGallery);
    await tapText(tester, es.acceptAndRecognize);
    await tapText(tester, es.consentAccept);
    await tapText(tester, es.export);
    await tapText(tester, es.wordOption);
    expect(h.controller.history.entries, hasLength(1));

    await tester.tap(find.byTooltip(es.moreActionsTooltip));
    await tester.pumpAndSettle();
    await tapText(tester, es.processAnotherImage);
    await tapText(tester, es.replaceTextConfirm);

    await scrollToText(tester, es.historyCount(1));
    expect(find.text(es.historyCount(1)), findsOneWidget);
  });

  testWidgets('[HD-H2-E1] tocar un documento lo abre en el editor', (
    tester,
  ) async {
    final h = _withHistory();
    await pumpHandTextApp(tester, h);
    await _openHistory(tester);

    await tapText(tester, _older.title);

    expect(find.text(es.editorTitle), findsOneWidget);
    expect(h.controller.documentText, _older.text);
    expect(find.text(es.statusText(h.controller.status!)), findsOneWidget);
  });

  testWidgets(
    '[HD-H2-E2] con cambios sin exportar pide confirmación; cancelar no cambia nada',
    (tester) async {
      final h = _withHistory();
      await pumpHandTextApp(tester, h);
      await tapText(tester, es.pickFromGallery);
      await tapText(tester, es.acceptAndRecognize);
      await tapText(tester, es.consentAccept);
      final current = h.controller.documentText;
      await tester.tap(find.byTooltip(es.moreActionsTooltip));
      await tester.pumpAndSettle();
      await tapText(tester, es.processAnotherImage);
      await tapText(tester, es.replaceTextConfirm);
      await _openHistory(tester);

      await tapText(tester, _older.title);
      expect(find.text(es.historyOpenTitle), findsOneWidget);
      await tapText(tester, es.cancel);
      expect(h.controller.documentText, current);
      expect(find.text(es.historyTitle), findsOneWidget);

      await tapText(tester, _older.title);
      await tapText(tester, es.historyOpenConfirm);
      expect(h.controller.documentText, _older.text);
      expect(find.text(es.editorTitle), findsOneWidget);
    },
  );

  testWidgets('[HD-H3-E1] [HD-H3-E3] eliminar un documento, con confirmación', (
    tester,
  ) async {
    final h = _withHistory();
    await pumpHandTextApp(tester, h);
    await _openHistory(tester);

    await tester.tap(find.byTooltip(es.historyDelete(_newer.title)));
    await tester.pumpAndSettle();
    await tapText(tester, es.cancel);
    expect(find.text(_newer.title), findsOneWidget); // cancelar no borra

    await tester.tap(find.byTooltip(es.historyDelete(_newer.title)));
    await tester.pumpAndSettle();
    await tapText(tester, es.historyDeleteConfirm);

    expect(find.text(_newer.title), findsNothing);
    expect(h.historyStore.stored.map((entry) => entry.id), [_older.id]);
  });

  testWidgets('[HD-H3-E2] «Borrar todo» vacía la lista, con confirmación', (
    tester,
  ) async {
    final h = _withHistory();
    await pumpHandTextApp(tester, h);
    await _openHistory(tester);

    await tester.tap(find.byTooltip(es.historyClearAll));
    await tester.pumpAndSettle();
    expect(find.text(es.historyClearMessage(2)), findsOneWidget);
    await tapText(tester, es.historyClearConfirm);

    expect(find.text(es.historyEmptyTitle), findsOneWidget);
    expect(h.historyStore.deletes, 1);
  });

  testWidgets('[HD-H3-E4] eliminar la cuenta borra el historial', (
    tester,
  ) async {
    final h = _withHistory();
    await pumpHandTextApp(tester, h);

    await tester.tap(find.byTooltip(es.accountTooltip));
    await tester.pumpAndSettle();
    await tapText(tester, es.deleteAccount);
    await enterField(tester, es.passwordLabel, 'clave-segura-1');
    await tapText(tester, es.deleteAccountConfirm);

    expect(h.historyStore.deletes, 1);
    expect(h.historyStore.stored, isEmpty);
  });

  testWidgets('[HD-H1-E5] cerrar sesión conserva el historial', (tester) async {
    final h = _withHistory();
    await pumpHandTextApp(tester, h);

    await tester.tap(find.byTooltip(es.accountTooltip));
    await tester.pumpAndSettle();
    await tapText(tester, es.signOut);

    expect(find.text(es.haveAccount), findsOneWidget);
    expect(h.historyStore.stored, hasLength(2));
  });

  testWidgets('la lista cumple las guías de accesibilidad de 006', (
    tester,
  ) async {
    for (final scale in [1.0, 2.0]) {
      tester.platformDispatcher.textScaleFactorTestValue = scale;
      final handle = tester.ensureSemantics();
      await pumpHandTextApp(tester, _withHistory());
      await _openHistory(tester);

      for (final guideline in [
        labeledTapTargetGuideline,
        androidTapTargetGuideline,
      ]) {
        final result = await guideline.evaluate(tester);
        expect(result.passed, isTrue, reason: '$scale: ${result.reason}');
      }
      handle.dispose();
      await tester.pumpWidget(const SizedBox());
    }
    tester.platformDispatcher.clearTextScaleFactorTestValue();
  });
}
