// Pruebas de accesibilidad (tareas T506 y T510; spec 006, Historias 2 y 3;
// research.md de 006, R4).
//
// Recorre todas las pantallas, menús, hojas y diálogos de la app con la letra normal y
// con la letra del sistema al 200 %. En cada uno comprueba con las guías de Flutter:
// - que todo lo que se puede tocar tiene un nombre para TalkBack [SC-602];
// - que mide al menos 48 × 48 dp [SC-603].
// Un desborde (contenido cortado) hace fallar la prueba por sí solo [SC-604].

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:handtext_ai/models/app_settings.dart';
import 'package:handtext_ai/models/recognition_result.dart';

import '../support/strings_es.dart';
import '../support/app_tester.dart';
import '../support/fakes.dart';

/// Texto reconocido con una palabra dudosa («célula», de 3 a 9).
const _recognized = RecognitionResult(
  hasText: true,
  text: 'La célula es la unidad básica de la vida.',
  uncertainRanges: [TextRange(start: 3, end: 9)],
);

/// Evalúa las dos guías en la pantalla actual; [where] dice cuál, si algo falla.
Future<void> _expectAccessible(WidgetTester tester, String where) async {
  for (final guideline in [
    labeledTapTargetGuideline, // [SC-602]
    androidTapTargetGuideline, // [SC-603]
  ]) {
    final result = await guideline.evaluate(tester);
    expect(result.passed, isTrue, reason: '$where: ${result.reason}');
  }
}

/// Toca el ícono con [tooltip] y espera.
Future<void> _tapTooltip(WidgetTester tester, String tooltip) async {
  await tester.tap(find.byTooltip(tooltip));
  await tester.pumpAndSettle();
}

/// Captura lo que la app pide a TalkBack que lea (anuncios de accesibilidad).
List<String> _captureAnnouncements(WidgetTester tester) {
  final announcements = <String>[];
  final messenger = tester.binding.defaultBinaryMessenger;
  messenger.setMockDecodedMessageHandler<Object?>(
    SystemChannels.accessibility,
    (message) async {
      final data = (message! as Map)['data'] as Map;
      if (data['message'] case final String text) announcements.add(text);
      return null;
    },
  );
  addTearDown(
    () => messenger.setMockDecodedMessageHandler<Object?>(
      SystemChannels.accessibility,
      null,
    ),
  );
  return announcements;
}

