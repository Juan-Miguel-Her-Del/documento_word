// Pruebas del historial: título, almacén en archivo y DocumentHistory (tarea T601;
// spec 007; research.md de 007, R1 a R5).

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:handtext_ai/models/export_format.dart';
import 'package:handtext_ai/models/history_entry.dart';
import 'package:handtext_ai/services/history_store.dart';
import 'package:handtext_ai/state/document_history.dart';
import 'package:path/path.dart' as p;

import '../support/fakes.dart';

final _date = DateTime(2026, 10, 29, 15, 30);

HistoryEntry _entry(String id, {String text = 'Apuntes de biología'}) =>
    HistoryEntry(
      id: id,
      title: historyTitleFor(text),
      text: text,
      formats: {ExportFormat.docx},
      savedAt: _date,
    );

void main() {
  group('historyTitleFor', () {
    test('[HD-H1-E1] es la primera línea con texto, sin espacios', () {
      expect(
        historyTitleFor('\n   \n  Clase del lunes  \nLa célula…'),
        'Clase del lunes',
      );
    });

    test('se corta en 60 caracteres con «…», sin partir caracteres', () {
      final long = '${'á' * 70} fin';
      final title = historyTitleFor(long);

      expect(title.runes.length, 60);
      expect(title, endsWith('…'));
      expect(historyTitleFor('😀' * 61).runes.length, 60);
    });
  });

  group('FileHistoryStore', () {
    late Directory folder;

    setUp(() async {
      folder = await Directory.systemTemp.createTemp('handtext_historial_');
    });

    tearDown(() async {
      if (await folder.exists()) await folder.delete(recursive: true);
    });

    FileHistoryStore storeFor(String userId) => FileHistoryStore(
      directory: () async => folder,
      fileName: historyFileNameFor(userId),
    );

    test('[HD-H1-E5] guarda y recupera el historial', () async {
      final saved = HistoryEntry(
        id: 'doc-1',
        title: 'Clase',
        text: 'Clase\nLa célula',
        formats: {ExportFormat.docx, ExportFormat.pdf},
        savedAt: _date,
      );

      await storeFor('ana').save([saved]);
      final loaded = await storeFor('ana').load();

      expect(loaded.single.id, 'doc-1');
      expect(loaded.single.text, 'Clase\nLa célula');
      expect(loaded.single.formats, {ExportFormat.docx, ExportFormat.pdf});
      expect(loaded.single.savedAt, _date);
      expect(
        File(p.join(folder.path, 'history_ana.json.tmp')).existsSync(),
        isFalse,
      );
    });

    test('[HD-H1-E6] [SC-703] otra cuenta tiene su propio archivo', () async {
      await storeFor('ana').save([_entry('doc-1')]);

      expect(await storeFor('luis').load(), isEmpty);
      // El id nunca forma otra ruta: solo letras, números y guiones.
      expect(historyFileNameFor('../ana/x'), 'history_anax.json');
    });

    test(
      'sin archivo o con un archivo dañado, el historial está vacío',
      () async {
        expect(await storeFor('ana').load(), isEmpty);
        File(
          p.join(folder.path, historyFileNameFor('ana')),
        ).writeAsStringSync('{no es json');
        expect(await storeFor('ana').load(), isEmpty);
      },
    );

    test('una entrada incompleta se omite sin perder las demás', () {
      final json = encodeHistory([
        _entry('doc-1'),
      ]).replaceFirst('"entries":[', '"entries":[{"id":"roto"},');

      expect(decodeHistory(json).map((entry) => entry.id), ['doc-1']);
    });

    test('[HD-H3-E4] [SC-704] borrar elimina el archivo', () async {
      await storeFor('ana').save([_entry('doc-1')]);

      await storeFor('ana').delete();

      expect(folder.listSync(), isEmpty);
    });
  });

  group('DocumentHistory', () {
    late InMemoryHistoryStore store;
    late DocumentHistory history;
    var ids = 0;

    setUp(() {
      store = InMemoryHistoryStore();
      ids = 0;
      history = DocumentHistory(store: store, newId: () => 'doc-${++ids}');
    });

    test('[HD-H1-E1] registra un documento nuevo al principio', () async {
      await history.record(
        text: 'Viejo',
        format: ExportFormat.pdf,
        savedAt: _date,
      );

      final id = await history.record(
        text: 'Apuntes\nde biología',
        format: ExportFormat.docx,
        savedAt: _date,
      );

      expect(id, 'doc-2');
      expect(history.entries.first.title, 'Apuntes');
      expect(history.entries.map((entry) => entry.id), ['doc-2', 'doc-1']);
      expect(store.stored, hasLength(2));
    });

    test(
      '[HD-H1-E2] [SC-702] volver a guardar actualiza la misma entrada',
      () async {
        final id = await history.record(
          text: 'Primera versión',
          format: ExportFormat.docx,
          savedAt: _date,
        );
        await history.record(
          text: 'Otro',
          format: ExportFormat.docx,
          savedAt: _date,
        );

        await history.record(
          id: id,
          text: 'Versión corregida',
          format: ExportFormat.pdf,
          savedAt: _date.add(const Duration(hours: 1)),
        );

        expect(history.entries, hasLength(2));
        final updated = history.entries.first;
        expect(updated.id, id);
        expect(updated.text, 'Versión corregida');
        expect(updated.formats, {ExportFormat.docx, ExportFormat.pdf});
        expect(updated.savedAt, _date.add(const Duration(hours: 1)));
      },
    );

    test('al pasar de 50 documentos sale el más antiguo', () async {
      for (var i = 0; i < 51; i++) {
        await history.record(
          text: 'Doc $i',
          format: ExportFormat.docx,
          savedAt: _date,
        );
      }

      expect(history.entries, hasLength(50));
      expect(history.entries.first.title, 'Doc 50');
      expect(history.entries.last.title, 'Doc 1'); // «Doc 0» salió
    });

    test(
      'si el teléfono no deja escribir, la lista sigue en memoria',
      () async {
        store.failSaves = true;

        await history.record(
          text: 'Apuntes',
          format: ExportFormat.docx,
          savedAt: _date,
        );

        expect(history.entries.single.title, 'Apuntes');
      },
    );

    test('[HD-H3-E1] [HD-H3-E2] eliminar uno y borrar todo', () async {
      final first = await history.record(
        text: 'Uno',
        format: ExportFormat.docx,
        savedAt: _date,
      );
      await history.record(
        text: 'Dos',
        format: ExportFormat.docx,
        savedAt: _date,
      );

      await history.remove(first);
      expect(history.entries.map((entry) => entry.title), ['Dos']);
      expect(store.stored.map((entry) => entry.title), ['Dos']);

      await history.clear();
      expect(history.entries, isEmpty);
      expect(store.deletes, 1);
    });

    test('[HD-H1-E5] lee el historial guardado', () async {
      store.stored = [_entry('guardado')];

      await history.load();

      expect(history.entries.single.id, 'guardado');
    });
  });
}
