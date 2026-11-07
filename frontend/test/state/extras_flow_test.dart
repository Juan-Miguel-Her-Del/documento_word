// Pruebas del controlador para la funcionalidad 003 (tareas T209, T212 y T215).
//
// Palabras dudosas, recorte y giro, y compartir, con servicios falsos (sin red, sin
// cámara y sin el editor nativo). Cada prueba indica el escenario del spec 003 que
// verifica: [EX-H2-E4] = Historia 2, escenario 4.

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:handtext_ai/models/app_failure.dart';
import 'package:handtext_ai/models/export_format.dart';
import 'package:handtext_ai/models/operation_status.dart';
import 'package:handtext_ai/models/recognition_result.dart';
import 'package:handtext_ai/services/file_save_service.dart';
import 'package:handtext_ai/services/image_rules.dart';
import 'package:handtext_ai/state/document_flow_controller.dart';
import 'package:image_picker/image_picker.dart';

import '../support/fakes.dart';

/// «Tema 1: la célula», con «célula» como palabra dudosa.
const _text = 'Tema 1: la célula';
const _celula = TextRange(start: 11, end: 17);

/// Bytes del resultado del recorte: un JPEG distinto del original.
Uint8List _croppedBytes() =>
    Uint8List.fromList([0xFF, 0xD8, 0xFF, ...List.filled(10, 7)]);

/// Imagen original 1200 × 1600; el recorte mide lo que se indique.
ImageDimensionsReader _dimensions({int width = 900, int height = 700}) =>
    (bytes) async => bytes.length == _croppedBytes().length
    ? ImageDimensions(width, height)
    : const ImageDimensions(1200, 1600);

