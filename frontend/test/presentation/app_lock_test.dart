// Pruebas del bloqueo con huella o rostro (tareas T1002, T1004 y T1006; spec 011).

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:handtext_ai/models/app_settings.dart';
import 'package:handtext_ai/models/export_format.dart';
import 'package:handtext_ai/models/history_entry.dart';
import 'package:handtext_ai/services/settings_store.dart';

import '../support/app_tester.dart';
import '../support/fakes.dart';
import '../support/strings_es.dart';

/// Arnés con el bloqueo activo (y los consejos ya vistos).
TestHarness _locked({bool signedIn = true}) =>
    TestHarness(signedIn: signedIn)
      ..settingsStore.stored = const AppSettings(tipsSeen: true, appLock: true);

Future<void> _openSettings(WidgetTester tester) async {
  await tester.tap(find.byTooltip(es.accountTooltip));
  await tester.pumpAndSettle();
  await tapText(tester, es.settingsTitle);
  await scrollToText(tester, es.appLockTitle);
}

SwitchListTile _lockSwitch(WidgetTester tester) =>
    tester.widget<SwitchListTile>(
      find.widgetWithText(SwitchListTile, es.appLockTitle),
    );

Future<void> _goToBackground(
  WidgetTester tester,
  Duration away,
  TestHarness h,
) async {
  // El orden real de Android: al volver también pasa por «hidden», y eso no debe
  // reiniciar la cuenta del minuto.
  void go(List<AppLifecycleState> states) {
    for (final state in states) {
      tester.binding.handleAppLifecycleStateChanged(state);
    }
  }

  go(const [
    AppLifecycleState.inactive,
    AppLifecycleState.hidden,
    AppLifecycleState.paused,
  ]);
  h.clock = h.clock.add(away);
  go(const [
    AppLifecycleState.hidden,
    AppLifecycleState.inactive,
    AppLifecycleState.resumed,
  ]);
  await tester.pumpAndSettle();
}

