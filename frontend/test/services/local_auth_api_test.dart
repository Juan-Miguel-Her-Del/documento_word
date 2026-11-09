import 'package:flutter_test/flutter_test.dart';
import 'package:handtext_ai/models/app_failure.dart';
import 'package:handtext_ai/services/local_auth_api.dart';

class _MemoryAccountStore implements LocalAccountStore {
  final List<LocalAccountRecord> accounts = [];

  @override
  Future<List<LocalAccountRecord>> read() async => accounts.toList();

  @override
  Future<void> write(List<LocalAccountRecord> value) async {
    accounts
      ..clear()
      ..addAll(value);
  }
}

Future<FailureKind> _failureOf(Future<Object?> operation) async {
  try {
    await operation;
  } on AppFailure catch (failure) {
    return failure.kind;
  }
  fail('Se esperaba un AppFailure');
}

void main() {
  late _MemoryAccountStore store;
  late LocalAuthApi auth;

  setUp(() {
    store = _MemoryAccountStore();
    auth = LocalAuthApi(accounts: store);
  });

  test('registra una cuenta local y no conserva la contraseña', () async {
    final result = await auth.register(
      displayName: '  Ana   María ',
      email: ' ANA@Correo.COM ',
      password: 'clave-segura-1',
      acceptsDataPolicy: true,
    );

    expect(result.user.displayName, 'Ana María');
    expect(result.user.email, 'ana@correo.com');
    expect(result.user.id, matches(RegExp(r'^[0-9a-f-]{36}$')));
    expect(store.accounts, hasLength(1));
    expect(store.accounts.single.passwordHash, isNot('clave-segura-1'));
    expect(store.accounts.single.sessionToken, result.token);
    expect(await auth.me(result.token), result.user);
  });

  test('no permite registrar dos veces el mismo correo', () async {
    await auth.register(
      displayName: 'Ana',
      email: 'ana@correo.com',
      password: 'clave-segura-1',
      acceptsDataPolicy: true,
    );

    expect(
      await _failureOf(
        auth.register(
          displayName: 'Otra Ana',
          email: ' ANA@CORREO.COM ',
          password: 'clave-segura-2',
          acceptsDataPolicy: true,
        ),
      ),
      FailureKind.emailAlreadyRegistered,
    );
    expect(store.accounts, hasLength(1));
  });

  test('el ingreso local conserva acceso tras crear otro servicio', () async {
    await auth.register(
      displayName: 'Ana',
      email: 'ana@correo.com',
      password: 'clave-segura-1',
      acceptsDataPolicy: true,
    );
    final nextRun = LocalAuthApi(accounts: store);

    final result = await nextRun.login(
      email: ' ANA@CORREO.COM ',
      password: 'clave-segura-1',
    );

    expect(await nextRun.me(result.token), result.user);
  });

  test('una contraseña incorrecta no inicia sesión', () async {
    await auth.register(
      displayName: 'Ana',
      email: 'ana@correo.com',
      password: 'clave-segura-1',
      acceptsDataPolicy: true,
    );

    expect(
      await _failureOf(
        auth.login(email: 'ana@correo.com', password: 'incorrecta'),
      ),
      FailureKind.invalidCredentials,
    );
  });

  test('cerrar sesión invalida el token pero conserva la cuenta', () async {
    final result = await auth.register(
      displayName: 'Ana',
      email: 'ana@correo.com',
      password: 'clave-segura-1',
      acceptsDataPolicy: true,
    );

    await auth.logout(result.token);

    expect(await _failureOf(auth.me(result.token)), FailureKind.sessionExpired);
    expect(store.accounts, hasLength(1));
    expect(store.accounts.single.sessionToken, isNull);
  });

  test('eliminar requiere la contraseña y borra la cuenta local', () async {
    final result = await auth.register(
      displayName: 'Ana',
      email: 'ana@correo.com',
      password: 'clave-segura-1',
      acceptsDataPolicy: true,
    );

    expect(
      await _failureOf(auth.deleteAccount(result.token, 'incorrecta')),
      FailureKind.invalidCredentials,
    );
    expect(store.accounts, hasLength(1));

    await auth.deleteAccount(result.token, 'clave-segura-1');
    expect(store.accounts, isEmpty);
  });

  test('rechaza el registro sin aceptar la política', () async {
    expect(
      await _failureOf(
        auth.register(
          displayName: 'Ana',
          email: 'ana@correo.com',
          password: 'clave-segura-1',
          acceptsDataPolicy: false,
        ),
      ),
      FailureKind.dataPolicyNotAccepted,
    );
    expect(store.accounts, isEmpty);
  });
}
