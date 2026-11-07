// Pruebas del controlador con varias páginas (tareas T305, T308 y T310; spec 004).
//
// Cada página es una imagen sintética distinta; la API falsa responde según la imagen.
// Cada prueba indica el escenario que verifica: [VP-H3-E2] = Historia 3, escenario 2.

import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:handtext_ai/models/app_failure.dart';
import 'package:handtext_ai/models/operation_status.dart';
import 'package:handtext_ai/models/picked_image.dart';
import 'package:handtext_ai/models/recognition_result.dart';
import 'package:handtext_ai/state/document_flow_controller.dart';
import 'package:image_picker/image_picker.dart';

import '../support/fakes.dart';

/// Imagen PNG sintética de la página [n] (un byte la distingue de las demás).
Uint8List _bytes(int n) => fakePngBytes()..[20] = n;

XFile _file(int n) => XFile.fromData(_bytes(n), name: 'pagina_$n.png');

/// Número de página de una imagen, leído del byte que la distingue.
int _pageOf(Uint8List bytes) => bytes[20];

/// Arnés con la galería devolviendo las páginas 1..[count], y la API respondiendo
/// «Texto de la página n» para cada una.
Future<TestHarness> _withPages(int count) async {
  final h = TestHarness();
  h.imageSource.galleryResults = [for (var n = 1; n <= count; n++) _file(n)];
  h.api.resultFor = (bytes) => RecognitionResult(
    hasText: true,
    text: 'Texto de la página ${_pageOf(bytes)}\n',
  );
  await h.controller.initialize();
  await h.controller.pickFromGallery();
  return h;
}

List<int> _pageNumbers(TestHarness h) => [
  for (final page in h.controller.pages) _pageOf(page.image.bytes),
];