void main() {
  group('palabras dudosas (Historia 1)', () {
    test('[EX-H1-E1] el reconocimiento trae las marcas al editor', () async {
      final h = TestHarness();

      await h.reachEditor(text: _text, uncertain: const [_celula]);

      expect(h.controller.uncertainRanges, const [_celula]);
      expect(h.drafts.storedRanges, const [_celula]); // [EX-H1-E7]
    });

    test('[EX-H1-E4] corregir la palabra quita su marca', () async {
      final h = TestHarness();
      await h.reachEditor(text: _text, uncertain: const [_celula]);

      h.controller.updateText('Tema 1: la célula viva');
      expect(h.controller.uncertainRanges, const [_celula]); // sigue igual

      h.controller.updateText('Tema 1: la celula viva');
      expect(h.controller.uncertainRanges, isEmpty);
    });

    test(
      '[EX-H1-E4] escribir antes desplaza la marca con su palabra',
      () async {
        final h = TestHarness();
        await h.reachEditor(text: _text, uncertain: const [_celula]);

        h.controller.updateText('Hoy: $_text');

        final range = h.controller.uncertainRanges.single;
        expect(range.textInside(h.controller.documentText!), 'célula');
      },
    );

    test(
      '[EX-H1-E5] «Está bien» quita la marca sin cambiar el texto',
      () async {
        final h = TestHarness();
        await h.reachEditor(text: _text, uncertain: const [_celula]);

        h.controller.acceptUncertainWord(_celula);
        await h.controller.flushDraft();

        expect(h.controller.uncertainRanges, isEmpty);
        expect(h.controller.documentText, _text);
        expect(
          h.drafts.storedRanges,
          isEmpty,
        ); // el borrador también se actualiza
      },
    );

    test('[EX-H1-E6] [SC-303] se exporta solo el texto, sin marcas', () async {
      final h = TestHarness();
      await h.reachEditor(text: _text, uncertain: const [_celula]);

      await h.controller.export(ExportFormat.pdf);

      expect(h.api.exports.single.$1, _text);
    });

    test('[EX-H1-E7] el borrador recupera las marcas que quedaban', () async {
      final h = TestHarness()
        ..drafts.stored = _text
        ..drafts.storedRanges = const [_celula, TextRange(start: 50, end: 60)];

      await h.controller.initialize();

      // La marca que no cabe en el texto se descarta.
      expect(h.controller.uncertainRanges, const [_celula]);
    });

    test('un nuevo reconocimiento reemplaza las marcas anteriores', () async {
      final h = TestHarness();
      await h.reachEditor(text: _text, uncertain: const [_celula]);
      h.controller.startAnotherImage();
      h.api.recognitionResult = const RecognitionResult(
        hasText: true,
        text: 'Otro texto',
      );

      await h.controller.pickFromGallery();
      await h.controller.recognize(consentGranted: true);

      expect(h.controller.documentText, 'Otro texto');
      expect(h.controller.uncertainRanges, isEmpty);
    });
  });

  group('recortar y girar (Historia 2)', () {
    Future<TestHarness> preview({int width = 900, int height = 700}) async {
      final h = TestHarness(
        readDimensions: _dimensions(width: width, height: height),
      );
      h.imageEditor.result = XFile.fromData(_croppedBytes(), name: 'r.jpg');
      await h.controller.initialize();
      await h.controller.pickFromGallery();
      return h;
    }

    test('[EX-H2-E1] [EX-H2-E2] el recorte reemplaza la imagen de la vista '
        'previa', () async {
      final h = await preview();
      final original = h.controller.pendingImage!;

      await h.controller.editImage();

      // Se editó la copia de trabajo, nunca el original [EX-H2-E7].
      expect(h.imageEditor.edited.single, original.workingCopy);
      final edited = h.controller.pendingImage!;
      expect(edited.bytes, _croppedBytes());
      expect((edited.width, edited.height), (900, 700));
      expect(h.controller.canRestoreOriginalImage, isTrue);
      expect(h.controller.status, isNull);
    });

    test('[EX-H2-E3] cancelar el recorte no cambia nada', () async {
      final h = await preview();
      final original = h.controller.pendingImage;
      h.imageEditor.result = null;

      await h.controller.editImage();

      expect(h.controller.pendingImage, same(original));
      expect(h.controller.canRestoreOriginalImage, isFalse);
    });

    test('[EX-H2-E4] un recorte de menos de 600 px se rechaza y se conserva la '
        'imagen', () async {
      final h = await preview(width: 500, height: 400);
      final original = h.controller.pendingImage;

      await h.controller.editImage();

      expect(h.controller.pendingImage, same(original));
      expect(
        h.controller.status?.failure?.kind,
        FailureKind.imageDimensionsOutOfRange,
      );
      // La copia del recorte rechazado se borra.
      expect(h.workingCopies.deleted.single.bytes, _croppedBytes());
    });

    test('si el editor falla, se explica y se conserva la imagen', () async {
      final h = await preview();
      final original = h.controller.pendingImage;
      h.imageEditor.error = const AppFailure(FailureKind.imageEditFailed);

      await h.controller.editImage();

      expect(h.controller.pendingImage, same(original));
      expect(h.controller.status?.failure?.kind, FailureKind.imageEditFailed);
    });

    test(
      '[EX-H2-E5] «Usar la imagen original» la recupera y borra el recorte',
      () async {
        final h = await preview();
        final original = h.controller.pendingImage;
        await h.controller.editImage();
        final edited = h.controller.pendingImage!;

        await h.controller.restoreOriginalImage();

        expect(h.controller.pendingImage, same(original));
        expect(h.controller.canRestoreOriginalImage, isFalse);
        expect(h.workingCopies.deleted, [edited.workingCopy]);
      },
    );

    test('[EX-H2-E6] [SC-304] se reconoce el recorte y luego se borran las dos '
        'copias', () async {
      final h = await preview();
      final original = h.controller.pendingImage!;
      await h.controller.editImage();
      final edited = h.controller.pendingImage!;

      await h.controller.recognize(consentGranted: true);

      expect(h.api.recognizedImages.single, _croppedBytes());
      expect(
        h.workingCopies.deleted,
        containsAll([edited.workingCopy, original.workingCopy]),
      );
    });

    test(
      '[SC-304] cancelar después de recortar borra las dos copias',
      () async {
        final h = await preview();
        final original = h.controller.pendingImage!;
        await h.controller.editImage();
        final edited = h.controller.pendingImage!;

        await h.controller.cancelPreview();

        expect(
          h.workingCopies.deleted,
          containsAll([edited.workingCopy, original.workingCopy]),
        );
        expect(h.controller.canRestoreOriginalImage, isFalse);
      },
    );
  });

  group('compartir (Historia 3)', () {
    test(
      '[EX-H3-E1] [EX-H3-E2] [SC-305] después de guardar se comparte el mismo '
      'archivo',
      () async {
        final h = TestHarness();
        await h.reachEditor();
        h.api.exportBytes = Uint8List.fromList([
          0x25,
          0x50,
          0x44,
          0x46,
          0x2D,
          1,
        ]);

        await h.controller.export(ExportFormat.pdf);
        expect(h.controller.status?.action, StatusAction.shareExport);

        await h.controller.shareLastExport();
        await h.controller.shareLastExport(); // [EX-H3-E3] se puede repetir

        final (bytes, name, format) = h.sharer.shared.first;
        expect(bytes, h.api.exportBytes);
        expect(name, h.fileSaver.savedNames.single);
        expect(format, ExportFormat.pdf);
        expect(h.sharer.shared, hasLength(2));
      },
    );

    test('[EX-H3-E4] sin guardar no se ofrece compartir', () async {
      final h = TestHarness();
      await h.reachEditor();
      h.fileSaver.outcome = const SaveCancelled();

      await h.controller.export(ExportFormat.docx);
      await h.controller.shareLastExport();

      expect(h.controller.status?.action, isNull);
      expect(h.sharer.shared, isEmpty);
    });

    test('[EX-H3-E4] si la exportación falla no se ofrece compartir', () async {
      final h = TestHarness();
      await h.reachEditor();
      h.api.exportError = const AppFailure(FailureKind.exportFailed);

      await h.controller.export(ExportFormat.docx);

      expect(h.controller.status?.action, isNot(StatusAction.shareExport));
    });

    test(
      '[EX-H3-E6] después de editar ya no se comparte el archivo viejo',
      () async {
        final h = TestHarness();
        await h.reachEditor();
        await h.controller.export(ExportFormat.docx);

        h.controller.updateText('Texto reconocido, con un cambio');
        await h.controller.shareLastExport();

        expect(h.sharer.shared, isEmpty);
      },
    );

    test(
      '[EX-H3-E5] la copia para compartir se borra al abrir la app y al cerrar '
      'sesión',
      () async {
        final h = TestHarness();
        await h.controller.initialize();
        expect(h.sharer.purges, 1);

        await h.controller.clearLocalData();

        expect(h.sharer.purges, 2);
      },
    );

    test(
      'si no se puede compartir, se explica y se puede reintentar',
      () async {
        final h = TestHarness();
        await h.reachEditor();
        await h.controller.export(ExportFormat.docx);
        h.sharer.error = const AppFailure(FailureKind.shareFailed);

        await h.controller.shareLastExport();

        expect(h.controller.status?.failure?.kind, FailureKind.shareFailed);
        expect(h.controller.status?.action, StatusAction.shareExport);
        expect(h.controller.step, FlowStep.editor); // el texto sigue ahí
      },
    );
  });
}