void main() {
  group('Historia 1: activar el bloqueo', () {
    test(
      '[BL-H1-E1] [SC-1104] apagado por omisión y en ajustes anteriores',
      () {
        expect(const AppSettings().appLock, isFalse);
        expect(decodeSettings('{"theme": "dark"}').appLock, isFalse);
        expect(decodeSettings('{"appLock": "sí"}').appLock, isFalse);
        expect(
          decodeSettings(
            encodeSettings(const AppSettings(appLock: true)),
          ).appLock,
          isTrue,
        );
      },
    );

    testWidgets('[BL-H1-E2] activarlo pide la verificación y se guarda', (
      tester,
    ) async {
      final h = TestHarness();
      await pumpHandTextApp(tester, h);
      await _openSettings(tester);
      expect(_lockSwitch(tester).value, isFalse);

      await tester.tap(find.text(es.appLockTitle));
      await tester.pumpAndSettle();

      expect(h.authenticator.calls, 1);
      expect(h.settingsStore.stored.appLock, isTrue);
      expect(_lockSwitch(tester).value, isTrue);
      // La persona está presente: activarlo no bloquea en ese momento.
      expect(find.text(es.lockedTitle), findsNothing);
    });

    testWidgets('[BL-H1-E3] si se cancela la verificación, sigue apagado', (
      tester,
    ) async {
      final h = TestHarness();
      h.authenticator.result = false;
      await pumpHandTextApp(tester, h);
      await _openSettings(tester);

      await tester.tap(find.text(es.appLockTitle));
      await tester.pumpAndSettle();

      expect(h.settingsStore.stored.appLock, isFalse);
      expect(_lockSwitch(tester).value, isFalse);
    });

    testWidgets('[BL-H1-E4] sin huella ni bloqueo de pantalla, lo explica', (
      tester,
    ) async {
      final h = TestHarness();
      h.authenticator.available = false;
      await pumpHandTextApp(tester, h);
      await _openSettings(tester);

      expect(find.text(es.appLockUnavailable), findsOneWidget);
      expect(_lockSwitch(tester).onChanged, isNull);
    });
  });

  group('Historia 2: abrir la app bloqueada', () {
    testWidgets(
      '[BL-H2-E1] [SC-1101] abre bloqueada y no se ve ningún documento',
      (tester) async {
        final h = _locked();
        h.authenticator.result = false; // la persona cancela el cuadro
        await pumpHandTextApp(tester, h);

        expect(find.text(es.lockedTitle), findsOneWidget);
        expect(find.text(es.takePhoto), findsNothing);
        expect(h.authenticator.calls, 1); // se pidió sola al aparecer
      },
    );

    testWidgets(
      '[BL-H2-E2] [SC-1103] desbloquear muestra la app con el borrador intacto',
      (tester) async {
        final h = _locked();
        h.drafts.stored = 'Texto en edición';
        h.authenticator.result = false;
        await pumpHandTextApp(tester, h);

        h.authenticator.result = true;
        await tapText(tester, es.unlock);

        expect(find.text(es.lockedTitle), findsNothing);
        expect(find.text(es.editorTitle), findsOneWidget);
        expect(h.controller.documentText, 'Texto en edición');
      },
    );

    testWidgets(
      '[BL-H2-E3] [SC-1102] si falla, sigue bloqueada y se reintenta',
      (tester) async {
        final h = _locked();
        h.authenticator.result = false;
        await pumpHandTextApp(tester, h);

        await tapText(tester, es.unlock);

        expect(find.text(es.lockedTitle), findsOneWidget);
        expect(find.text(es.takePhoto), findsNothing);
        expect(h.authenticator.calls, 2);
      },
    );

    testWidgets('[BL-H2-E4] se bloquea al volver después de más de 1 minuto', (
      tester,
    ) async {
      final h = _locked();
      await pumpHandTextApp(tester, h); // se desbloquea sola (result = true)
      expect(find.text(es.takePhoto), findsOneWidget);
      h.authenticator.result = false;

      await _goToBackground(tester, const Duration(seconds: 30), h);
      expect(find.text(es.lockedTitle), findsNothing); // menos de 1 minuto

      await _goToBackground(tester, const Duration(seconds: 61), h);
      expect(find.text(es.lockedTitle), findsOneWidget);
      expect(find.text(es.takePhoto), findsNothing);
    });

    testWidgets(
      '[BL-H2-E4] [SC-1101] también tapa las pantallas abiertas encima (R4)',
      (tester) async {
        const title = 'Notas de los estudiantes';
        final h = _locked()
          ..historyStore.stored = [
            HistoryEntry(
              id: 'doc-1',
              title: title,
              text: '$title\nAna: 4,5',
              formats: {ExportFormat.docx},
              savedAt: DateTime(2026, 11, 4, 10),
            ),
          ];
        await pumpHandTextApp(tester, h); // se desbloquea sola
        await tapText(tester, es.historyTitle); // una ruta encima del inicio
        expect(find.text(title), findsOneWidget);

        h.authenticator.result = false;
        await _goToBackground(tester, const Duration(seconds: 61), h);
        expect(find.text(es.lockedTitle), findsOneWidget);
        expect(find.text(title), findsNothing); // Mis documentos queda tapado

        h.authenticator.result = true;
        await tapText(tester, es.unlock);
        expect(find.text(title), findsOneWidget); // sigue donde estaba
      },
    );

    testWidgets('[BL-H2-E5] sin sesión, la bienvenida no se bloquea', (
      tester,
    ) async {
      final h = _locked(signedIn: false);
      await pumpHandTextApp(tester, h);

      expect(find.text(es.createAccount), findsOneWidget);
      expect(find.text(es.lockedTitle), findsNothing);

      // Quien ingresa con su contraseña ya se verificó.
      await tapText(tester, es.haveAccount);
      await enterField(tester, es.emailLabel, 'ana@correo.com');
      await enterField(tester, es.passwordLabel, 'clave-segura-1');
      await tapText(tester, es.signIn);
      expect(find.text(es.lockedTitle), findsNothing);
      expect(h.authenticator.calls, 0);
    });
  });

  group('Historia 3: desactivar', () {
    testWidgets('[BL-H3-E1] apagarlo deja de bloquear la app', (tester) async {
      final h = _locked();
      await pumpHandTextApp(tester, h); // se desbloquea sola
      await _openSettings(tester);

      await tester.tap(find.text(es.appLockTitle));
      await tester.pumpAndSettle();
      expect(h.settingsStore.stored.appLock, isFalse);

      h.authenticator.result = false;
      await _goToBackground(tester, const Duration(minutes: 5), h);
      expect(find.text(es.lockedTitle), findsNothing);
    });
  });

  testWidgets(
    'la pantalla de bloqueo cumple las guías de 006 y está en inglés (008)',
    (tester) async {
      for (final scale in [1.0, 2.0]) {
        tester.platformDispatcher.textScaleFactorTestValue = scale;
        final handle = tester.ensureSemantics();
        final h = TestHarness()
          ..settingsStore.stored = const AppSettings(
            tipsSeen: true,
            appLock: true,
            language: AppLanguage.english,
          );
        h.authenticator.result = false;
        await pumpHandTextApp(tester, h);

        expect(find.text(en.lockedTitle), findsOneWidget);
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
    },
  );
}
