// Pruebas del escáner de documentos (tareas T802, T805 y T807; spec 009).

import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:handtext_ai/models/app_failure.dart';
import 'package:handtext_ai/models/operation_status.dart';
import 'package:handtext_ai/models/picked_image.dart';
import 'package:handtext_ai/state/document_flow_controller.dart';
import 'package:image_picker/image_picker.dart';

import '../support/app_tester.dart';
import '../support/fakes.dart';
import '../support/strings_es.dart';

/// Hojas escaneadas: JPEG válidos, como los que entrega el escáner.
List<XFile> _scanned(int count) => [
  for (var i = 0; i < count; i++) pickedFile(fakeJpegBytes()),
];

void main() {
  group('Historia 1: escanear', () {
    test(
      '[ED-H1-E2] [ED-H3-E1] una hoja llega a la vista previa como copia',
      () async {
        final h = TestHarness();
        await h.controller.initialize();
        h.scanner.result = _scanned(1);

        await h.controller.scanDocument();

        expect(h.controller.step, FlowStep.preview);
        expect(h.controller.pages, hasLength(1));
        expect(h.controller.pendingImage!.origin, ImageOrigin.scanner);
        expect(h.workingCopies.created, hasLength(1)); // constitución §3
        expect(h.scanner.lastPageLimit, 10);
      },
    );

    test('[ED-H1-E3] varias hojas llegan en orden, sin pasar de 10', () async {
      final h = TestHarness();
      await h.controller.initialize();
      h.scanner.result = _scanned(3);

      await h.controller.scanDocument();

      expect(h.controller.pages, hasLength(3));
      expect(
        h.controller.pages.map((page) => page.image.workingCopy.path),
        h.workingCopies.created.map((copy) => copy.path),
      );
    });

    test(
      '[ED-H1-E4] «Agregar página» escanea solo las hojas que caben',
      () async {
        final h = TestHarness();
        await h.controller.initialize();
        h.imageSource.galleryResults = _scanned(8);
        await h.controller.pickFromGallery();
        h.scanner.result = _scanned(2);

        await h.controller.addPages(ImageOrigin.scanner);

        expect(h.scanner.lastPageLimit, 2);
        expect(h.controller.pages, hasLength(10));
        expect(h.controller.pages.last.image.origin, ImageOrigin.scanner);
      },
    );

    test('[ED-H1-E5] [SC-903] cancelar el escáner no cambia nada', () async {
      final h = TestHarness();
      await h.reachEditor(text: 'Texto en edición');
      h.controller.startAnotherImage();
      h.scanner.result = null; // canceló

      await h.controller.scanDocument();

      expect(h.controller.step, FlowStep.start);
      expect(h.controller.pages, isEmpty);
      expect(h.controller.documentText, 'Texto en edición');
      expect(h.controller.status, isNull);
    });

    test('[SC-902] una hoja escaneada no se envía sin autorización', () async {
      final h = TestHarness();
      await h.controller.initialize();
      h.scanner.result = _scanned(1);
      await h.controller.scanDocument();

      await h.controller.recognize(consentGranted: false);

      expect(h.api.recognizedImages, isEmpty);
    });
  });

  group('Historia 2: escáner no disponible', () {
    test('[ED-H2-E1] [SC-904] el aviso ofrece tomar una fotografía', () async {
      final h = TestHarness();
      await h.controller.initialize();
      h.scanner.error = const AppFailure(FailureKind.scannerUnavailable);

      await h.controller.scanDocument();

      final status = h.controller.status!;
      expect(status.failure!.kind, FailureKind.scannerUnavailable);
      expect(status.action, StatusAction.takePhoto);
      expect(h.controller.step, FlowStep.start);
    });

    test('[ED-H2-E2] un fallo del escáner conserva las páginas', () async {
      final h = TestHarness();
      await h.controller.initialize();
      h.scanner.result = _scanned(2);
      await h.controller.scanDocument();
      h.scanner.error = const AppFailure(FailureKind.scannerFailed);

      await h.controller.addPages(ImageOrigin.scanner);

      expect(h.controller.pages, hasLength(2));
      expect(h.controller.status!.failure!.kind, FailureKind.scannerFailed);
      expect(h.controller.status!.action, isNull);
    });
  });

  group('Historia 3: reglas de imagen', () {
    test(
      '[ED-H3-E2] una hoja no válida se explica y las válidas se agregan',
      () async {
        final h = TestHarness();
        await h.controller.initialize();
        h.scanner.result = [
          pickedFile(fakeJpegBytes()),
          pickedFile(
            Uint8List.fromList(List.filled(64, 7)),
          ), // no es una imagen
        ];

        await h.controller.scanDocument();

        expect(h.controller.pages, hasLength(1));
        expect(
          h.controller.status!.failure!.kind,
          FailureKind.unsupportedImageType,
        );
      },
    );

    test(
      '[ED-H3-E3] reemplazar una hoja escaneada vuelve a escanear una',
      () async {
        final h = TestHarness();
        await h.controller.initialize();
        h.scanner.result = _scanned(1);
        await h.controller.scanDocument();

        await h.controller.replaceImage();

        expect(h.scanner.calls, 2);
        expect(h.scanner.lastPageLimit, 1);
        expect(es.replaceImageLabel(ImageOrigin.scanner), es.rescanImage);
      },
    );
  });

  group('Pantallas', () {
    testWidgets(
      '[ED-H1-E1] [ED-H1-E2] «Escanear hoja» lleva a la vista previa',
      (tester) async {
        final h = TestHarness();
        h.scanner.result = _scanned(1);
        await pumpHandTextApp(tester, h);

        await tapText(tester, es.scanDocument);

        expect(find.text(es.previewTitle), findsOneWidget);
        expect(find.text(es.rescanImage), findsOneWidget); // botón de reemplazo
      },
    );

    testWidgets('[ED-H2-E1] sin escáner, «Tomar fotografía» desde el aviso', (
      tester,
    ) async {
      final h = TestHarness();
      h.scanner.error = const AppFailure(FailureKind.scannerUnavailable);
      await pumpHandTextApp(tester, h);

      await tapText(tester, es.scanDocument);
      expect(
        find.text(
          es.failureText(const AppFailure(FailureKind.scannerUnavailable)),
        ),
        findsOneWidget,
      );
      // El botón del aviso (el primero; la tarjeta de la cámara está más abajo).
      await tester.tap(find.widgetWithText(TextButton, es.takePhoto));
      await tester.pumpAndSettle();

      expect(find.text(es.previewTitle), findsOneWidget);
      expect(h.controller.pendingImage!.origin, ImageOrigin.camera);
    });

    testWidgets('[ED-H1-E4] «Escanear» en la hoja de «Agregar página»', (
      tester,
    ) async {
      final h = TestHarness();
      await pumpHandTextApp(tester, h);
      await tapText(tester, es.pickFromGallery);
      h.scanner.result = _scanned(2);

      await tester.tap(find.bySemanticsLabel(es.addPage));
      await tester.pumpAndSettle();
      await tapText(tester, es.addPageFromScanner);

      expect(h.controller.pages, hasLength(3));
    });
  });
}
