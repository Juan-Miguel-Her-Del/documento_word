// Pruebas del controlador del flujo (tarea T025).
//
// Cada prueba indica el escenario del spec que verifica: [H1-E9] = Historia 1,
// escenario 9; [SC-007] = criterio de éxito 7.

import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:handtext_ai/models/app_failure.dart';
import 'package:handtext_ai/models/export_format.dart';
import 'package:handtext_ai/models/operation_status.dart';
import 'package:handtext_ai/models/picked_image.dart';
import 'package:handtext_ai/models/recognition_result.dart';
import 'package:handtext_ai/services/file_save_service.dart';
import 'package:handtext_ai/state/document_flow_controller.dart';

import '../support/fakes.dart';

void main() {
  group('arranque', () {
    test('[H1-E15] recupera el borrador y abre el editor', () async {
      final h = TestHarness()..drafts.stored = 'Texto sin exportar';

      await h.controller.initialize();

      expect(h.workingCopies.purges, 1); // copias antiguas eliminadas
      expect(h.controller.isReady, isTrue);
      expect(h.controller.step, FlowStep.editor);
      expect(h.controller.documentText, 'Texto sin exportar');
      expect(h.controller.status?.event, StatusEvent.draftRestored);
    });

    test('sin borrador (o vacío) empieza en el inicio', () async {
      final h = TestHarness()..drafts.stored = '   ';

      await h.controller.initialize();

      expect(h.controller.step, FlowStep.start);
      expect(h.controller.hasDocument, isFalse);
    });
  });

  group('selección de imagen (spec, módulo 1)', () {
    test('[H1-E2] una imagen válida va a la vista previa', () async {
      final h = TestHarness();
      await h.controller.initialize();

      await h.controller.pickFromGallery();

      final image = h.controller.pendingImage!;
      expect(h.controller.step, FlowStep.preview);
      expect((image.width, image.height), (1200, 1600));
      expect(image.origin, ImageOrigin.gallery);
      expect(
        h.workingCopies.created,
        hasLength(1),
      ); // se trabaja sobre una copia
    });

    test('cancelar el selector no cambia nada', () async {
      final h = TestHarness();
      h.imageSource.galleryResult = null;
      await h.controller.initialize();

      await h.controller.pickFromGallery();

      expect(h.controller.step, FlowStep.start);
      expect(h.workingCopies.created, isEmpty);
    });

    test('[H1-E1] una imagen pequeña se rechaza con el motivo', () async {
      final h = TestHarness(imageWidth: 400, imageHeight: 300);
      await h.controller.initialize();

      await h.controller.pickFromGallery();

      expect(h.controller.step, FlowStep.start);
      expect(
        h.controller.status?.failure?.kind,
        FailureKind.imageDimensionsOutOfRange,
      );
      expect(h.workingCopies.deleted, h.workingCopies.created); // copia borrada
    });

    test('[H1-E1] un archivo que no es JPEG ni PNG se rechaza', () async {
      final h = TestHarness();
      h.imageSource.galleryResult = pickedFile(fakePngBytes()..[0] = 0x00);
      await h.controller.initialize();

      await h.controller.pickFromGallery();

      expect(
        h.controller.status?.failure?.kind,
        FailureKind.unsupportedImageType,
      );
    });

    test(
      'cancelar la vista previa borra la copia y vuelve al inicio',
      () async {
        final h = TestHarness();
        await h.controller.initialize();
        await h.controller.pickFromGallery();

        await h.controller.cancelPreview();

        expect(h.controller.step, FlowStep.start);
        expect(h.controller.pendingImage, isNull);
        expect(h.workingCopies.deleted, h.workingCopies.created);
      },
    );

    test('reemplazar elige otra imagen y borra la copia anterior', () async {
      final h = TestHarness();
      await h.controller.initialize();
      await h.controller.pickFromGallery();
      final first = h.controller.pendingImage!.workingCopy;

      await h.controller.replaceImage();

      expect(h.imageSource.galleryCalls, 2);
      expect(h.controller.pendingImage!.workingCopy, isNot(first));
      expect(h.workingCopies.deleted, [first]);
    });
  });

  group('reconocimiento (spec, módulo 2)', () {
    test('[H1-E4] [SC-004] sin autorización no se envía nada', () async {
      final h = TestHarness();
      await h.controller.initialize();
      await h.controller.pickFromGallery();

      await h.controller.recognize(consentGranted: false);

      expect(h.api.recognizedImages, isEmpty);
      expect(h.controller.step, FlowStep.preview);
      expect(h.controller.status?.event, StatusEvent.consentDeclined);
    });

    test('[H1-E6] con texto, abre el editor y guarda el borrador', () async {
      final h = TestHarness();

      await h.reachEditor(text: 'Apuntes de clase');

      expect(h.controller.step, FlowStep.editor);
      expect(h.controller.documentText, 'Apuntes de clase');
      expect(h.controller.status?.event, StatusEvent.recognized);
      expect(h.drafts.stored, 'Apuntes de clase');
      expect(h.workingCopies.deleted, h.workingCopies.created); // retención
    });

    test('[H1-E7] sin texto, se queda en la vista previa con aviso', () async {
      final h = TestHarness();
      h.api.recognitionResult = const RecognitionResult(
        hasText: false,
        text: '',
      );
      await h.controller.initialize();
      await h.controller.pickFromGallery();

      await h.controller.recognize(consentGranted: true);

      expect(h.controller.step, FlowStep.preview);
      expect(h.controller.status?.event, StatusEvent.noTextFound);
      expect(h.controller.status?.action, StatusAction.replaceImage);
      expect(h.controller.hasDocument, isFalse); // no hay documento vacío
    });

    test('[H1-E8] un fallo se explica y ofrece reintentar', () async {
      final h = TestHarness();
      h.api.recognitionError = const AppFailure(FailureKind.recognitionTimeout);
      await h.controller.initialize();
      await h.controller.pickFromGallery();

      await h.controller.recognize(consentGranted: true);

      expect(h.controller.step, FlowStep.preview);
      expect(
        h.controller.status?.failure?.kind,
        FailureKind.recognitionTimeout,
      );
      expect(h.controller.status?.action, StatusAction.retryRecognition);
    });

    test(
      '[H1-E5] [SC-008] los toques repetidos inician una sola operación',
      () async {
        final h = TestHarness();
        await h.controller.initialize();
        await h.controller.pickFromGallery();
        h.api.recognitionGate = Completer<void>();

        final first = h.controller.recognize(consentGranted: true);
        expect(h.controller.isBusy, isTrue);
        expect(h.controller.status?.kind, StatusKind.inProgress);
        await h.controller.recognize(consentGranted: true); // ignorado
        await h.controller.pickFromGallery(); // ignorado
        h.api.recognitionGate!.complete();
        await first;

        expect(h.api.recognizedImages, hasLength(1));
        expect(h.imageSource.galleryCalls, 1);
      },
    );
  });

  group('otra imagen con un texto en edición [H1-E13]', () {
    test(
      'si el nuevo reconocimiento falla, las correcciones se conservan',
      () async {
        final h = TestHarness();
        await h.reachEditor(text: 'Original');
        h.controller.updateText('Original corregido');

        h.controller.startAnotherImage();
        expect(h.controller.step, FlowStep.start);
        expect(h.controller.documentText, 'Original corregido');

        h.api.recognitionError = const AppFailure(FailureKind.noConnection);
        await h.controller.pickFromGallery();
        await h.controller.recognize(consentGranted: true);

        expect(h.controller.documentText, 'Original corregido');
      },
    );

    test('cancelar permite volver al texto actual', () async {
      final h = TestHarness();
      await h.reachEditor(text: 'Original');
      h.controller.startAnotherImage();
      await h.controller.pickFromGallery();

      await h.controller.cancelPreview();
      h.controller.returnToDocument();

      expect(h.controller.step, FlowStep.editor);
      expect(h.controller.documentText, 'Original');
    });

    test(
      'si el nuevo reconocimiento termina bien, reemplaza el texto',
      () async {
        final h = TestHarness();
        await h.reachEditor(text: 'Original');
        h.controller.startAnotherImage();
        h.api.recognitionResult = const RecognitionResult(
          hasText: true,
          text: 'Nuevo',
        );

        await h.controller.pickFromGallery();
        await h.controller.recognize(consentGranted: true);

        expect(h.controller.documentText, 'Nuevo');
      },
    );
  });

  group('exportación (spec, módulo 4)', () {
    test('[H1-E9] se exporta el texto actual del editor', () async {
      final h = TestHarness();
      await h.reachEditor(text: 'Texto con eror');
      h.controller.updateText('Texto con error corregido\n\nSegundo párrafo');

      await h.controller.export(ExportFormat.docx);

      expect(h.api.exports.single, (
        'Texto con error corregido\n\nSegundo párrafo',
        ExportFormat.docx,
      ));
      // Spec 010: el nombre propuesto es el título (la primera línea) [OR-H1-E1].
      expect(h.fileSaver.savedNames.single, 'Texto con error corregido.docx');
      expect(h.controller.status?.event, StatusEvent.saved);
    });

    test('[H1-E10] [SC-007] un texto vacío no se exporta', () async {
      final h = TestHarness();
      await h.reachEditor();
      h.controller.updateText('  \n\t ');

      await h.controller.export(ExportFormat.pdf);

      expect(h.api.exports, isEmpty);
      expect(h.controller.status?.failure?.kind, FailureKind.emptyText);
    });

    test(
      '[H1-E12] [SC-003] un fallo no se anuncia como éxito ni borra el texto',
      () async {
        final h = TestHarness();
        await h.reachEditor(text: 'Mis apuntes');
        h.fileSaver.error = const AppFailure(FailureKind.saveFailed);

        await h.controller.export(ExportFormat.docx);

        expect(h.controller.status?.kind, StatusKind.failure);
        expect(h.controller.documentText, 'Mis apuntes');
        expect(h.drafts.stored, 'Mis apuntes'); // el borrador sigue
      },
    );

    test('cancelar el diálogo de guardado no es éxito ni error', () async {
      final h = TestHarness();
      await h.reachEditor(text: 'Mis apuntes');
      h.fileSaver.outcome = const SaveCancelled();

      await h.controller.export(ExportFormat.pdf);

      expect(h.controller.status?.event, StatusEvent.saveCancelled);
      expect(h.drafts.stored, 'Mis apuntes');
    });

    test(
      '[H1-E16] [SC-011] tras exportar se borra el borrador y vuelve si se edita',
      () async {
        final h = TestHarness();
        await h.reachEditor(text: 'Mis apuntes');

        await h.controller.export(ExportFormat.docx);
        expect(h.drafts.stored, isNull);

        h.controller.updateText('Mis apuntes, con un cambio');
        await h.controller.flushDraft();
        expect(h.drafts.stored, 'Mis apuntes, con un cambio');
      },
    );
  });

  test('[H1-E17] descartar elimina el texto y su borrador', () async {
    final h = TestHarness();
    await h.reachEditor(text: 'Mis apuntes');

    await h.controller.discardDocument();

    expect(h.controller.hasDocument, isFalse);
    expect(h.controller.step, FlowStep.start);
    expect(h.drafts.stored, isNull);
  });

  test('el nombre propuesto lleva fecha, hora y la extensión real', () {
    final moment = DateTime(2026, 1, 5, 7, 9);

    expect(
      suggestedFileName(ExportFormat.pdf, moment),
      'HandText_20260105_0709.pdf',
    );
  });

  group('sesión (spec 002)', () {
    test(
      '[CU-H2-E5] si la sesión vence al exportar, el borrador se guarda y se avisa',
      () async {
        final h = TestHarness();
        await h.reachEditor(text: 'Original');
        h.controller.updateText('Texto corregido sin exportar');
        h.api.exportError = const AppFailure(FailureKind.sessionExpired);

        await h.controller.export(ExportFormat.docx);

        expect(h.drafts.stored, 'Texto corregido sin exportar');
        expect(h.sessionExpiredCalls, 1);
      },
    );

    test('hay cambios sin exportar hasta que se exporta', () async {
      final h = TestHarness();
      await h.reachEditor();
      expect(h.controller.hasUnexportedChanges, isTrue);

      await h.controller.export(ExportFormat.pdf);

      expect(h.controller.hasUnexportedChanges, isFalse);
    });

    test('[CU-H2-E2] clearLocalData borra el texto y el borrador', () async {
      final h = TestHarness();
      await h.reachEditor(text: 'Privado');

      await h.controller.clearLocalData();

      expect(h.controller.hasDocument, isFalse);
      expect(h.controller.step, FlowStep.start);
      expect(h.drafts.stored, isNull);
    });
  });
}
