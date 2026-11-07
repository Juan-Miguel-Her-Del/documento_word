// Pruebas de las pantallas de cuenta (tareas T128 y T129; spec 002, Historias 1 y 2).

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:handtext_ai/models/app_failure.dart';
import 'package:handtext_ai/models/recognition_result.dart';

import '../support/strings_es.dart';
import '../support/app_tester.dart';
import '../support/fakes.dart';

Future<void> _fillRegistration(
  WidgetTester tester, {
  String confirm = 'clave-segura-1',
}) async {
  await enterField(tester, es.nameLabel, 'Ana María');
  await enterField(tester, es.emailLabel, 'ana@correo.com');
  await enterField(tester, es.passwordLabel, 'clave-segura-1');
  await enterField(tester, es.confirmPasswordLabel, confirm);
}

Future<void> _openAccountMenuItem(WidgetTester tester, String item) async {
  await tester.tap(find.byTooltip(es.accountTooltip));
  await tester.pumpAndSettle();
  await tapText(tester, item);
}

void main() {
  testWidgets('[CU-H1-E1] sin sesión se muestra la bienvenida', (tester) async {
    await pumpHandTextApp(tester, TestHarness(signedIn: false));

    expect(find.text(es.welcomeTagline), findsOneWidget);
    expect(find.text(es.createAccount), findsOneWidget);
    expect(find.text(es.haveAccount), findsOneWidget);
  });

  testWidgets('[CU-H1-E2] un registro válido entra a la app y saluda', (
    tester,
  ) async {
    final h = TestHarness(signedIn: false);
    await pumpHandTextApp(tester, h);

    await tapText(tester, es.createAccount);
    await _fillRegistration(tester);
    await tester.tap(find.byType(CheckboxListTile));
    await tester.pumpAndSettle();
    await tapText(tester, es.createAccount);

    expect(h.authApi.calls, contains('register'));
    expect(
      h.sessions.stored?.token,
      'token-nuevo',
    ); // [CU-H1-E9] sesión guardada
    expect(find.text(es.greeting('Ana')), findsOneWidget);
  });

  testWidgets('[CU-H1-E5] sin la autorización de datos no se envía nada', (
    tester,
  ) async {
    final h = TestHarness(signedIn: false);
    await pumpHandTextApp(tester, h);

    await tapText(tester, es.createAccount);
    await _fillRegistration(tester);
    await tapText(tester, es.createAccount);

    expect(h.authApi.calls, isEmpty);
    expect(
      find.text(
        es.failureText(const AppFailure(FailureKind.dataPolicyNotAccepted)),
      ),
      findsOneWidget,
    );
  });

  testWidgets('[CU-H1-E4] las contraseñas deben coincidir', (tester) async {
    final h = TestHarness(signedIn: false);
    await pumpHandTextApp(tester, h);

    await tapText(tester, es.createAccount);
    await _fillRegistration(tester, confirm: 'otra-clave-2');
    await tester.tap(find.byType(CheckboxListTile));
    await tester.pumpAndSettle();
    await tapText(tester, es.createAccount);

    expect(h.authApi.calls, isEmpty);
    expect(find.text('Las contraseñas no coinciden.'), findsOneWidget);
  });

  testWidgets('[CU-H1-E7] datos incorrectos muestran un único mensaje', (
    tester,
  ) async {
    final h = TestHarness(signedIn: false);
    h.authApi.loginError = const AppFailure(FailureKind.invalidCredentials);
    await pumpHandTextApp(tester, h);

    await tapText(tester, es.haveAccount);
    await enterField(tester, es.emailLabel, 'ana@correo.com');
    await enterField(tester, es.passwordLabel, 'mala-clave');
    await tapText(tester, es.signIn);

    expect(find.text('Correo o contraseña incorrectos.'), findsOneWidget);
    expect(find.text(es.loginTitle), findsOneWidget); // sigue en el ingreso
  });

  testWidgets('[CU-H1-E9] con una sesión guardada se entra directo', (
    tester,
  ) async {
    final h = TestHarness();
    await pumpHandTextApp(tester, h);

    expect(h.authApi.calls, ['me']); // se comprobó la sesión con la API
    expect(find.text(es.greeting('Ana')), findsOneWidget);
  });

  testWidgets('[CU-H2-E5] si la sesión guardada venció, se pide ingresar', (
    tester,
  ) async {
    final h = TestHarness();
    h.authApi.meError = const AppFailure(FailureKind.sessionExpired);
    await pumpHandTextApp(tester, h);

    expect(find.text(es.loginTitle), findsOneWidget);
    expect(find.textContaining('Su sesión venció'), findsOneWidget);
    expect(h.sessions.stored, isNull);
  });

  testWidgets('[CU-H2-E5] un 401 durante el reconocimiento lleva al ingreso', (
    tester,
  ) async {
    final h = TestHarness();
    h.api.recognitionError = const AppFailure(FailureKind.sessionExpired);
    await pumpHandTextApp(tester, h);

    await tapText(tester, es.pickFromGallery);
    await tapText(tester, es.acceptAndRecognize);
    await tapText(tester, es.consentAccept);

    expect(find.text(es.loginTitle), findsOneWidget);
    expect(find.textContaining('Su sesión venció'), findsOneWidget);
  });

  testWidgets(
    '[CU-H2-E2] cerrar sesión con texto sin exportar pide confirmación',
    (tester) async {
      final h = TestHarness();
      h.api.recognitionResult = const RecognitionResult(
        hasText: true,
        text: 'Mis apuntes',
      );
      await pumpHandTextApp(tester, h);
      await tapText(tester, es.pickFromGallery);
      await tapText(tester, es.acceptAndRecognize);
      await tapText(tester, es.consentAccept);

      await _openAccountMenuItem(tester, es.signOut);
      expect(find.text(es.signOutTitle), findsOneWidget);
      await tapText(tester, es.cancel);
      expect(
        find.text('Mis apuntes'),
        findsOneWidget,
      ); // cancelar conserva todo

      await _openAccountMenuItem(tester, es.signOut);
      await tapText(tester, es.signOut);

      expect(find.text(es.createAccount), findsOneWidget); // bienvenida
      expect(h.drafts.stored, isNull); // el texto se descartó
      expect(h.sessions.stored, isNull);
      expect(h.authApi.calls, contains('logout:token-guardado'));
    },
  );

  testWidgets('[CU-H2-E3] eliminar la cuenta con la contraseña', (
    tester,
  ) async {
    final h = TestHarness();
    await pumpHandTextApp(tester, h);

    await _openAccountMenuItem(tester, es.deleteAccount);
    await tester.enterText(find.byType(TextField), 'clave-segura-1');
    await tester.pumpAndSettle();
    await tapText(tester, es.deleteAccountConfirm);

    expect(h.authApi.calls, contains('delete'));
    expect(h.sessions.stored, isNull);
    expect(find.text('Su cuenta y sus datos se eliminaron.'), findsOneWidget);
  });

  testWidgets(
    '[CU-H2-E4] con una contraseña incorrecta la cuenta se conserva',
    (tester) async {
      final h = TestHarness();
      h.authApi.deleteError = const AppFailure(FailureKind.invalidCredentials);
      await pumpHandTextApp(tester, h);

      await _openAccountMenuItem(tester, es.deleteAccount);
      await tester.enterText(find.byType(TextField), 'mala-clave');
      await tester.pumpAndSettle();
      await tapText(tester, es.deleteAccountConfirm);

      expect(find.text('Correo o contraseña incorrectos.'), findsOneWidget);
      expect(find.text(es.greeting('Ana')), findsOneWidget); // sigue adentro
      expect(h.sessions.stored, isNotNull);
    },
  );
}
