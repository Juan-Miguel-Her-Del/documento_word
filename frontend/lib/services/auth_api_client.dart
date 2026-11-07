// Cliente de la API de cuentas (tarea T122; spec 002; contracts/auth-api.md).
//
// Registro, ingreso, comprobación de la sesión, cierre y eliminación de la cuenta. La
// contraseña solo viaja en el cuerpo de la solicitud y nunca se guarda en el teléfono.

import 'dart:convert';

import 'package:http/http.dart' as http;

import '../config/app_config.dart';
import '../models/app_failure.dart';
import '../models/user_account.dart';
import 'api_errors.dart';

/// Sesión recién iniciada: el token y los datos visibles de la cuenta.
class AuthResult {
  const AuthResult({required this.token, required this.user});

  final String token;
  final UserAccount user;
}

/// Lo que AuthController necesita. Las pruebas usan una versión falsa.
abstract interface class AuthApi {
  Future<AuthResult> register({
    required String displayName,
    required String email,
    required String password,
    required bool acceptsDataPolicy,
  });

  Future<AuthResult> login({required String email, required String password});

  Future<UserAccount> me(String token);

  Future<void> logout(String token);

  Future<void> deleteAccount(String token, String password);
}

class AuthApiClient implements AuthApi {
  AuthApiClient({
    required Uri baseUrl,
    http.Client? httpClient,
    Duration timeout = AppConfig.authTimeout,
  }) : _baseUrl = baseUrl,
       _client = httpClient ?? http.Client(),
       _timeout = timeout;

  final Uri _baseUrl;
  final http.Client _client;
  final Duration _timeout;

  static const _json = {'Content-Type': 'application/json; charset=utf-8'};

  Map<String, String> _bearer(String token) => {
    'Authorization': 'Bearer $token',
  };

  Future<http.Response> _send(Future<http.Response> Function() request) =>
      sendRequest(
        request,
        timeout: _timeout,
        timeoutFailure: FailureKind.noConnection,
      );

  @override
  Future<AuthResult> register({
    required String displayName,
    required String email,
    required String password,
    required bool acceptsDataPolicy,
  }) async {
    final response = await _send(
      () => _client.post(
        _baseUrl.resolve('api/v1/auth/register'),
        headers: _json,
        body: jsonEncode({
          'display_name': displayName,
          'email': email,
          'password': password,
          'accepts_data_policy': acceptsDataPolicy,
        }),
      ),
    );
    return _session(response, expectedStatus: 201);
  }

  @override
  Future<AuthResult> login({
    required String email,
    required String password,
  }) async {
    final response = await _send(
      () => _client.post(
        _baseUrl.resolve('api/v1/auth/login'),
        headers: _json,
        body: jsonEncode({'email': email, 'password': password}),
      ),
    );
    return _session(response, expectedStatus: 200);
  }

  @override
  Future<UserAccount> me(String token) async {
    final response = await _send(
      () => _client.get(
        _baseUrl.resolve('api/v1/auth/me'),
        headers: _bearer(token),
      ),
    );
    if (response.statusCode != 200) {
      throw failureFromResponse(response, fallback: FailureKind.unexpected);
    }
    try {
      return switch (decodeJson(response)) {
        {'user': final Object user} => UserAccount.fromJson(user),
        _ => throw const FormatException('Sin usuario'),
      };
    } on FormatException {
      throw const AppFailure(FailureKind.invalidServerResponse);
    }
  }

  @override
  Future<void> logout(String token) async {
    final response = await _send(
      () => _client.post(
        _baseUrl.resolve('api/v1/auth/logout'),
        headers: _bearer(token),
      ),
    );
    if (response.statusCode != 204) {
      throw failureFromResponse(response, fallback: FailureKind.unexpected);
    }
  }

  @override
  Future<void> deleteAccount(String token, String password) async {
    final response = await _send(
      () => _client.delete(
        _baseUrl.resolve('api/v1/account'),
        headers: {..._bearer(token), ..._json},
        body: jsonEncode({'password': password}),
      ),
    );
    if (response.statusCode != 204) {
      throw failureFromResponse(response, fallback: FailureKind.unexpected);
    }
  }

  /// Interpreta la respuesta del registro o del ingreso.
  AuthResult _session(http.Response response, {required int expectedStatus}) {
    if (response.statusCode != expectedStatus) {
      throw failureFromResponse(response, fallback: FailureKind.unexpected);
    }
    try {
      return switch (decodeJson(response)) {
        {'token': final String token, 'user': final Object user} => AuthResult(
          token: token,
          user: UserAccount.fromJson(user),
        ),
        _ => throw const FormatException('Sesión con formato inesperado'),
      };
    } on FormatException {
      throw const AppFailure(FailureKind.invalidServerResponse);
    }
  }
}
