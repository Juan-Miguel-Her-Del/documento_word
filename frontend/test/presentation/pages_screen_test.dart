// Pruebas de la vista previa con varias páginas (tarea T309; spec 004).

import 'package:flutter_test/flutter_test.dart';
import 'package:image_picker/image_picker.dart';

import '../support/strings_es.dart';
import '../support/app_tester.dart';
import '../support/fakes.dart';

XFile _file(int n) =>
    XFile.fromData(fakePngBytes()..[20] = n, name: 'pagina_$n.png');

/// Abre la app y elige [count] imágenes de la galería.
Future<TestHarness> _previewWith(WidgetTester tester, int count) async {
  final h = TestHarness();
  h.imageSource.galleryResults = [for (var n = 1; n <= count; n++) _file(n)];
  await pumpHandTextApp(tester, h);
  await tapText(tester, es.pickFromGallery);
  return h;
}

void main() {
  testWidgets('[VP-H1-E1] la vista previa muestra las páginas numeradas', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    await _previewWith(tester, 3);

    expect(find.bySemanticsLabel(es.pageThumbnail(1, true)), findsOne);
    expect(find.bySemanticsLabel(es.pageThumbnail(3, false)), findsOne);
    expect(find.textContaining(es.pageOf(1, 3)), findsWidgets);
    expect(find.text(es.recognizePages(3)), findsOneWidget);
    semantics.dispose();
  });

  testWidgets(
    '[VP-H2-E1] [VP-H2-E2] [VP-H2-E3] elegir, mover y quitar páginas',
    (tester) async {
      final semantics = tester.ensureSemantics();
      final h = await _previewWith(tester, 3);

      await tester.tap(find.bySemanticsLabel(es.pageThumbnail(3, false)));
      await tester.pumpAndSettle();
      expect(h.controller.selectedPageIndex, 2);

      await tester.tap(find.byTooltip(es.movePageBefore));
      await tester.pumpAndSettle();
      expect(
        [for (final p in h.controller.pages) p.image.bytes[20]],
        [1, 3, 2],
      );

      await tester.tap(find.byTooltip(es.removePage));
      await tester.pumpAndSettle();
      expect(h.controller.pages, hasLength(2));
      expect(find.text(es.recognizePages(2)), findsOneWidget);
      semantics.dispose();
    },
  );

  testWidgets('[VP-H2-E5] con una sola página no hay mover ni quitar', (
    tester,
  ) async {
    await _previewWith(tester, 1);

    expect(find.byTooltip(es.removePage), findsNothing);
    expect(find.byTooltip(es.movePageAfter), findsNothing);
    expect(find.text(es.acceptAndRecognize), findsOneWidget);
  });

  testWidgets('[VP-H1-E3] la autorización dice cuántas imágenes se envían', (
    tester,
  ) async {
    await _previewWith(tester, 3);

    await tapText(tester, es.recognizePages(3));

    expect(find.text(es.consentTitleFor(3)), findsOneWidget);
    await tapText(tester, es.consentAccept);
    expect(find.text(es.editorTitle), findsOneWidget);
  });

  testWidgets('[VP-H1-E2] «Agregar página» desde la galería', (tester) async {
    final semantics = tester.ensureSemantics();
    final h = await _previewWith(tester, 2);
    h.imageSource.galleryResults = [_file(3)];

    await tester.tap(find.bySemanticsLabel(es.addPage));
    await tester.pumpAndSettle();
    await tapText(tester, es.addPageFromGallery);

    expect(h.controller.pages, hasLength(3));
    expect(find.text(es.recognizePages(3)), findsOneWidget);
    semantics.dispose();
  });
}
