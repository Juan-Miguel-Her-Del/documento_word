// Pruebas del controlador de sesión (tareas T119 y T129; spec 002).

import 'package:flutter_test/flutter_test.dart';
import 'package:handtext_ai/models/app_failure.dart';
import 'package:handtext_ai/models/operation_status.dart';
import 'package:handtext_ai/services/session_store.dart';
import 'package:handtext_ai/state/auth_controller.dart';

import '../support/fakes.dart';

void main() {
  late FakeAuthApi api;
  late InMemorySessionStore sessions;
  late AuthController auth;

  setUp(() {
    api = FakeAuthApi();
    sessions = InMemorySessionStore();
    auth = AuthController(api: api, sessions: sessions);
  });

  group('al abrir la app', () {
    test('sin sesión guardada muestra la bienvenida', () async {
      await auth.initialize();

      expect(auth.status, AuthStatus.signedOut);
      expect(api.calls, isEmpty);
    });

    test('[CU-H1-E9] con sesión válida entra directo', () async {
      sessions.stored = const StoredSession(token: 't', user: testUser);

      await auth.initialize();

      expect(auth.status, AuthStatus.signedIn);
      expect(auth.user?.displayName, 'Ana María');
      expect(auth.token, 't');
    });

    test(
      '[CU-H2-E5] con sesión vencida pide ingresar y borra la guardada',
      () async {
        sessions.stored = const StoredSession(token: 't', user: testUser);
        api.meError = const AppFailure(FailureKind.sessionExpired);

        await auth.initialize();

        expect(auth.status, AuthStatus.signedOut);
        expect(auth.notice, StatusEvent.sessionExpired);
        expect(sessions.stored, isNull);
      },
    );

    test('sin conexión entra con los datos guardados (caso límite)', () async {
      sessions.stored = const StoredSession(token: 't', user: testUser);
      api.meError = const AppFailure(FailureKind.noConnection);

      await auth.initialize();

      expect(auth.status, AuthStatus.signedIn);
      expect(auth.user, testUser);
    });
  });

  group('ingreso y registro', () {
    test('[CU-H1-E6] ingresar guarda la sesión en el almacén seguro', () async {
      await auth.initialize();

      final ok = await auth.signIn(
        email: 'ana@correo.com',
        password: 'clave-1234',
      );

      expect(ok, isTrue);
      expect(auth.status, AuthStatus.signedIn);
      expect(sessions.stored?.token, 'token-nuevo');
    });

    test(
      '[CU-H1-E7] un ingreso fallido deja el motivo y no inicia sesión',
      () async {
        await auth.initialize();
        api.loginError = const AppFailure(FailureKind.invalidCredentials);

        final ok = await auth.signIn(email: 'ana@correo.com', password: 'mala');

        expect(ok, isFalse);
        expect(auth.status, AuthStatus.signedOut);
        expect(auth.failure?.kind, FailureKind.invalidCredentials);
        expect(sessions.stored, isNull);
      },
    );

    test('[CU-H1-E3] un correo repetido se informa', () async {
      await auth.initialize();
      api.registerError = const AppFailure(FailureKind.emailAlreadyRegistered);

      final ok = await auth.register(
        displayName: 'Ana',
        email: 'ana@correo.com',
        password: 'clave-1234',
        acceptsDataPolicy: true,
      );

      expect(ok, isFalse);
      expect(auth.failure?.kind, FailureKind.emailAlreadyRegistered);
    });
  });

  group('cerrar sesión y eliminar la cuenta', () {
    setUp(() async {
      sessions.stored = const StoredSession(token: 't', user: testUser);
      await auth.initialize();
    });

    test(
      '[CU-H2-E1] cerrar sesión borra la local y avisa al servidor',
      () async {
        var cleared = false;

        await auth.signOut(beforeSignOut: () async => cleared = true);

        expect(cleared, isTrue);
        expect(api.calls, contains('logout:t'));
        expect(auth.status, AuthStatus.signedOut);
        expect(auth.notice, StatusEvent.signedOut);
        expect(sessions.stored, isNull);
      },
    );

    test('[CU-H2-E3] eliminar la cuenta borra los datos locales', () async {
      var cleared = false;

      final ok = await auth.deleteAccount(
        'clave-1234',
        beforeSignOut: () async => cleared = true,
      );

      expect(ok, isTrue);
      expect(cleared, isTrue);
      expect(auth.notice, StatusEvent.accountDeleted);
      expect(sessions.stored, isNull);
    });

    test(
      '[CU-H2-E4] con contraseña incorrecta la cuenta se conserva',
      () async {
        api.deleteError = const AppFailure(FailureKind.invalidCredentials);
        var cleared = false;

        final ok = await auth.deleteAccount(
          'mala',
          beforeSignOut: () async => cleared = true,
        );

        expect(ok, isFalse);
        expect(cleared, isFalse);
        expect(auth.status, AuthStatus.signedIn);
        expect(auth.failure?.kind, FailureKind.invalidCredentials);
      },
    );

    test(
      '[CU-H2-E5] la sesión vencida durante el uso vuelve a la bienvenida',
      () async {
        auth.handleSessionExpired();
        await Future<void>.delayed(Duration.zero);

        expect(auth.status, AuthStatus.signedOut);
        expect(auth.notice, StatusEvent.sessionExpired);
        expect(sessions.stored, isNull);
      },
    );
  });
}