void main() {
  group('Historia 1: varias hojas en un documento', () {
    test('[VP-H1-E1] elegir 3 imágenes crea 3 páginas en orden', () async {
      final h = await _withPages(3);

      expect(_pageNumbers(h), [1, 2, 3]);
      expect(h.controller.step, FlowStep.preview);
      expect(h.controller.selectedPageIndex, 0);
      expect(h.imageSource.lastLimit, 10); // nunca más de 10
    });

    test(
      '[VP-H1-E2] «Agregar página» suma al final desde la galería o la cámara',
      () async {
        final h = await _withPages(2);
        h.imageSource.galleryResults = [_file(3)];
        h.imageSource.cameraResult = _file(4);

        await h.controller.addPages(ImageOrigin.gallery);
        expect(h.imageSource.lastLimit, 8); // solo las que caben
        await h.controller.addPages(ImageOrigin.camera);

        expect(_pageNumbers(h), [1, 2, 3, 4]);
        expect(h.controller.selectedPageIndex, 3); // se ve la nueva
      },
    );

    test('[VP-H1-E6] [SC-403] con 10 páginas no se agregan más', () async {
      final h = await _withPages(10);
      final calls = h.imageSource.galleryCalls;

      await h.controller.addPages(ImageOrigin.gallery);

      expect(h.controller.pages, hasLength(10));
      expect(h.imageSource.galleryCalls, calls); // ni se abre el selector
      expect(h.controller.status?.failure?.kind, FailureKind.tooManyPages);
    });

    test(
      'caso límite: si el selector devuelve de más, sobran y se borran',
      () async {
        final h = await _withPages(9);
        h.imageSource.galleryResults = [_file(10), _file(11)];

        await h.controller.addPages(ImageOrigin.gallery);

        expect(h.controller.pages, hasLength(10));
        expect(h.controller.status?.failure?.kind, FailureKind.tooManyPages);
        expect(_pageOf(h.workingCopies.deleted.single.bytes), 11);
      },
    );

    test('[VP-H1-E7] una imagen inválida no se agrega; las demás sí', () async {
      final h = TestHarness();
      h.imageSource.galleryResults = [
        _file(1),
        XFile.fromData(Uint8List.fromList(List.filled(40, 7)), name: 'x.png'),
        _file(3),
      ];
      await h.controller.initialize();

      await h.controller.pickFromGallery();

      expect(_pageNumbers(h), [1, 3]);
      expect(
        h.controller.status?.failure?.kind,
        FailureKind.unsupportedImageType,
      );
      expect(h.workingCopies.deleted, hasLength(1)); // la copia inválida
    });

    test(
      '[VP-H1-E4] [VP-H1-E5] [SC-401] se reconocen en orden y el texto se une',
      () async {
        final h = await _withPages(3);

        await h.controller.recognize(consentGranted: true);

        expect([for (final b in h.api.recognizedImages) _pageOf(b)], [1, 2, 3]);
        expect(
          h.controller.documentText,
          'Texto de la página 1\n\nTexto de la página 2\n\nTexto de la página 3',
        );
        expect(h.controller.step, FlowStep.editor);
      },
    );

    test('[VP-H1-E4] el avance dice qué página se está leyendo', () async {
      final h = await _withPages(2);
      final gate = h.api.recognitionGate = Completer<void>();

      final running = h.controller.recognize(consentGranted: true);
      await Future<void>.delayed(Duration.zero);

      expect(h.controller.status?.event, StatusEvent.recognizing);
      expect(h.controller.status?.page, 1);
      expect(h.controller.status?.pageCount, 2);
      gate.complete();
      await running;
    });

    test('[SC-404] las palabras dudosas quedan sobre sus palabras', () async {
      final h = await _withPages(2);
      h.api.resultFor = (bytes) => RecognitionResult(
        hasText: true,
        text: 'la celula ${_pageOf(bytes)}',
        uncertainRanges: const [TextRange(start: 3, end: 9)],
      );

      await h.controller.recognize(consentGranted: true);

      final text = h.controller.documentText!;
      expect(
        [for (final r in h.controller.uncertainRanges) r.textInside(text)],
        ['celula', 'celula'],
      );
      expect(
        h.controller.uncertainRanges.last.start,
        'la celula 1\n\nla '.length,
      );
    });

    test(
      '[SC-403] al reconocer se borran las copias de todas las páginas',
      () async {
        final h = await _withPages(3);

        await h.controller.recognize(consentGranted: true);

        expect(h.workingCopies.deleted, hasLength(3));
        expect(h.controller.pages, isEmpty);
      },
    );
  });

  group('Historia 2: organizar las páginas', () {
    test(
      '[VP-H2-E1] [VP-H2-E2] elegir y mover una página cambia el orden',
      () async {
        final h = await _withPages(3);

        h.controller.selectPage(2);
        h.controller.moveSelectedPage(-1);

        expect(_pageNumbers(h), [1, 3, 2]);
        expect(h.controller.selectedPageIndex, 1);
        h.controller.moveSelectedPage(-5); // fuera de rango: no hace nada
        expect(_pageNumbers(h), [1, 3, 2]);
      },
    );

    test('[VP-H2-E3] quitar una página borra su copia y renumera', () async {
      final h = await _withPages(3);
      h.controller.selectPage(1);

      await h.controller.removeSelectedPage();

      expect(_pageNumbers(h), [1, 3]);
      expect(_pageOf(h.workingCopies.deleted.single.bytes), 2);
    });

    test(
      '[VP-H2-E5] con una sola página no se quita (se usa «Cancelar»)',
      () async {
        final h = await _withPages(1);

        await h.controller.removeSelectedPage();

        expect(h.controller.pages, hasLength(1));
      },
    );

    test('[VP-H2-E4] reemplazar cambia solo la página elegida', () async {
      final h = await _withPages(3);
      h.controller.selectPage(1);
      h.imageSource.galleryResult = _file(9);

      await h.controller.replaceImage();

      expect(_pageNumbers(h), [1, 9, 3]);
      expect(_pageOf(h.workingCopies.deleted.single.bytes), 2);
    });

    test('[VP-H2-E4] recortar cambia solo la página elegida', () async {
      final h = await _withPages(2);
      h.controller.selectPage(1);
      h.imageEditor.result = _file(7);

      await h.controller.editImage();

      expect(_pageNumbers(h), [1, 7]);
      expect(h.controller.canRestoreOriginalImage, isTrue);
      h.controller.selectPage(0);
      expect(h.controller.canRestoreOriginalImage, isFalse);
    });

    test('[SC-403] cancelar borra las copias de todas las páginas', () async {
      final h = await _withPages(3);

      await h.controller.cancelPreview();

      expect(h.workingCopies.deleted, hasLength(3));
    });
  });

  group('Historia 3: fallos de una página', () {
    test(
      '[VP-H3-E1] [VP-H3-E2] [SC-402] si falla la página 2, al reintentar no se '
      'reenvía la 1',
      () async {
        final h = await _withPages(3);
        h.api.failOnceWith = h.controller.pages[1].image.bytes;

        await h.controller.recognize(consentGranted: true);

        final status = h.controller.status!;
        expect(status.failure?.kind, FailureKind.noConnection);
        expect((status.page, status.pageCount), (2, 3));
        expect(status.action, StatusAction.retryRecognition);
        expect(h.controller.step, FlowStep.preview); // las páginas siguen ahí
        expect(h.controller.pagesToSend, 2);

        await h.controller.recognize(consentGranted: true);

        expect(
          [for (final b in h.api.recognizedImages) _pageOf(b)],
          [1, 2, 2, 3],
        );
        expect(h.controller.step, FlowStep.editor);
      },
    );

    test(
      '[VP-H3-E3] una página reconocida y luego recortada se vuelve a enviar',
      () async {
        final h = await _withPages(2);
        h.api.failOnceWith = h.controller.pages[1].image.bytes;
        await h.controller.recognize(
          consentGranted: true,
        ); // la 1 quedó reconocida
        h.controller.selectPage(0);
        h.imageEditor.result = _file(5);

        await h.controller.editImage();
        await h.controller.recognize(consentGranted: true);

        expect(
          [for (final b in h.api.recognizedImages) _pageOf(b)],
          [1, 2, 5, 2],
        );
      },
    );

    test('[VP-H3-E3] mover una página reconocida no la reenvía', () async {
      final h = await _withPages(2);
      h.api.failOnceWith = h.controller.pages[1].image.bytes;
      await h.controller.recognize(consentGranted: true);

      h.controller.selectPage(1);
      h.controller.moveSelectedPage(-1);
      await h.controller.recognize(consentGranted: true);

      expect([for (final b in h.api.recognizedImages) _pageOf(b)], [1, 2, 2]);
      expect(
        h.controller.documentText,
        'Texto de la página 2\n\nTexto de la página 1',
      );
    });

    test('[VP-H3-E4] una página sin texto se omite y se informa', () async {
      final h = await _withPages(3);
      h.api.resultFor = (bytes) => _pageOf(bytes) == 2
          ? const RecognitionResult(hasText: false, text: '')
          : RecognitionResult(hasText: true, text: 'Página ${_pageOf(bytes)}');

      await h.controller.recognize(consentGranted: true);

      expect(h.controller.documentText, 'Página 1\n\nPágina 3');
      expect(h.controller.status?.emptyPages, [2]);
    });

    test('[VP-H3-E5] si ninguna tiene texto, se informa como en 001', () async {
      final h = await _withPages(2);
      h.api.resultFor = (bytes) =>
          const RecognitionResult(hasText: false, text: '');

      await h.controller.recognize(consentGranted: true);

      expect(h.controller.status?.event, StatusEvent.noTextFound);
      expect(h.controller.step, FlowStep.preview);
    });

    test(
      'con una sola página, el fallo no menciona páginas (igual que en 001)',
      () async {
        final h = await _withPages(1);
        h.api.recognitionError = const AppFailure(FailureKind.noConnection);

        await h.controller.recognize(consentGranted: true);

        expect(h.controller.status?.page, isNull);
      },
    );
  });
}
