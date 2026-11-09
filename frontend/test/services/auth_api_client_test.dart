// Pruebas del cliente HTTP de cuentas (tarea T119; contracts/auth-api.md).

import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:handtext_ai/models/app_failure.dart';
import 'package:handtext_ai/models/image_format.dart';
import 'package:handtext_ai/services/auth_api_client.dart';
import 'package:handtext_ai/services/handtext_api_client.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import '../support/fakes.dart';

const _user = {
  'id': '0b6f2a3e-1111-4c4c-9a9a-123456789abc',
  'display_name': 'Ana',
  'email': 'ana@correo.com',
};

AuthApiClient _client(MockClientHandler handler) => AuthApiClient(
  baseUrl: Uri.parse('http://api.test/'),
  httpClient: MockClient(handler),
);

http.Response _json(Object body, int status) => http.Response.bytes(
  utf8.encode(jsonEncode(body)),
  status,
  headers: {'content-type': 'application/json'},
);

http.Response _error(String code, int status) => _json({
  'error': {'code': code, 'message': 'm', 'request_id': 'r'},
}, status);

Future<FailureKind> _failureOf(Future<Object?> operation) async {
  try {
    await operation;
  } on AppFailure catch (failure) {
    return failure.kind;
  }
  fail('Se esperaba un AppFailure');
}

void main() {
  test('[CU-H1-E2] el registro envía los datos y recibe la sesión', () async {
    late http.Request sent;
    final client = _client((request) async {
      sent = request;
      return _json({'token': 'abc', 'user': _user}, 201);
    });

    final result = await client.register(
      displayName: 'Ana',
      email: 'ana@correo.com',
      password: 'clave-1234',
      acceptsDataPolicy: true,
    );

    expect(result.token, 'abc');
    expect(result.user.displayName, 'Ana');
    expect(sent.url.path, '/api/v1/auth/register');
    expect(jsonDecode(sent.body), {
      'display_name': 'Ana',
      'email': 'ana@correo.com',
      'password': 'clave-1234',
      'accepts_data_policy': true,
    });
  });

  test('los errores de cuenta se traducen', () async {
    final cases = <(String, int, FailureKind)>[
      ('INVALID_CREDENTIALS', 401, FailureKind.invalidCredentials),
      ('TOO_MANY_ATTEMPTS', 429, FailureKind.tooManyAttempts),
      ('EMAIL_ALREADY_REGISTERED', 409, FailureKind.emailAlreadyRegistered),
      ('WEAK_PASSWORD', 400, FailureKind.weakPassword),
      ('ACCOUNTS_UNAVAILABLE', 503, FailureKind.accountsUnavailable),
    ];
    for (final (code, status, kind) in cases) {
      final client = _client((_) async => _error(code, status));
      expect(
        await _failureOf(client.login(email: 'a@b.co', password: 'x')),
        kind,
      );
    }
  });

  test('me y logout envían el token Bearer', () async {
    final headers = <String?>[];
    final client = _client((request) async {
      headers.add(request.headers['authorization']);
      return request.url.path.endsWith('/me')
          ? _json({'user': _user}, 200)
          : http.Response('', 204);
    });

    await client.me('t-1');
    await client.logout('t-1');

    expect(headers, ['Bearer t-1', 'Bearer t-1']);
  });

  test('[CU-H2-E5] un token vencido es «sesión vencida»', () async {
    final client = _client((_) async => _error('UNAUTHENTICATED', 401));

    expect(await _failureOf(client.me('viejo')), FailureKind.sessionExpired);
  });

  test(
    '[CU-H2-E3] eliminar la cuenta envía DELETE con la contraseña',
    () async {
      late http.Request sent;
      final client = _client((request) async {
        sent = request;
        return http.Response('', 204);
      });

      await client.deleteAccount('t-1', 'clave-1234');

      expect(sent.method, 'DELETE');
      expect(sent.url.path, '/api/v1/account');
      expect(jsonDecode(sent.body), {'password': 'clave-1234'});
    },
  );

  test('una respuesta 200 sin token es una respuesta no válida', () async {
    final client = _client((_) async => _json({'user': _user}, 200));

    expect(
      await _failureOf(client.login(email: 'a@b.co', password: 'x')),
      FailureKind.invalidServerResponse,
    );
  });

  test(
    '[SC-202] el cliente de documentos envía el token de la sesión',
    () async {
      late http.Request sent;
      final documents = HandTextApiClient(
        baseUrl: Uri.parse('http://api.test/'),
        tokenProvider: () => 'token-de-sesion',
        httpClient: MockClient((request) async {
          sent = request;
          return _error('UNAUTHENTICATED', 401);
        }),
      );

      final kind = await _failureOf(
        documents.recognize(fakePngBytes(), ImageFormat.png),
      );

      expect(sent.headers['authorization'], 'Bearer token-de-sesion');
      expect(kind, FailureKind.sessionExpired); // [CU-H2-E5]
    },
  );

  test(
    'un 401 sin token informa que el backend requiere otra sesión',
    () async {
      late http.Request sent;
      final documents = HandTextApiClient(
        baseUrl: Uri.parse('http://api.test/'),
        httpClient: MockClient((request) async {
          sent = request;
          return _error('UNAUTHENTICATED', 401);
        }),
      );

      final kind = await _failureOf(
        documents.recognize(fakePngBytes(), ImageFormat.png),
      );

      expect(sent.headers.containsKey('authorization'), isFalse);
      expect(kind, FailureKind.backendAuthenticationRequired);
    },
  );

  test(
    'el secreto de desarrollo local se envía solo al cliente de documentos',
    () async {
      late http.Request sent;
      final documents = HandTextApiClient(
        baseUrl: Uri.parse('http://api.test/'),
        localDevToken: 'secret-local',
        httpClient: MockClient((request) async {
          sent = request;
          return _json({'status': 'text_found', 'text': 'Hola'}, 200);
        }),
      );

      await documents.recognize(fakePngBytes(), ImageFormat.png);

      expect(sent.headers['x-handtext-local-dev'], 'secret-local');
      expect(sent.headers.containsKey('authorization'), isFalse);
    },
  );

  test(
    'un secreto local rechazado no se confunde con sesión vencida',
    () async {
      final documents = HandTextApiClient(
        baseUrl: Uri.parse('http://api.test/'),
        localDevToken: 'secret-local',
        httpClient: MockClient((_) async => _error('UNAUTHENTICATED', 401)),
      );

      expect(
        await _failureOf(documents.recognize(fakePngBytes(), ImageFormat.png)),
        FailureKind.backendAuthenticationRequired,
      );
    },
  );
}
