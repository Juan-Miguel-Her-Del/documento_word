// Pruebas de las reglas de imagen de la app (tarea T022; spec, módulo 1; H1-E1).

import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:handtext_ai/config/app_config.dart';
import 'package:handtext_ai/models/app_failure.dart';
import 'package:handtext_ai/models/image_format.dart';
import 'package:handtext_ai/services/image_rules.dart';

import '../support/fakes.dart';
import '../support/synthetic_png.dart';

/// PNG sintético real de 7 × 5 píxeles (blanco).
final _tinyPng = syntheticPng(7, 5);

Future<FailureKind> _rejection(
  Uint8List bytes, {
  int width = 1000,
  int height = 1000,
}) async {
  try {
    await validateSelectedImage(
      bytes,
      readDimensions: fixedDimensions(width, height),
    );
  } on AppFailure catch (failure) {
    return failure.kind;
  }
  fail('Se esperaba un rechazo');
}

void main() {
  group('detectImageFormat (por contenido, no por extensión)', () {
    test('reconoce JPEG y PNG por su firma', () {
      expect(detectImageFormat(fakeJpegBytes()), ImageFormat.jpeg);
      expect(detectImageFormat(fakePngBytes()), ImageFormat.png);
    });

    test('rechaza cualquier otro contenido', () {
      expect(
        detectImageFormat(Uint8List.fromList(utf8.encode('GIF89a'))),
        isNull,
      );
      expect(detectImageFormat(Uint8List(0)), isNull);
    });
  });

  group('validateSelectedImage', () {
    test('acepta los límites exactos de 600 y 10 000 px', () async {
      final small = await validateSelectedImage(
        fakePngBytes(),
        readDimensions: fixedDimensions(600, 600),
      );
      final large = await validateSelectedImage(
        fakeJpegBytes(),
        readDimensions: fixedDimensions(10000, 10000),
      );

      expect((small.format, small.width), (ImageFormat.png, 600));
      expect((large.format, large.height), (ImageFormat.jpeg, 10000));
    });

    test('rechaza lados fuera de 600–10 000 px', () async {
      expect(
        await _rejection(fakePngBytes(), width: 599),
        FailureKind.imageDimensionsOutOfRange,
      );
      expect(
        await _rejection(fakePngBytes(), height: 10001),
        FailureKind.imageDimensionsOutOfRange,
      );
    });

    test('rechaza archivos de más de 10 MB', () async {
      final bytes = Uint8List(AppConfig.maxImageBytes + 1)
        ..setAll(0, [0xFF, 0xD8, 0xFF]);

      expect(await _rejection(bytes), FailureKind.imageTooLarge);
    });

    test('rechaza contenido que no es JPEG ni PNG', () async {
      final pdf = Uint8List.fromList(utf8.encode('%PDF-1.7'));

      expect(await _rejection(pdf), FailureKind.unsupportedImageType);
    });

    test('un archivo vacío o ilegible no se puede abrir', () async {
      expect(await _rejection(Uint8List(0)), FailureKind.imageUnreadable);
      final unreadable =
          await validateSelectedImage(
            fakePngBytes(),
            readDimensions: (_) => Future.error(Exception('encabezado dañado')),
          ).then<FailureKind?>(
            (_) => null,
            onError: (Object e) => (e as AppFailure).kind,
          );
      expect(unreadable, FailureKind.imageUnreadable);
    });
  });

  group('readImageDimensionsWithEngine (motor real de Flutter)', () {
    testWidgets('lee ancho y alto del encabezado', (tester) async {
      final dimensions = await tester.runAsync(
        () => readImageDimensionsWithEngine(_tinyPng),
      );

      expect((dimensions!.width, dimensions.height), (7, 5));
    });

    testWidgets('falla con datos que no son una imagen', (tester) async {
      Object? error;
      await tester.runAsync(() async {
        try {
          await readImageDimensionsWithEngine(fakePngBytes());
        } catch (e) {
          error = e;
        }
      });

      expect(error, isNotNull);
    });
  });
}
