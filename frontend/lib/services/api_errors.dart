// Errores de la API compartidos por todos los clientes HTTP (tarea T121).
//
// - sendRequest: envía con tiempo máximo y traduce los problemas de red.
// - failureFromResponse: traduce `{"error": {"code": ...}}` (contracts/api.md y
//   contracts/auth-api.md) a un AppFailure con mensaje en español. Nunca se muestra
//   la respuesta técnica (constitución §5, UI).

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import '../models/app_failure.dart';

/// Ejecuta la solicitud con tiempo máximo; sin red lanza AppFailure(noConnection).
Future<http.Response> sendRequest(
  Future<http.Response> Function() request, {
  required Duration timeout,
  required FailureKind timeoutFailure,
}) async {
  try {
    return await request().timeout(timeout);
  } on TimeoutException {
    throw AppFailure(timeoutFailure);
  } on IOException {
    // Sin red, servidor apagado o dirección equivocada.
    throw const AppFailure(FailureKind.noConnection);
  } on http.ClientException {
    throw const AppFailure(FailureKind.noConnection);
  }
}

/// Decodifica el cuerpo JSON; lanza FormatException si no es JSON válido.
Object? decodeJson(http.Response response) =>
    jsonDecode(utf8.decode(response.bodyBytes));

/// Traduce el código de error de la API a un fallo con mensaje propio.
AppFailure failureFromResponse(
  http.Response response, {
  required FailureKind fallback,
}) {
  String? code;
  String? message;
  try {
    if (decodeJson(response) case {
      'error': {'code': final String c, 'message': final String m},
    }) {
      code = c;
      message = m;
    }
  } on FormatException {
    // Respuesta sin JSON (por ejemplo, de un proxy): se usa el fallo genérico.
  }
  return switch (code) {
    // Imágenes y reconocimiento (spec 001).
    'IMAGE_TOO_LARGE' => const AppFailure(FailureKind.imageTooLarge),
    'UNSUPPORTED_IMAGE_TYPE' => const AppFailure(
      FailureKind.unsupportedImageType,
    ),
    'IMAGE_UNREADABLE' => const AppFailure(FailureKind.imageUnreadable),
    'IMAGE_DIMENSIONS_OUT_OF_RANGE' => const AppFailure(
      FailureKind.imageDimensionsOutOfRange,
    ),
    'OCR_NOT_CONFIGURED' => const AppFailure(FailureKind.serviceUnavailable),
    'OCR_TIMEOUT' => const AppFailure(FailureKind.recognitionTimeout),
    'OCR_PROVIDER_ERROR' ||
    'OCR_INVALID_RESPONSE' => const AppFailure(FailureKind.recognitionFailed),
    // Exportación (spec 001).
    'EMPTY_TEXT' => const AppFailure(FailureKind.emptyText),
    'TEXT_TOO_LARGE' => const AppFailure(FailureKind.textTooLarge),
    // El mensaje de la API enumera los caracteres; está redactado para el usuario.
    'UNSUPPORTED_CHARACTERS' => AppFailure(
      FailureKind.unsupportedCharacters,
      detail: message,
    ),
    // Cuentas y sesión (spec 002).
    'UNAUTHENTICATED' => const AppFailure(FailureKind.sessionExpired),
    'INVALID_CREDENTIALS' => const AppFailure(FailureKind.invalidCredentials),
    'TOO_MANY_ATTEMPTS' => const AppFailure(FailureKind.tooManyAttempts),
    'EMAIL_ALREADY_REGISTERED' => const AppFailure(
      FailureKind.emailAlreadyRegistered,
    ),
    'INVALID_EMAIL' => const AppFailure(FailureKind.invalidEmail),
    'INVALID_DISPLAY_NAME' => const AppFailure(FailureKind.invalidDisplayName),
    'WEAK_PASSWORD' => const AppFailure(FailureKind.weakPassword),
    'DATA_POLICY_NOT_ACCEPTED' => const AppFailure(
      FailureKind.dataPolicyNotAccepted,
    ),
    'ACCOUNTS_UNAVAILABLE' => const AppFailure(FailureKind.accountsUnavailable),
    _ => AppFailure(fallback),
  };
}
