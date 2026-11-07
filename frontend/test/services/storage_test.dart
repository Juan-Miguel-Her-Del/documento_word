// Pruebas del borrador y de las copias de trabajo con archivos reales (tarea T024).
//
// - Borrador: Clarifications del spec; Historia 1, escenarios 15 a 17.
// - Copias de trabajo: constitución §3 (Conservación del original), Historia 1,
//   escenario 14, y SC-006 (el original queda idéntico).
// - Spec 003: borrador con marcas (formato 2) y limpieza de las copias para compartir.
// Todo ocurre en una carpeta temporal que se borra al final de cada prueba.

import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:handtext_ai/models/document_draft.dart';
import 'package:handtext_ai/services/draft_storage.dart';
import 'package:handtext_ai/services/share_service.dart';
import 'package:handtext_ai/services/working_copy_service.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as p;

import '../support/fakes.dart';

void main() {
  late Directory root;

  setUp(() async {
    root = await Directory.systemTemp.createTemp('handtext_prueba_');
  });

  tearDown(() async {
    if (await root.exists()) await root.delete(recursive: true);
  });

  group('FileDraftStore', () {
    late FileDraftStore store;
    late Directory privateFolder;

    setUp(() {
      privateFolder = Directory(p.join(root.path, 'privado'));
      store = FileDraftStore(directory: () async => privateFolder);
    });

    test('sin borrador devuelve null', () async {
      expect(await store.load(), isNull);
    });

    test(
      'guarda y recupera el texto exacto, con todos sus caracteres',
      () async {
        const text = 'Título\n\nÁrbol, ñandú, ¿qué? ¡sí!\tcon tabulación 😀';

        await store.save(DocumentDraft(text));

        expect((await store.load())?.text, text);
        // La escritura atómica no deja el archivo temporal.
        expect(
          File(p.join(privateFolder.path, 'draft.txt.tmp')).existsSync(),
          isFalse,
        );
      },
    );

    test('guardar de nuevo reemplaza el borrador anterior', () async {
      await store.save(DocumentDraft('versión 1'));
      await store.save(DocumentDraft('versión 2'));

      expect((await store.load())?.text, 'versión 2');
    });

    test('[H1-E17] eliminar deja el teléfono sin borrador', () async {
      await store.save(DocumentDraft('privado'));

      await store.delete();

      expect(await store.load(), isNull);
      expect(
        File(p.join(privateFolder.path, 'draft.txt')).existsSync(),
        isFalse,
      );
    });
  });

  group('FileDraftStore, formato 2 (spec 003)', () {
    late Directory folder;
    late FileDraftStore store;

    setUp(() {
      folder = Directory(p.join(root.path, 'privado2'));
      store = FileDraftStore(directory: () async => folder);
    });

    test('[EX-H1-E7] guarda y recupera el texto con sus marcas', () async {
      const ranges = [
        TextRange(start: 0, end: 4),
        TextRange(start: 5, end: 10),
      ];

      await store.save(
        const DocumentDraft('Hola mundo', uncertainRanges: ranges),
      );
      final draft = await store.load();

      expect(draft?.text, 'Hola mundo');
      expect(draft?.uncertainRanges, ranges);
    });

    test('lee un borrador de la versión anterior (texto plano)', () async {
      await folder.create(recursive: true);
      // Texto plano, aunque parezca JSON: no es el formato 2.
      const old = '{"nota": 1}\nApuntes de clase';
      await File(p.join(folder.path, 'draft.txt')).writeAsString(old);

      final draft = await store.load();

      expect(draft?.text, old);
      expect(draft?.uncertainRanges, isEmpty);
    });

    test('descarta las marcas que no caben en el texto', () {
      final draft = decodeDraft(
        '{"version": 2, "text": "Hola", "uncertain": [[0, 4], [2, 9], "x"]}',
      );

      expect(draft.uncertainRanges, const [TextRange(start: 0, end: 4)]);
    });
  });

  group('WorkingCopyService', () {
    late Directory cache;
    late WorkingCopyService service;

    setUp(() async {
      cache = await Directory(p.join(root.path, 'cache')).create();
      service = WorkingCopyService(cacheDirectory: () async => cache);
    });

    test(
      '[H1-E14] [SC-006] trabaja sobre una copia y el original no cambia',
      () async {
        // «Galería» del usuario: fuera de la caché de la app.
        final gallery = await Directory(p.join(root.path, 'galeria')).create();
        final original = File(p.join(gallery.path, 'apuntes.png'));
        final bytes = fakePngBytes();
        await original.writeAsBytes(bytes);

        final copy = await service.createFrom(XFile(original.path));

        expect(
          p.isWithin(p.join(cache.path, 'handtext_work'), copy.path),
          isTrue,
        );
        expect(await File(copy.path).readAsBytes(), bytes);
        expect(original.existsSync(), isTrue); // nunca se borra el original
        expect(await original.readAsBytes(), bytes); // ni se modifica
      },
    );

    test(
      'borra el archivo intermedio de image_picker dentro de la caché',
      () async {
        final pickerFile = File(p.join(cache.path, 'image_picker_123.png'));
        await pickerFile.writeAsBytes(fakePngBytes());

        await service.createFrom(XFile(pickerFile.path));

        expect(pickerFile.existsSync(), isFalse);
      },
    );

    test('delete y purgeAll eliminan las copias (retención)', () async {
      final first = await service.createFrom(
        XFile.fromData(Uint8List.fromList(fakeJpegBytes())),
      );
      final second = await service.createFrom(
        XFile.fromData(Uint8List.fromList(fakeJpegBytes())),
      );

      await service.delete(first);
      expect(File(first.path).existsSync(), isFalse);
      expect(File(second.path).existsSync(), isTrue);

      await service.purgeAll();
      expect(
        Directory(p.join(cache.path, 'handtext_work')).existsSync(),
        isFalse,
      );
    });
  });

  group('borrador por cuenta (spec 002)', () {
    test('[SC-206] dos cuentas no comparten borrador', () async {
      final folder = Directory(p.join(root.path, 'privado'));
      final ana = FileDraftStore(
        directory: () async => folder,
        fileName: draftFileNameFor('aaaa-1111'),
      );
      final luis = FileDraftStore(
        directory: () async => folder,
        fileName: draftFileNameFor('bbbb-2222'),
      );

      await ana.save(DocumentDraft('Apuntes de Ana'));

      expect(await luis.load(), isNull);
      expect((await ana.load())?.text, 'Apuntes de Ana');
    });

    test('el id nunca puede formar una ruta distinta', () {
      expect(draftFileNameFor('../../otra-carpeta'), 'draft_otra-carpeta.txt');
      expect(draftFileNameFor('0b6f2a3e-1111'), 'draft_0b6f2a3e-1111.txt');
    });
  });

  test(
    '[EX-H3-E5] purge borra la copia propia y la que deja share_plus',
    () async {
      // Regresión (spec 003, R8): share_plus guarda su propia copia del archivo
      // compartido en <caché>/share_plus; también debe borrarse.
      final cache = await Directory(p.join(root.path, 'cache')).create();
      final other = File(p.join(cache.path, 'otra_cosa.txt'))
        ..writeAsStringSync('x');
      for (final folder in ['handtext_share', 'share_plus']) {
        File(p.join(cache.path, folder, 'HandText_20261029_0358.pdf'))
          ..createSync(recursive: true)
          ..writeAsBytesSync([0x25, 0x50, 0x44, 0x46]);
      }

      await SystemDocumentSharer(cacheDirectory: () async => cache).purge();

      expect(
        Directory(p.join(cache.path, 'handtext_share')).existsSync(),
        isFalse,
      );
      expect(Directory(p.join(cache.path, 'share_plus')).existsSync(), isFalse);
      expect(other.existsSync(), isTrue); // el resto de la caché no se toca
    },
  );
}
