// Pruebas de la captura con cámara y sus permisos (tarea T045; Historia 2).

import 'package:flutter_test/flutter_test.dart';
import 'package:handtext_ai/models/app_failure.dart';
import 'package:handtext_ai/models/operation_status.dart';
import 'package:handtext_ai/models/picked_image.dart';
import 'package:handtext_ai/models/recognition_result.dart';
import 'package:handtext_ai/services/camera_permission_service.dart';
import 'package:handtext_ai/state/document_flow_controller.dart';

import '../support/strings_es.dart';
import '../support/fakes.dart';

void main() {
  test(
    '[H2-E1] [H2-E4] con permiso, la foto llega a la vista previa',
    () async {
      final h = TestHarness();
      await h.controller.initialize();

      await h.controller.takePhoto();

      expect(h.cameraPermission.requests, 1);
      expect(h.imageSource.cameraCalls, 1);
      expect(h.controller.step, FlowStep.preview);
      expect(h.controller.pendingImage?.origin, ImageOrigin.camera);
    },
  );

  test(
    '[H2-E2] sin permiso no se abre la cámara y se explica por qué',
    () async {
      final h = TestHarness();
      h.cameraPermission.result = CameraPermission.denied;
      await h.controller.initialize();

      await h.controller.takePhoto();

      expect(h.imageSource.cameraCalls, 0);
      expect(h.controller.step, FlowStep.start); // puede volver a intentarlo
      expect(
        h.controller.status?.failure?.kind,
        FailureKind.cameraPermissionDenied,
      );
    },
  );

  test('permiso denegado para siempre: se indica cómo activarlo', () async {
    final h = TestHarness();
    h.cameraPermission.result = CameraPermission.permanentlyDenied;
    await h.controller.initialize();

    await h.controller.takePhoto();

    expect(
      h.controller.status?.failure?.kind,
      FailureKind.cameraPermissionPermanentlyDenied,
    );
  });

  test('[H2-E3] «Repetir captura» vuelve a usar la cámara', () async {
    final h = TestHarness();
    await h.controller.initialize();
    await h.controller.takePhoto();

    await h.controller.replaceImage();

    expect(h.imageSource.cameraCalls, 2);
    expect(h.imageSource.galleryCalls, 0);
    expect(
      es.replaceImageLabel(h.controller.pendingImage!.origin),
      es.retakePhoto,
    );
  });

  test('si la cámara no está disponible, se explica', () async {
    final h = TestHarness();
    h.imageSource.cameraError = const AppFailure(FailureKind.cameraUnavailable);
    await h.controller.initialize();

    await h.controller.takePhoto();

    expect(h.controller.status?.failure?.kind, FailureKind.cameraUnavailable);
  });

  test('[H2-E5] sin texto se ofrece repetir la captura', () async {
    final h = TestHarness();
    h.api.recognitionResult = const RecognitionResult(hasText: false, text: '');
    await h.controller.initialize();
    await h.controller.takePhoto();

    await h.controller.recognize(consentGranted: true);

    expect(h.controller.status?.event, StatusEvent.noTextFound);
    expect(h.controller.status?.action, StatusAction.replaceImage);
    expect(h.controller.pendingImage?.origin, ImageOrigin.camera);
  });
}
