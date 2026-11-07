// Pruebas de la app en inglés (tareas T705, T708 y T709; spec 008; research.md de 008,
// R7).

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:handtext_ai/models/app_failure.dart';
import 'package:handtext_ai/models/app_settings.dart';
import 'package:handtext_ai/models/export_format.dart';
import 'package:handtext_ai/models/history_entry.dart';
import 'package:handtext_ai/models/recognition_result.dart';
import 'package:handtext_ai/presentation/strings.dart';

import '../support/app_tester.dart';
import '../support/fakes.dart';
import '../support/strings_es.dart';

/// Letras que el inglés de la app nunca usa (R7).
final _spanishLetters = RegExp('[¿¡áéíóúñÁÉÍÓÚÑ]');

/// Textos que sí pueden tenerlas con la app en inglés: los datos de la persona y el
/// nombre del idioma «Español».
final _allowed = [testUser.displayName, AppStrings.spanishName];

/// Frases (de 10 caracteres o más) de un archivo de textos: las cadenas contiguas se
/// unen y se cortan donde hay datos (`$page`, `${…}`).
Set<String> _phrasesOf(String path) {
  final source = File(path)
      .readAsLinesSync()
      .where((line) => !line.trimLeft().startsWith('//'))
      .join('\n');
  // Cadenas con comillas simples o dobles («Don't» va entre dobles).
  const one =
      r"'(?:[^'\\]|\\.)*'"
      '|'
      r'"(?:[^"\\]|\\.)*"';
  final literal = RegExp(one);
  final adjacent = RegExp('(?:$one)(?:\\s*(?:$one))*');
  return {
    for (final group in adjacent.allMatches(source))
      for (final piece
          in literal
              .allMatches(group.group(0)!)
              .map((m) => m.group(0)!.substring(1, m.group(0)!.length - 1))
              .join()
              .split(RegExp(r'\$\{[^}]*\}|\$\w+')))
        if (piece.trim().length >= 10) piece.trim(),
  };
}

/// Frases del español que no están en el inglés: si una se ve con la app en inglés,
/// falta una traducción o una pantalla no usa context.strings.
final _spanishPhrases = _phrasesOf(
  'lib/presentation/strings_es.dart',
).difference(_phrasesOf('lib/presentation/strings_en.dart'));

/// [SC-802] Ningún texto visible de la app está en español. El texto del documento
/// está en el campo del editor y no se revisa.
void _expectNoSpanish(WidgetTester tester, String where) {
  final spanish = tester
      .widgetList<RichText>(find.byType(RichText))
      .map((widget) => widget.text.toPlainText())
      .where(
        (text) =>
            (text.contains(_spanishLetters) &&
                !_allowed.any((allowed) => text.contains(allowed))) ||
            _spanishPhrases.any(text.contains),
      )
      .toList();
  expect(spanish, isEmpty, reason: 'Texto en español en «$where»');
}

const _recognized = RecognitionResult(
  hasText: true,
  text: 'La célula es la unidad básica de la vida.',
  uncertainRanges: [TextRange(start: 3, end: 9)],
);

Future<void> _tapTooltip(WidgetTester tester, String tooltip) async {
  await tester.tap(find.byTooltip(tooltip));
  await tester.pumpAndSettle();
}

/// Specs 009 y 010: en inglés [SC-802] y con las guías de toque de 006 [SC-602]
/// [SC-603]. Los desbordes a 200 % hacen fallar la prueba solos [SC-805].
Future<void> _expectEnglishAndAccessible(
  WidgetTester tester,
  String where,
) async {
  _expectNoSpanish(tester, where);
  for (final guideline in [
    labeledTapTargetGuideline,
    androidTapTargetGuideline,
  ]) {
    final result = await guideline.evaluate(tester);
    expect(result.passed, isTrue, reason: '$where: ${result.reason}');
  }
}

