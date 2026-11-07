// Pruebas de los consejos para una buena foto (tarea T503; spec 006, Historia 1).

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:handtext_ai/models/app_settings.dart';
import 'package:handtext_ai/models/user_account.dart';

import '../support/strings_es.dart';
import '../support/app_tester.dart';
import '../support/fakes.dart';

/// Arnés en un teléfono donde nunca se vieron los consejos.
TestHarness _firstTime({bool signedIn = true}) =>
    TestHarness(signedIn: signedIn)..settingsStore.stored = const AppSettings();

final _count = es.tips.length;

void _expectTip(int index) {
  expect(find.text(es.tipOf(index + 1, _count)), findsOneWidget);
  expect(find.text(es.tips[index].$1), findsOneWidget);
}

void main() {
  testWidgets(
    '[PA-H1-E1] la primera vez se ven los consejos antes del inicio',
    (tester) async {
      await pumpHandTextApp(tester, _firstTime());

      _expectTip(0);
      expect(find.text(es.takePhoto), findsNothing);
    },
  );

  testWidgets(
    '[PA-H1-E2] «Siguiente» recorre los consejos y «Empezar» termina',
    (tester) async {
      final h = _firstTime();
      await pumpHandTextApp(tester, h);

      for (var index = 1; index < _count; index++) {
        await tapText(tester, es.tipsNext);
        _expectTip(index);
      }
      expect(find.text(es.tipsNext), findsNothing);
      await tapText(tester, es.tipsStart);

      expect(find.text(es.takePhoto), findsOneWidget);
      expect(h.settingsStore.stored.tipsSeen, isTrue); // [SC-601]
    },
  );

  testWidgets('[PA-H1-E3] «Saltar» lleva al inicio', (tester) async {
    final h = _firstTime();
    await pumpHandTextApp(tester, h);

    await tapText(tester, es.tipsSkip);

    expect(find.text(es.takePhoto), findsOneWidget);
    expect(h.settingsStore.stored.tipsSeen, isTrue);
  });

  testWidgets(
    '[PA-H1-E3] el botón atrás también los salta, sin cerrar la app',
    (tester) async {
      final h = _firstTime();
      await pumpHandTextApp(tester, h);

      await tester.binding.handlePopRoute(); // botón atrás de Android
      await tester.pumpAndSettle();

      expect(find.text(es.takePhoto), findsOneWidget);
      expect(h.settingsStore.stored.tipsSeen, isTrue);
    },
  );

  testWidgets(
    '[PA-H1-E4] [SC-601] no vuelven a aparecer al abrir la app ni con otra cuenta',
    (tester) async {
      final h = _firstTime();
      await pumpHandTextApp(tester, h);
      await tapText(tester, es.tipsSkip);

      // Otra cuenta en el mismo teléfono: cerrar sesión e ingresar.
      await tester.tap(find.byTooltip(es.accountTooltip));
      await tester.pumpAndSettle();
      await tapText(tester, es.signOut);
      h.authApi.user = const UserAccount(
        id: 'otra-cuenta',
        email: 'luis@correo.com',
        displayName: 'Luis',
      );
      await tapText(tester, es.haveAccount);
      await enterField(tester, es.emailLabel, 'luis@correo.com');
      await enterField(tester, es.passwordLabel, 'clave-segura-2');
      await tapText(tester, es.signIn);
      expect(find.text(es.greeting('Luis')), findsOneWidget);
      expect(find.text(es.tipsSkip), findsNothing);

      // Cerrar y abrir la app: los ajustes guardados dicen que ya se vieron.
      await tester.pumpWidget(const SizedBox()); // la app se cierra
      final reopened = TestHarness()
        ..settingsStore.stored = h.settingsStore.stored;
      await pumpHandTextApp(tester, reopened);
      expect(find.text(es.takePhoto), findsOneWidget);
      expect(find.text(es.tipsSkip), findsNothing);
    },
  );

  testWidgets('[PA-H1-E5] se abren desde el inicio y se vuelve al inicio', (
    tester,
  ) async {
    await pumpHandTextApp(tester, TestHarness());

    await tapText(tester, es.tipsLink);
    _expectTip(0);
    await tapText(tester, es.tipsSkip);

    expect(find.text(es.takePhoto), findsOneWidget);
  });

  testWidgets('[PA-H1-E5] se abren desde Ajustes y se vuelve a Ajustes', (
    tester,
  ) async {
    await pumpHandTextApp(tester, TestHarness());
    await tester.tap(find.byTooltip(es.accountTooltip));
    await tester.pumpAndSettle();
    await tapText(tester, es.settingsTitle);

    await tapText(tester, es.tipsLink);
    for (var index = 1; index < _count; index++) {
      await tapText(tester, es.tipsNext);
    }
    await tapText(tester, es.tipsStart);

    // De vuelta en Ajustes: su título (la lista quedó desplazada hasta los consejos).
    expect(find.text(es.settingsTitle), findsOneWidget);
    expect(find.text(es.tipsLink), findsOneWidget);
  });

  testWidgets(
    '[PA-H2-E4] [PA-H2-E5] TalkBack lee el consejo nuevo y el título es encabezado',
    (tester) async {
      final handle = tester.ensureSemantics();
      final announcements = <String>[];
      tester.binding.defaultBinaryMessenger
          .setMockDecodedMessageHandler<Object?>(SystemChannels.accessibility, (
            message,
          ) async {
            final data = (message! as Map)['data'] as Map;
            if (data['message'] case final String text) announcements.add(text);
            return null;
          });
      addTearDown(
        () => tester.binding.defaultBinaryMessenger
            .setMockDecodedMessageHandler<Object?>(
              SystemChannels.accessibility,
              null,
            ),
      );
      await pumpHandTextApp(tester, _firstTime());

      expect(
        tester.getSemantics(find.text(es.tips[0].$1)),
        containsSemantics(isHeader: true),
      );
      await tapText(tester, es.tipsNext);

      expect(
        announcements,
        contains('${es.tipOf(2, _count)}. ${es.tips[1].$1}'),
      );
      handle.dispose();
    },
  );
}
