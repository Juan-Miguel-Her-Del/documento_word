// Cliente de la API de documentos (tareas T038 y T121; contracts/api.md).
//
// - recognize: envía la imagen como cuerpo binario a POST /api/v1/recognitions.
// - export: envía el texto confirmado a POST /api/v1/exports y recibe el archivo.
// - Spec 002: cada solicitud lleva `Authorization: Bearer <token>` de la sesión. Si la
//   API responde 401, el fallo es `sessionExpired` y la app pide ingresar de nuevo.
// - Los errores se traducen con api_errors.dart (mensajes en español, constitución §5).
// - Espera como máximo 60 segundos (SC-009).
// - Spec 003: la respuesta de reconocimiento trae también las palabras dudosas.

import 'dart:convert';
import 'dart:typed_data';

import 'package:http/http.dart' as http;

import '../config/app_config.dart';
import '../models/app_failure.dart';
import '../models/export_format.dart';
import '../models/image_format.dart';
import '../models/recognition_result.dart';
import 'api_errors.dart';
import 'uncertain_ranges.dart';

/// Lo que el controlador necesita de la API. Las pruebas usan una versión falsa.
abstract interface class HandTextApi {
  Future<RecognitionResult> recognize(Uint8List imageBytes, ImageFormat format);

  Future<Uint8List> export(String text, ExportFormat format);
}

class HandTextApiClient implements HandTextApi {
  HandTextApiClient({
    required Uri baseUrl,
    String? Function()? tokenProvider,
    String localDevToken = AppConfig.localDevApiToken,
    http.Client? httpClient,
    Duration recognitionTimeout = AppConfig.recognitionTimeout,
    Duration exportTimeout = AppConfig.exportTimeout,
  }) : _baseUrl = baseUrl,
       _tokenProvider = tokenProvider,
       _localDevToken = localDevToken,
       _client = httpClient ?? http.Client(),
       _recognitionTimeout = recognitionTimeout,
       _exportTimeout = exportTimeout;

  final Uri _baseUrl;

  /// Devuelve el token del backend, si existe. Las cuentas locales no emiten uno válido
  /// para los endpoints remotos de documentos.
  final String? Function()? _tokenProvider;
  final String _localDevToken;
  final http.Client _client;
  final Duration _recognitionTimeout;
  final Duration _exportTimeout;

  /// Cabecera de autenticación [SC-202] más las cabeceras propias de la solicitud.
  Map<String, String> _headers(Map<String, String> extra) {
    final token = _tokenProvider?.call();
    if (token == null && _localDevToken.isNotEmpty) {
      return {'X-HandText-Local-Dev': _localDevToken, ...extra};
    }
    return {if (token != null) 'Authorization': 'Bearer $token', ...extra};
  }

  @override
  Future<RecognitionResult> recognize(
    Uint8List imageBytes,
    ImageFormat format,
  ) async {
    final response = await sendRequest(
      () => _client.post(
        _baseUrl.resolve('api/v1/recognitions'),
        headers: _headers({
          'Content-Type': format.mimeType,
          'Accept': 'application/json',
        }),
        body: imageBytes,
      ),
      timeout: _recognitionTimeout,
      timeoutFailure: FailureKind.recognitionTimeout,
    );
    if (response.statusCode != 200) {
      throw _failureFromResponse(
        response,
        fallback: FailureKind.recognitionFailed,
      );
    }
    return _parseRecognition(response);
  }

  @override
  Future<Uint8List> export(String text, ExportFormat format) async {
    final response = await sendRequest(
      () => _client.post(
        _baseUrl.resolve('api/v1/exports'),
        headers: _headers({'Content-Type': 'application/json; charset=utf-8'}),
        body: jsonEncode({'text': text, 'format': format.apiValue}),
      ),
      timeout: _exportTimeout,
      timeoutFailure: FailureKind.exportTimeout,
    );
    if (response.statusCode != 200) {
      throw _failureFromResponse(response, fallback: FailureKind.exportFailed);
    }
    final bytes = response.bodyBytes;
    // SC-001: lo recibido debe ser de verdad un .docx o un .pdf.
    if (!format.matchesContent(bytes)) {
      throw const AppFailure(FailureKind.exportFailed);
    }
    return bytes;
  }

  AppFailure _failureFromResponse(
    http.Response response, {
    required FailureKind fallback,
  }) {
    final failure = failureFromResponse(response, fallback: fallback);
    if (_tokenProvider == null && failure.kind == FailureKind.sessionExpired) {
      return const AppFailure(FailureKind.backendAuthenticationRequired);
    }
    return failure;
  }

  /// Interpreta la respuesta 200 del reconocimiento.
  RecognitionResult _parseRecognition(http.Response response) {
    final Object? body;
    try {
      body = decodeJson(response);
    } on FormatException {
      throw const AppFailure(FailureKind.invalidServerResponse);
    }
    return switch (body) {
      {'status': 'text_found', 'text': final String text} && final Map map
          when text.trim().isNotEmpty =>
        RecognitionResult(
          hasText: true,
          text: text,
          // Spec 003: marcas de palabras dudosas (las inválidas se descartan).
          uncertainRanges: rangesFromApi(text, map['uncertain_words']),
        ),
      {'status': 'text_found' || 'no_text', 'text': String _} =>
        const RecognitionResult(hasText: false, text: ''),
      _ => throw const AppFailure(FailureKind.invalidServerResponse),
    };
  }
}