void main() {
  group('Historia 1: elegir el idioma', () {
    testWidgets('[IE-H1-E1] recién instalada, la app está en español', (
      tester,
    ) async {
      await pumpHandTextApp(tester, TestHarness(signedIn: false));

      expect(find.text(es.createAccount), findsOneWidget);
      expect(find.text(AppStrings.spanishName), findsOneWidget); // el botón
    });

    testWidgets(
      '[IE-H1-E2] en Ajustes, «English» cambia toda la app al instante',
      (tester) async {
        final h = TestHarness();
        await pumpHandTextApp(tester, h);
        await _tapTooltip(tester, es.accountTooltip);
        await tapText(tester, es.settingsTitle);

        await tapText(tester, AppStrings.englishName);

        expect(find.text(en.settingsTitle), findsOneWidget);
        expect(h.settingsStore.stored.language, AppLanguage.english);
        await _tapTooltip(tester, en.back);
        expect(find.text(en.takePhoto), findsOneWidget);
      },
    );

    testWidgets(
      '[IE-H1-E2] en la bienvenida, el botón de idioma abre la hoja',
      (tester) async {
        final h = TestHarness(signedIn: false);
        await pumpHandTextApp(tester, h);

        await _tapTooltip(tester, es.languageTooltip);
        expect(find.text(es.languageSection), findsOneWidget);
        await tapText(tester, AppStrings.englishName);

        expect(find.text(en.createAccount), findsOneWidget);
        expect(find.text(AppStrings.englishName), findsOneWidget); // el botón
        expect(h.settingsStore.stored.language, AppLanguage.english);
      },
    );

    for (final (phone, expected) in [
      (const Locale('en', 'US'), 'en'),
      (const Locale('es', 'CO'), 'es'),
      (const Locale('fr', 'FR'), 'es'),
    ]) {
      testWidgets(
        '[IE-H1-E3] «Automático» con el teléfono en ${phone.toLanguageTag()}: '
        '$expected',
        (tester) async {
          tester.platformDispatcher.localesTestValue = [phone];
          addTearDown(tester.platformDispatcher.clearLocalesTestValue);
          final h = TestHarness(signedIn: false)
            ..settingsStore.stored = const AppSettings(
              tipsSeen: true,
              language: AppLanguage.system,
            );

          await pumpHandTextApp(tester, h);

          final strings = expected == 'en' ? en : es;
          expect(find.text(strings.createAccount), findsOneWidget);
        },
      );
    }

    testWidgets('[IE-H1-E4] [SC-804] el idioma se conserva al abrir la app', (
      tester,
    ) async {
      final h = TestHarness()
        ..settingsStore.stored = const AppSettings(
          tipsSeen: true,
          language: AppLanguage.english,
        );

      await pumpHandTextApp(tester, h);

      expect(find.text(en.startHeadline), findsOneWidget);
    });
  });

  group('Historia 2: toda la app en inglés', () {
    for (final scale in [1.0, 2.0]) {
      testWidgets(
        '[IE-H2-E1] [IE-H2-E5] [SC-802] [SC-805] ninguna pantalla en español, '
        'con la letra al ${(scale * 100).round()} %',
        (tester) async {
          tester.platformDispatcher.textScaleFactorTestValue = scale;
          addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
          final h = TestHarness(signedIn: false)
            ..settingsStore.stored = const AppSettings(
              language: AppLanguage.english, // con los consejos
            );
          h.imageSource.galleryResults = [
            pickedFile(fakePngBytes()),
            pickedFile(fakePngBytes()),
          ];
          h.api.recognitionResult = _recognized;
          await pumpHandTextApp(tester, h);

          _expectNoSpanish(tester, 'bienvenida');
          await tapText(tester, en.createAccount);
          _expectNoSpanish(tester, 'registro');
          await _tapTooltip(tester, en.back);
          await tapText(tester, en.haveAccount);
          _expectNoSpanish(tester, 'ingreso');
          await enterField(tester, en.emailLabel, 'ana@correo.com');
          await enterField(tester, en.passwordLabel, 'clave-segura-1');
          await tapText(tester, en.signIn);

          _expectNoSpanish(tester, 'consejos');
          await tapText(tester, en.tipsSkip);
          _expectNoSpanish(tester, 'inicio');
          await tapText(tester, en.historyTitle);
          _expectNoSpanish(tester, 'mis documentos');
          await _tapTooltip(tester, en.back);

          await tapText(tester, en.pickFromGallery);
          _expectNoSpanish(tester, 'vista previa');
          await tester.tap(find.bySemanticsLabel(en.addPage));
          await tester.pumpAndSettle();
          _expectNoSpanish(tester, 'hoja agregar página');
          await tester.tapAt(const Offset(20, 20));
          await tester.pumpAndSettle();
          await tapText(tester, en.recognizePages(2));
          _expectNoSpanish(tester, 'autorización');
          await tapText(tester, en.consentAccept);

          _expectNoSpanish(tester, 'editor');
          await tapText(tester, en.export);
          _expectNoSpanish(tester, 'hoja exportar');
          await tester.tapAt(const Offset(20, 20));
          await tester.pumpAndSettle();
          await _tapTooltip(tester, en.moreActionsTooltip);
          _expectNoSpanish(tester, 'menú del editor');
          await tapText(tester, en.processAnotherImage);
          _expectNoSpanish(tester, 'diálogo procesar otra imagen');
          await tapText(tester, en.cancel);
          await _tapTooltip(tester, en.moreActionsTooltip);
          await tapText(tester, en.discardText);
          _expectNoSpanish(tester, 'diálogo descartar');
          await tapText(tester, en.cancel);

          await _tapTooltip(tester, en.accountTooltip);
          _expectNoSpanish(tester, 'menú de la cuenta');
          await tapText(tester, en.settingsTitle);
          _expectNoSpanish(tester, 'ajustes');
          await _tapTooltip(tester, en.back);
          await _tapTooltip(tester, en.accountTooltip);
          await tapText(tester, en.aboutTitle);
          _expectNoSpanish(tester, 'acerca de');
          await tapText(tester, en.privacyTitle);
          _expectNoSpanish(tester, 'privacidad');
          await _tapTooltip(tester, en.back);
          await _tapTooltip(tester, en.back);

          await _tapTooltip(tester, en.accountTooltip);
          await tapText(tester, en.signOut);
          _expectNoSpanish(tester, 'diálogo cerrar sesión');
          await tapText(tester, en.cancel);
          await _tapTooltip(tester, en.accountTooltip);
          await tapText(tester, en.deleteAccount);
          _expectNoSpanish(tester, 'diálogo eliminar cuenta');
          await tapText(tester, en.cancel);
        },
      );
    }

    testWidgets('[IE-H2-E2] los fallos se explican en inglés', (tester) async {
      final h = TestHarness()
        ..settingsStore.stored = const AppSettings(
          tipsSeen: true,
          language: AppLanguage.english,
        );
      h.api.recognitionError = const AppFailure(FailureKind.noConnection);
      await pumpHandTextApp(tester, h);

      await tapText(tester, en.pickFromGallery);
      await tapText(tester, en.acceptAndRecognize);
      await tapText(tester, en.consentAccept);

      expect(
        find.text(en.failureText(const AppFailure(FailureKind.noConnection))),
        findsOneWidget,
      );
      _expectNoSpanish(tester, 'fallo');
    });

    test(
      '[IE-H2-E2] el detalle en español de la API no se muestra en inglés',
      () {
        const failure = AppFailure(
          FailureKind.unsupportedCharacters,
          detail: 'El texto contiene caracteres no admitidos: ✓',
        );

        expect(es.failureText(failure), failure.detail);
        expect(en.failureText(failure), isNot(contains('caracteres')));
      },
    );

    testWidgets(
      '[IE-H2-E3] los títulos del diálogo para guardar y del recorte',
      (tester) async {
        final h = TestHarness()
          ..settingsStore.stored = const AppSettings(
            tipsSeen: true,
            language: AppLanguage.english,
          );
        await pumpHandTextApp(tester, h);
        expect(AppStrings.current.saveDialogTitle, en.saveDialogTitle);
        expect(AppStrings.current.imageEditorTitle, en.imageEditorTitle);

        await h.settings.setLanguage(AppLanguage.spanish);
        await tester.pumpAndSettle();
        expect(AppStrings.current.saveDialogTitle, es.saveDialogTitle);
      },
    );

    test('[IE-H2-E4] fechas y tamaños en el formato de cada idioma', () {
      final moment = DateTime(2026, 10, 29, 15, 30);
      const bytes = 2516582; // 2,4 MB

      expect(en.shortDate(moment), 'Oct 29, 2026, 15:30');
      expect(es.shortDate(moment), '29 oct 2026, 15:30');
      expect(en.formatBytes(bytes), '2.4 MB');
      expect(es.formatBytes(bytes), '2,4 MB');
    });
  });

  group('Historia 3: el texto de la persona no cambia', () {
    testWidgets(
      '[IE-H3-E1] [IE-H3-E2] [SC-803] cambiar el idioma no toca el texto, sus '
      'marcas ni lo que se exporta',
      (tester) async {
        final h = TestHarness()..api.recognitionResult = _recognized;
        await pumpHandTextApp(tester, h);
        await tapText(tester, es.pickFromGallery);
        await tapText(tester, es.acceptAndRecognize);
        await tapText(tester, es.consentAccept);
        await tester.enterText(
          find.byType(TextField),
          '${_recognized.text} Fin',
        );
        await tester.pumpAndSettle();
        final text = h.controller.documentText;
        final marks = h.controller.uncertainRanges;
        final draft = h.drafts.stored;

        await h.settings.setLanguage(AppLanguage.english);
        await tester.pumpAndSettle();

        expect(find.text(en.editorTitle), findsOneWidget);
        expect(h.controller.documentText, text);
        expect(h.controller.uncertainRanges, marks);
        expect(h.drafts.stored, draft);
        expect(
          tester.widget<TextField>(find.byType(TextField)).controller!.text,
          text,
        );

        await tapText(tester, en.export);
        await tapText(tester, en.wordOption);
        expect(h.api.exports.single, (text, ExportFormat.docx));
      },
    );
  });

  // T808 y T907: lo que el recorrido de arriba no alcanza. El aviso del escáner (009)
  // solo aparece si falla, y la búsqueda y «Renombrar» (010), si hay documentos.
  group('Specs 009 y 010 en inglés', () {
    for (final scale in [1.0, 2.0]) {
      testWidgets(
        '[ED-H2-E1] [OR-H3-E1] [OR-H3-E3] aviso del escáner, búsqueda y '
        '«Renombrar», con la letra al ${(scale * 100).round()} %',
        (tester) async {
          tester.platformDispatcher.textScaleFactorTestValue = scale;
          addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
          final handle = tester.ensureSemantics();
          const title = 'Notes on cells';
          final h = TestHarness()
            ..settingsStore.stored = const AppSettings(
              tipsSeen: true,
              language: AppLanguage.english,
            )
            ..historyStore.stored = [
              HistoryEntry(
                id: 'doc-1',
                title: title,
                text: '$title\nThe cell is the basic unit of life.',
                formats: {ExportFormat.docx},
                savedAt: DateTime(2026, 11, 4, 10),
              ),
            ];
          h.scanner.error = const AppFailure(FailureKind.scannerUnavailable);
          await pumpHandTextApp(tester, h);

          await tapText(tester, en.scanDocument);
          expect(find.text(en.takePhoto), findsWidgets); // el botón del aviso
          await _expectEnglishAndAccessible(tester, 'scanner unavailable');

          await tapText(tester, en.historyTitle);
          await _expectEnglishAndAccessible(tester, 'My documents');

          await tester.enterText(find.byType(TextField), 'zzz');
          await tester.pumpAndSettle();
          expect(find.text(en.historyNoResults('zzz')), findsOneWidget);
          await _expectEnglishAndAccessible(tester, 'no results');

          await tester.enterText(find.byType(TextField), '');
          await tester.pumpAndSettle();
          await _tapTooltip(tester, en.historyRename(title));
          expect(find.text(en.historyRenameTitle), findsOneWidget);
          await _expectEnglishAndAccessible(tester, 'Rename');

          handle.dispose();
        },
      );
    }
  });
}
