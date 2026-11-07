// Prueba de contrato entre la app y la API REAL (tareas T056 y T137; constitución §6,
// integraciones; contracts/api.md y contracts/auth-api.md).
//
// Usa los clientes HTTP reales de la app contra un backend en marcha, con PostgreSQL,
// y comprueba que ambos «hablan el mismo idioma»:
// 1. Crea una cuenta temporal y usa su token (spec 002).
// 2. Prueba el reconocimiento y la exportación con esa sesión.
// 3. Al final elimina la cuenta.
// Se OMITE si no se define la variable HANDTEXT_API_URL. Para ejecutarla (PowerShell):
//   1) cd backend; .venv\Scripts\python -m uvicorn app.main:app --port 8000
//      (con HANDTEXT_DATABASE_URL apuntando a la base, ver quickstart.md)
//   2) cd frontend; $env:HANDTEXT_API_URL = "http://127.0.0.1:8000/"
//      flutter test test/integration
// Sin clave de Google, el reconocimiento responde «servicio no disponible».

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:handtext_ai/models/app_failure.dart';
import 'package:handtext_ai/models/export_format.dart';
import 'package:handtext_ai/models/image_format.dart';
import 'package:handtext_ai/services/auth_api_client.dart';
import 'package:handtext_ai/services/handtext_api_client.dart';

import '../support/synthetic_png.dart';

void main() {
  final apiUrl = Platform.environment['HANDTEXT_API_URL'];
  final skip = apiUrl == null
      ? 'Defina HANDTEXT_API_URL para probar contra la API real'
      : false;
  final baseUrl = Uri.parse(apiUrl ?? 'http://127.0.0.1:8000/');
  final accounts = AuthApiClient(baseUrl: baseUrl);
  const password = 'clave-de-contrato-123';
  String? token;
  final documents = HandTextApiClient(
    baseUrl: baseUrl,
    tokenProvider: () => token,
  );

  Future<FailureKind> failureOf(Future<Object?> operation) async {
    try {
      await operation;
    } on AppFailure catch (failure) {
      return failure.kind;
    }
    fail('Se esperaba un AppFailure');
  }

  test('[CU-H1-E2] se crea una cuenta temporal con sesión', () async {
    final email =
        'contrato-${DateTime.now().microsecondsSinceEpoch}@handtext.test';
    final result = await accounts.register(
      displayName: 'Prueba de contrato',
      email: email,
      password: password,
      acceptsDataPolicy: true,
    );
    token = result.token;

    expect((await accounts.me(result.token)).email, email);
  }, skip: skip);

  test('[SC-202] sin sesión no se puede exportar', () async {
    final anonymous = HandTextApiClient(baseUrl: baseUrl);

    expect(
      await failureOf(anonymous.export('Hola', ExportFormat.docx)),
      FailureKind.sessionExpired,
    );
  }, skip: skip);

  test('[SC-001] Word: la API devuelve un .docx real', () async {
    final bytes = await documents.export(
      'Título\n\nAcentos: áéíóú ñ ¿? ¡!',
      ExportFormat.docx,
    );

    expect(ExportFormat.docx.matchesContent(bytes), isTrue);
  }, skip: skip);

  test('[SC-001] PDF: la API devuelve un .pdf real', () async {
    final bytes = await documents.export(
      'Título\n\nAcentos: áéíóú ñ ¿? ¡!',
      ExportFormat.pdf,
    );

    expect(ExportFormat.pdf.matchesContent(bytes), isTrue);
  }, skip: skip);

  test('[SC-007] la API rechaza el texto vacío', () async {
    expect(
      await failureOf(documents.export('  \n ', ExportFormat.docx)),
      FailureKind.emptyText,
    );
  }, skip: skip);

  test('la API explica qué caracteres no caben en el PDF', () async {
    try {
      await documents.export('Hola 漢', ExportFormat.pdf);
      fail('Se esperaba un AppFailure');
    } on AppFailure catch (failure) {
      expect(failure.kind, FailureKind.unsupportedCharacters);
      expect(failure.detail, contains('U+6F22'));
    }
  }, skip: skip);

  test('[H1-E1] la API rechaza una imagen demasiado pequeña', () async {
    expect(
      await failureOf(documents.recognize(syntheticPng(7, 5), ImageFormat.png)),
      FailureKind.imageDimensionsOutOfRange,
    );
  }, skip: skip);

  test(
    'el reconocimiento responde según la configuración del servidor',
    () async {
      try {
        // Con clave de Google: una hoja en blanco debe dar «sin texto».
        final result = await documents.recognize(
          syntheticPng(600, 600),
          ImageFormat.png,
        );
        expect(result.hasText, isFalse);
      } on AppFailure catch (failure) {
        // Sin clave: el servidor informa que el servicio no está disponible.
        expect(failure.kind, FailureKind.serviceUnavailable);
      }
    },
    skip: skip,
  );

  test('[CU-H2-E3] la cuenta temporal se elimina', () async {
    await accounts.deleteAccount(token!, password);

    expect(await failureOf(accounts.me(token!)), FailureKind.sessionExpired);
  }, skip: skip);
}
