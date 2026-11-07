// Pruebas del cliente HTTP de la API (tarea T023; contracts/api.md).
//
// Se usa MockClient: responde como lo haría la API sin salir a la red. Se comprueba la
// forma de cada solicitud y la traducción de cada error a un mensaje para el usuario
// (constitución §5, UI; Historia 1, escenarios 8, 10 y 12).

import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:handtext_ai/models/app_failure.dart';
import 'package:handtext_ai/models/export_format.dart';
import 'package:handtext_ai/models/image_format.dart';
import 'package:handtext_ai/services/handtext_api_client.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import '../support/fakes.dart';

HandTextApiClient _client(
  MockClientHandler handler, {
  Duration timeout = const Duration(seconds: 5),
  String baseUrl = 'http://api.test/',
}) => HandTextApiClient(
  baseUrl: Uri.parse(baseUrl),
  httpClient: MockClient(handler),
  recognitionTimeout: timeout,
  exportTimeout: timeout,
);

http.Response _json(Object body, [int status = 200]) => http.Response.bytes(
  utf8.encode(jsonEncode(body)),
  status,
  headers: {'content-type': 'application/json'},
);

http.Response _apiError(String code, int status, [String message = 'm']) =>
    _json({
      'error': {'code': code, 'message': message, 'request_id': 'r'},
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
  group('reconocimiento', () {
    test('envía la imagen como cuerpo binario con su tipo', () async {
      late http.Request sent;
      final client = _client((request) async {
        sent = request;
        return _json({
          'status': 'text_found',
          'text': 'Hola',
          'request_id': 'r',
        });
      });

      final result = await client.recognize(fakePngBytes(), ImageFormat.png);

      expect((result.hasText, result.text), (true, 'Hola'));
      expect(sent.method, 'POST');
      expect(sent.url.toString(), 'http://api.test/api/v1/recognitions');
      expect(sent.headers['content-type'], 'image/png');
      expect(sent.bodyBytes, fakePngBytes());
    });

    test('respeta una URL base con ruta', () async {
      late Uri url;
      final client = _client((request) async {
        url = request.url;
        return _json({'status': 'no_text', 'text': '', 'request_id': 'r'});
      }, baseUrl: 'http://servidor.test/handtext/');

      await client.recognize(fakeJpegBytes(), ImageFormat.jpeg);

      expect(
        url.toString(),
        'http://servidor.test/handtext/api/v1/recognitions',
      );
    });

    test('[H1-E7] «no_text» o texto en blanco significa sin texto', () async {
      for (final body in [
        {'status': 'no_text', 'text': '', 'request_id': 'r'},
        {'status': 'text_found', 'text': '  \n ', 'request_id': 'r'},
      ]) {
        final result = await _client(
          (_) async => _json(body),
        ).recognize(fakePngBytes(), ImageFormat.png);
        expect(result.hasText, isFalse);
      }
    });

    test('[EX-H1-E1] trae las palabras dudosas en posiciones de Dart', () async {
      // Spec 003: «😀» ocupa 1 punto de código en la API y 2 unidades en Dart.
      final result = await _client(
        (_) async => _json({
          'status': 'text_found',
          'text': '😀 Hola mundo',
          'uncertain_words': [
            {'start': 7, 'end': 12},
          ],
          'request_id': 'r',
        }),
      ).recognize(fakePngBytes(), ImageFormat.png);

      expect(result.text, '😀 Hola mundo');
      expect(result.uncertainRanges.single.textInside(result.text), 'mundo');
    });

    test(
      '[EX-H1-E8] sin el campo de marcas, el texto llega sin marcas',
      () async {
        final result = await _client(
          (_) async => _json({
            'status': 'text_found',
            'text': 'Hola',
            'request_id': 'r',
          }),
        ).recognize(fakePngBytes(), ImageFormat.png);

        expect(result.text, 'Hola');
        expect(result.uncertainRanges, isEmpty);
      },
    );

    final errorCases = <(String, int, FailureKind)>[
      ('IMAGE_TOO_LARGE', 413, FailureKind.imageTooLarge),
      ('UNSUPPORTED_IMAGE_TYPE', 415, FailureKind.unsupportedImageType),
      ('IMAGE_UNREADABLE', 400, FailureKind.imageUnreadable),
      (
        'IMAGE_DIMENSIONS_OUT_OF_RANGE',
        400,
        FailureKind.imageDimensionsOutOfRange,
      ),
      ('OCR_NOT_CONFIGURED', 503, FailureKind.serviceUnavailable),
      ('OCR_TIMEOUT', 504, FailureKind.recognitionTimeout),
      ('OCR_PROVIDER_ERROR', 502, FailureKind.recognitionFailed),
      ('OCR_INVALID_RESPONSE', 502, FailureKind.recognitionFailed),
    ];
    for (final (code, status, kind) in errorCases) {
      test('[H1-E8] el código $code se traduce a $kind', () async {
        final client = _client((_) async => _apiError(code, status));

        expect(
          await _failureOf(client.recognize(fakePngBytes(), ImageFormat.png)),
          kind,
        );
      });
    }

    test('un error sin JSON usa el fallo genérico', () async {
      final client = _client((_) async => http.Response('Bad Gateway', 502));

      expect(
        await _failureOf(client.recognize(fakePngBytes(), ImageFormat.png)),
        FailureKind.recognitionFailed,
      );
    });

    test('una respuesta 200 inesperada es una respuesta no válida', () async {
      for (final response in [
        http.Response('<html>', 200),
        _json({'status': 'otro', 'text': 'x'}),
        _json({'status': 'text_found', 'text': 5}),
      ]) {
        final client = _client((_) async => response);
        expect(
          await _failureOf(client.recognize(fakePngBytes(), ImageFormat.png)),
          FailureKind.invalidServerResponse,
        );
      }
    });

    test('[SC-009] más de lo permitido es «tiempo agotado»', () async {
      final client = _client((_) async {
        await Future<void>.delayed(const Duration(milliseconds: 200));
        return _json({'status': 'no_text', 'text': '', 'request_id': 'r'});
      }, timeout: const Duration(milliseconds: 20));

      expect(
        await _failureOf(client.recognize(fakePngBytes(), ImageFormat.png)),
        FailureKind.recognitionTimeout,
      );
    });

    test('sin red se informa la falta de conexión', () async {
      for (final error in [
        const SocketException('sin red'),
        http.ClientException('conexión rechazada'),
      ]) {
        final client = _client((_) async => throw error);
        expect(
          await _failureOf(client.recognize(fakePngBytes(), ImageFormat.png)),
          FailureKind.noConnection,
        );
      }
    });
  });

  group('exportación', () {
    test('[H1-E9] envía el texto y el formato y devuelve el archivo', () async {
      late http.Request sent;
      final docx = Uint8List.fromList([0x50, 0x4B, 0x03, 0x04, 1, 2, 3]);
      final client = _client((request) async {
        sent = request;
        return http.Response.bytes(docx, 200);
      });

      final bytes = await client.export('Texto ñ ¿?', ExportFormat.docx);

      expect(bytes, docx);
      expect(sent.url.path, '/api/v1/exports');
      expect(sent.headers['content-type'], startsWith('application/json'));
      expect(jsonDecode(utf8.decode(sent.bodyBytes)), {
        'text': 'Texto ñ ¿?',
        'format': 'docx',
      });
    });

    test('[SC-001] rechaza un archivo que no es del formato pedido', () async {
      final client = _client(
        (_) async => http.Response.bytes(utf8.encode('no es un pdf'), 200),
      );

      expect(
        await _failureOf(client.export('Hola', ExportFormat.pdf)),
        FailureKind.exportFailed,
      );
    });

    test('[H1-E10] el texto vacío rechazado por la API se explica', () async {
      final client = _client((_) async => _apiError('EMPTY_TEXT', 400));

      expect(
        await _failureOf(client.export(' ', ExportFormat.docx)),
        FailureKind.emptyText,
      );
    });

    test('los caracteres no representables conservan el detalle', () async {
      const message = 'El texto contiene caracteres que no se pueden incluir…';
      final client = _client(
        (_) async => _apiError('UNSUPPORTED_CHARACTERS', 400, message),
      );

      try {
        await client.export('Hola 漢', ExportFormat.pdf);
        fail('Se esperaba un AppFailure');
      } on AppFailure catch (failure) {
        expect(failure.kind, FailureKind.unsupportedCharacters);
        expect(failure.detail, message);
      }
    });

    test('[H1-E12] un error del servidor es un fallo de exportación', () async {
      final client = _client((_) async => _apiError('INTERNAL_ERROR', 500));

      expect(
        await _failureOf(client.export('Hola', ExportFormat.docx)),
        FailureKind.exportFailed,
      );
    });

    test('la espera excesiva es «tiempo agotado» de exportación', () async {
      final client = _client((_) async {
        await Future<void>.delayed(const Duration(milliseconds: 200));
        return http.Response.bytes([0x50, 0x4B], 200);
      }, timeout: const Duration(milliseconds: 20));

      expect(
        await _failureOf(client.export('Hola', ExportFormat.docx)),
        FailureKind.exportTimeout,
      );
    });
  });
}
