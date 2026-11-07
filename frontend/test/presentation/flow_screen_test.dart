// Pruebas de las pantallas y diálogos del flujo (tareas T026 y T135).
//
// Simulan toques reales sobre la interfaz, con servicios falsos (sin cámara, red ni
// archivos) y una sesión ya iniciada (spec 002). Cada prueba indica el escenario del
// spec que verifica.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:handtext_ai/models/export_format.dart';
import 'package:handtext_ai/services/camera_permission_service.dart';

import '../support/strings_es.dart';
import '../support/app_tester.dart';
import '../support/fakes.dart';

Future<TestHarness> _pumpApp(
  WidgetTester tester, [
  TestHarness? harness,
]) async {
  final h = harness ?? TestHarness();
  await pumpHandTextApp(tester, h);
  return h;
}

/// Toca un texto visible y espera a que termine la animación.
Future<void> _tap(WidgetTester tester, String text) => tapText(tester, text);

/// Lleva la app hasta el editor autorizando el envío.
Future<void> _goToEditor(WidgetTester tester) async {
  await _tap(tester, es.pickFromGallery);
  await _tap(tester, es.acceptAndRecognize);
  await _tap(tester, es.consentAccept);
}

Future<void> _openMenuItem(WidgetTester tester, String item) async {
  await tester.tap(find.byTooltip(es.moreActionsTooltip));
  await tester.pumpAndSettle();
  await _tap(tester, item);
}

void main() {
  testWidgets(
    '[ED-H1-E1] el inicio ofrece las tres formas de obtener el documento',
    (tester) async {
      await _pumpApp(tester);

      expect(
        find.text(es.scanDocument),
        findsOneWidget,
      ); // primera opción (spec 009)
      expect(find.text(es.takePhoto), findsOneWidget);
      expect(find.text(es.pickFromGallery), findsOneWidget);
      expect(
        tester.getTopLeft(find.text(es.scanDocument)).dy,
        lessThan(tester.getTopLeft(find.text(es.takePhoto)).dy),
      );
      await scrollToText(tester, es.imageRequirements);
      expect(find.text(es.imageRequirements), findsOneWidget);
    },
  );

  testWidgets('[H1-E3] [H1-E4] sin autorización la imagen no se envía', (
    tester,
  ) async {
    final h = await _pumpApp(tester);

    await _tap(tester, es.pickFromGallery);
    await _tap(tester, es.acceptAndRecognize);
    expect(find.text(es.consentTitle), findsOneWidget);
    await _tap(tester, es.consentDecline);

    expect(h.api.recognizedImages, isEmpty);
    expect(find.textContaining('No se envió la imagen'), findsOneWidget);
    expect(find.text(es.acceptAndRecognize), findsOneWidget);
  });

  testWidgets(
    '[H1-E6] con autorización, el editor muestra el texto y la advertencia',
    (tester) async {
      final h = await _pumpApp(tester);

      await _goToEditor(tester);

      expect(h.api.recognizedImages, hasLength(1));
      expect(find.text(es.editorTitle), findsOneWidget);
      expect(find.text(es.recognitionWarning), findsOneWidget);
      expect(find.text('Texto reconocido'), findsOneWidget);
    },
  );

  testWidgets('[H1-E10] exportar un texto vacío explica el motivo', (
    tester,
  ) async {
    final h = await _pumpApp(tester);
    await _goToEditor(tester);

    await tester.enterText(find.byType(TextField), '   ');
    await tester.pumpAndSettle();
    await _tap(tester, es.export);
    await _tap(tester, es.wordOption);

    expect(h.api.exports, isEmpty);
    expect(
      find.textContaining('No se puede exportar un texto vacío'),
      findsOneWidget,
    );
  });

  testWidgets(
    '[H1-E9] [H3-E1] exporta el texto corregido en el formato elegido',
    (tester) async {
      final h = await _pumpApp(tester);
      await _goToEditor(tester);

      await tester.enterText(find.byType(TextField), 'Texto corregido');
      await tester.pumpAndSettle();
      await _tap(tester, es.export);
      expect(find.text(es.wordOption), findsOneWidget);
      expect(find.text(es.pdfOption), findsOneWidget);
      await _tap(tester, es.wordOption);

      expect(h.api.exports.single, ('Texto corregido', ExportFormat.docx));
      expect(
        find.text('El archivo Word se guardó correctamente.'),
        findsOneWidget,
      );
    },
  );

  testWidgets(
    '[H1-E13] procesar otra imagen pide confirmación y conserva el texto',
    (tester) async {
      await _pumpApp(tester);
      await _goToEditor(tester);

      await _openMenuItem(tester, es.processAnotherImage);
      expect(find.text(es.replaceTextTitle), findsOneWidget);
      await _tap(tester, es.cancel);
      expect(
        find.text('Texto reconocido'),
        findsOneWidget,
      ); // sigue en el editor

      await _openMenuItem(tester, es.processAnotherImage);
      await _tap(tester, es.replaceTextConfirm);
      expect(find.text(es.takePhoto), findsOneWidget); // inicio
      await _tap(tester, es.backToCurrentText);
      expect(find.text('Texto reconocido'), findsOneWidget);
    },
  );

  testWidgets('[H1-E17] descartar pide confirmación y elimina el borrador', (
    tester,
  ) async {
    final h = await _pumpApp(tester);
    await _goToEditor(tester);
    expect(h.drafts.stored, 'Texto reconocido');

    await _openMenuItem(tester, es.discardText);
    await _tap(tester, es.discardConfirm);

    expect(find.text(es.takePhoto), findsOneWidget);
    expect(find.text('El texto se descartó.'), findsOneWidget);
    expect(h.drafts.stored, isNull);
  });

  testWidgets('[H1-E15] al abrir la app se recupera el borrador', (
    tester,
  ) async {
    final h = TestHarness()..drafts.stored = 'Borrador sin exportar';

    await _pumpApp(tester, h);

    expect(find.text(es.editorTitle), findsOneWidget);
    expect(find.text('Borrador sin exportar'), findsOneWidget);
    expect(
      find.text('Se recuperó el texto que estaba editando.'),
      findsOneWidget,
    );
  });

  testWidgets('[H2-E2] sin permiso de cámara se explica el motivo', (
    tester,
  ) async {
    final h = TestHarness();
    h.cameraPermission.result = CameraPermission.denied;
    await _pumpApp(tester, h);

    await _tap(tester, es.takePhoto);

    expect(h.imageSource.cameraCalls, 0);
    expect(
      find.textContaining('Se necesita el permiso de cámara'),
      findsOneWidget,
    );
  });
}
