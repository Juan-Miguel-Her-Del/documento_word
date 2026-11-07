// Pruebas de las pantallas de Ajustes y «Acerca de» (tareas T405 y T406; spec 005).
// Spec 006: opciones de Ajustes con la letra grande [PA-H3-E1].

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:handtext_ai/config/app_config.dart';
import 'package:handtext_ai/models/app_settings.dart';

import '../support/strings_es.dart';
import '../support/app_tester.dart';
import '../support/fakes.dart';

/// Abre el menú de la cuenta (el avatar) y toca [item].
Future<void> _openFromAccountMenu(WidgetTester tester, String item) async {
  await tester.tap(find.byTooltip(es.accountTooltip));
  await tester.pumpAndSettle();
  await tapText(tester, item);
}

ThemeMode _themeMode(WidgetTester tester) =>
    tester.widget<MaterialApp>(find.byType(MaterialApp)).themeMode!;

void main() {
  testWidgets(
    '[AV-H1-E1] [AV-H1-E2] el menú abre Ajustes y el tema se aplica',
    (tester) async {
      final h = TestHarness();
      await pumpHandTextApp(tester, h);
      expect(_themeMode(tester), ThemeMode.system); // [AV-H1-E3] por omisión

      await _openFromAccountMenu(tester, es.settingsTitle);
      await tapText(tester, es.themeDark);

      expect(_themeMode(tester), ThemeMode.dark);
      expect(h.settingsStore.stored.theme, ThemePreference.dark);
    },
  );

  testWidgets('[AV-H1-E4] la letra grande agranda el texto del editor', (
    tester,
  ) async {
    final h = TestHarness();
    await pumpHandTextApp(tester, h);
    await tapText(tester, es.pickFromGallery);
    await tapText(tester, es.acceptAndRecognize);
    await tapText(tester, es.consentAccept);
    final normal = tester
        .widget<TextField>(find.byType(TextField))
        .style!
        .fontSize!;

    await h.settings.setTextSize(EditorTextSize.extraLarge);
    await tester.pumpAndSettle();

    final large = tester
        .widget<TextField>(find.byType(TextField))
        .style!
        .fontSize!;
    expect(large, closeTo(normal * 1.4, 0.01));
  });

  testWidgets('[AV-H2-E1] [AV-H2-E2] «Acerca de» se abre desde la bienvenida', (
    tester,
  ) async {
    await pumpHandTextApp(tester, TestHarness(signedIn: false));

    await tapText(tester, es.privacyAndAbout);

    expect(
      find.text(es.version(AppConfig.appVersion, AppConfig.appBuild)),
      findsOneWidget,
    );
  });

  testWidgets('[AV-H2-E3] [AV-H2-E4] privacidad y licencias', (tester) async {
    await pumpHandTextApp(tester, TestHarness());
    await _openFromAccountMenu(tester, es.aboutTitle);

    await tapText(tester, es.privacyTitle);
    // La lista solo construye lo visible: se desplaza hasta cada sección.
    for (final (title, _) in es.privacySections) {
      await tester.scrollUntilVisible(
        find.text(title),
        200,
        scrollable: find.byType(Scrollable).last,
      );
      expect(find.text(title), findsOneWidget);
    }
    await tester.tap(find.byTooltip(es.back));
    await tester.pumpAndSettle();

    await tapText(tester, es.licensesTitle);
    expect(find.byType(LicensePage), findsOneWidget);
  });

  for (final (scale, segmented) in [(1.0, true), (2.0, false)]) {
    testWidgets(
      '[PA-H3-E1] opciones de Ajustes con la letra al ${(scale * 100).round()} %: '
      '${segmented ? 'botones segmentados' : 'una debajo de otra'}',
      (tester) async {
        tester.platformDispatcher.textScaleFactorTestValue = scale;
        addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
        final handle = tester.ensureSemantics();
        await loadPoppins(tester); // medidas como en el teléfono
        final h = TestHarness();
        await pumpHandTextApp(tester, h);
        await _openFromAccountMenu(tester, es.settingsTitle);

        // Con la letra grande, los segmentos partían palabras («Autom-ático»).
        expect(
          find.byType(SegmentedButton<ThemePreference>),
          segmented ? findsOneWidget : findsNothing,
        );
        await tapText(tester, es.themeDark);
        expect(h.settingsStore.stored.theme, ThemePreference.dark);
        if (!segmented) {
          expect(
            tester.getSemantics(find.text(es.themeDark)),
            containsSemantics(
              isInMutuallyExclusiveGroup: true,
              isChecked: true,
            ),
          );
        }
        handle.dispose();
      },
    );
  }
}