void main() {
  for (final scale in [1.0, 2.0]) {
    testWidgets(
      '[PA-H2-E1] [PA-H3-E1] [PA-H3-E3] todas las pantallas con la letra al '
      '${(scale * 100).round()} %',
      (tester) async {
        tester.platformDispatcher.textScaleFactorTestValue = scale;
        addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
        final handle = tester.ensureSemantics();
        final h = TestHarness(signedIn: false)
          ..settingsStore.stored = const AppSettings(); // con los consejos
        h.imageSource.galleryResults = [
          pickedFile(fakePngBytes()),
          pickedFile(fakePngBytes()),
        ];
        h.api.recognitionResult = _recognized;
        await pumpHandTextApp(tester, h);

        // Sin sesión: bienvenida, registro, ingreso y «Acerca de».
        await _expectAccessible(tester, 'bienvenida');
        await tapText(tester, es.createAccount);
        await _expectAccessible(tester, 'registro');
        await _tapTooltip(tester, es.back);
        await tapText(tester, es.haveAccount);
        await _expectAccessible(tester, 'ingreso');
        await enterField(tester, es.emailLabel, 'ana@correo.com');
        await enterField(tester, es.passwordLabel, 'clave-segura-1');
        await tapText(tester, es.signIn);

        // Consejos (primera vez) e inicio.
        await _expectAccessible(tester, 'consejos');
        await tapText(tester, es.tipsSkip);
        await _expectAccessible(tester, 'inicio');

        // Vista previa con dos páginas, hoja para agregar y autorización.
        await tapText(tester, es.pickFromGallery);
        await _expectAccessible(tester, 'vista previa');
        await tester.tap(find.bySemanticsLabel(es.addPage));
        await tester.pumpAndSettle();
        await _expectAccessible(tester, 'hoja agregar página');
        await tester.tapAt(const Offset(20, 20)); // cierra la hoja
        await tester.pumpAndSettle();
        await tapText(tester, es.recognizePages(2));
        await _expectAccessible(tester, 'autorización');
        await tapText(tester, es.consentAccept);

        // Editor con aviso de estado y palabra dudosa.
        await _expectAccessible(tester, 'editor');
        await tapText(tester, es.export);
        await _expectAccessible(tester, 'hoja exportar');
        await tester.tapAt(const Offset(20, 20));
        await tester.pumpAndSettle();
        await _tapTooltip(tester, es.moreActionsTooltip);
        await _expectAccessible(tester, 'menú del editor');
        await tapText(tester, es.processAnotherImage);
        await _expectAccessible(tester, 'diálogo procesar otra imagen');
        await tapText(tester, es.cancel);
        await _tapTooltip(tester, es.moreActionsTooltip);
        await tapText(tester, es.discardText);
        await _expectAccessible(tester, 'diálogo descartar');
        await tapText(tester, es.cancel);

        // Menú de la cuenta, Ajustes, «Acerca de» y Privacidad.
        await _tapTooltip(tester, es.accountTooltip);
        await _expectAccessible(tester, 'menú de la cuenta');
        await tapText(tester, es.settingsTitle);
        await _expectAccessible(tester, 'ajustes');
        await _tapTooltip(tester, es.back);
        await _tapTooltip(tester, es.accountTooltip);
        await tapText(tester, es.aboutTitle);
        await _expectAccessible(tester, 'acerca de');
        await tapText(tester, es.privacyTitle);
        await _expectAccessible(tester, 'privacidad');
        await _tapTooltip(tester, es.back);
        await _tapTooltip(tester, es.back);

        // Diálogos de la cuenta.
        await _tapTooltip(tester, es.accountTooltip);
        await tapText(tester, es.signOut);
        await _expectAccessible(tester, 'diálogo cerrar sesión');
        await tapText(tester, es.cancel);
        await _tapTooltip(tester, es.accountTooltip);
        await tapText(tester, es.deleteAccount);
        await _expectAccessible(tester, 'diálogo eliminar cuenta');
        await tapText(tester, es.cancel);
        handle.dispose();
      },
    );
  }

  testWidgets('[PA-H3-E2] con la letra al 200 %, el editor conserva el texto y '
      '«Exportar» a la vista', (tester) async {
    tester.platformDispatcher.textScaleFactorTestValue = 2.0;
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    final h = TestHarness()..api.recognitionResult = _recognized;
    await pumpHandTextApp(tester, h);
    await tapText(tester, es.pickFromGallery);
    await tapText(tester, es.acceptAndRecognize);
    await tapText(tester, es.consentAccept);

    // Hay aviso de estado y barra de revisión, y aun así el campo tiene espacio.
    expect(find.text(es.uncertainWordsCount(1)), findsOneWidget);
    expect(tester.getSize(find.byType(TextField)).height, greaterThan(150));
    expect(find.text(es.export).hitTestable(), findsOneWidget);
    await tester.enterText(find.byType(TextField), 'Texto corregido');
    expect(h.controller.documentText, 'Texto corregido');
  });

  testWidgets('[PA-H2-E1] TalkBack lee «Cuenta», no la inicial del avatar', (
    tester,
  ) async {
    final handle = tester.ensureSemantics();
    await pumpHandTextApp(tester, TestHarness());

    // La auditoría inicial encontró un nodo que se leía «A» (research.md, R9).
    expect(find.bySemanticsLabel(testUser.initial), findsNothing);
    // Regresión (verificación en el emulador): el botón es un nodo propio; no absorbe
    // el saludo ni el título de al lado ni se vuelve encabezado.
    expect(
      tester.getSemantics(find.byTooltip(es.accountTooltip)),
      containsSemantics(
        tooltip: es.accountTooltip,
        label: '',
        hasTapAction: true,
        isHeader: false,
      ),
    );
    handle.dispose();
  });

  testWidgets('[PA-H2-E2] [SC-605] los avisos de estado se leen solos', (
    tester,
  ) async {
    final handle = tester.ensureSemantics();
    final h = TestHarness()..api.recognitionResult = _recognized;
    await pumpHandTextApp(tester, h);
    await tapText(tester, es.pickFromGallery);
    await tapText(tester, es.acceptAndRecognize);
    await tapText(tester, es.consentAccept);

    final status = h.controller.status!;
    expect(
      tester.getSemantics(find.text(es.statusText(status))),
      containsSemantics(isLiveRegion: true),
    );
    handle.dispose();
  });

  testWidgets('[PA-H2-E3] [SC-605] «Siguiente» hace leer la palabra dudosa', (
    tester,
  ) async {
    final announcements = _captureAnnouncements(tester);
    final h = TestHarness()..api.recognitionResult = _recognized;
    await pumpHandTextApp(tester, h);
    await tapText(tester, es.pickFromGallery);
    await tapText(tester, es.acceptAndRecognize);
    await tapText(tester, es.consentAccept);

    await tapText(tester, es.nextUncertainWord);

    expect(announcements, [es.uncertainWordAnnouncement('célula')]);
  });

  testWidgets('[PA-H2-E5] el título de cada pantalla es un encabezado', (
    tester,
  ) async {
    final handle = tester.ensureSemantics();
    // Un encabezado es un nodo propio y no se puede tocar (no se mezcla con un botón).
    Matcher header() => containsSemantics(isHeader: true, hasTapAction: false);
    final h = TestHarness(signedIn: false)..api.recognitionResult = _recognized;
    await pumpHandTextApp(tester, h);
    expect(tester.getSemantics(find.text(es.appName)), header());

    await tapText(tester, es.createAccount);
    expect(tester.getSemantics(find.text(es.registerTitle)), header());
    await _tapTooltip(tester, es.back);
    await tapText(tester, es.haveAccount);
    expect(tester.getSemantics(find.text(es.loginTitle)), header());
    await enterField(tester, es.emailLabel, 'ana@correo.com');
    await enterField(tester, es.passwordLabel, 'clave-segura-1');
    await tapText(tester, es.signIn);

    expect(tester.getSemantics(find.text(es.startHeadline)), header());
    await tapText(tester, es.pickFromGallery);
    expect(tester.getSemantics(find.text(es.previewTitle)), header());
    await tapText(tester, es.acceptAndRecognize);
    await tapText(tester, es.consentAccept);
    expect(tester.getSemantics(find.text(es.editorTitle)), header());

    await _tapTooltip(tester, es.accountTooltip);
    await tapText(tester, es.settingsTitle);
    expect(tester.getSemantics(find.text(es.settingsTitle)), header());
    handle.dispose();
  });
}
