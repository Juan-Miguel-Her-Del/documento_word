// Pruebas del historial en el flujo de documentos (tareas T604, T608 y T610; spec 007).

import 'package:flutter_test/flutter_test.dart';
import 'package:handtext_ai/models/app_failure.dart';
import 'package:handtext_ai/models/export_format.dart';
import 'package:handtext_ai/models/history_entry.dart';
import 'package:handtext_ai/models/operation_status.dart';
import 'package:handtext_ai/services/file_save_service.dart';
import 'package:handtext_ai/state/document_flow_controller.dart';

import '../support/fakes.dart';

/// Hora fija del arnés (TestHarness).
final _now = DateTime(2026, 10, 26, 15, 30);

final _saved = HistoryEntry(
  id: 'guardado-1',
  title: 'Guía de la semana',
  text: 'Guía de la semana\nEjercicios 1 a 5',
  formats: {ExportFormat.pdf},
  savedAt: DateTime(2026, 10, 20, 9, 0),
);

void main() {
  group('Historia 1: lo guardado queda en el historial', () {
    test('[HD-H1-E1] [SC-701] un guardado correcto aparece primero', () async {
      final h = TestHarness();
      await h.reachEditor(text: 'Apuntes de biología\nLa célula');

      await h.controller.export(ExportFormat.docx);

      final entry = h.controller.history.entries.single;
      expect(entry.title, 'Apuntes de biología');
      expect(entry.text, 'Apuntes de biología\nLa célula');
      expect(entry.formats, {ExportFormat.docx});
      expect(entry.savedAt, _now);
      expect(h.historyStore.stored, hasLength(1)); // quedó en el teléfono
    });

    test('[HD-H1-E2] [SC-702] guardarlo otra vez, corregido o en otro formato, '
        'actualiza la misma entrada', () async {
      final h = TestHarness();
      await h.reachEditor(text: 'Primera versión');
      await h.controller.export(ExportFormat.docx);

      h.controller.updateText('Versión corregida');
      await h.controller.export(ExportFormat.pdf);

      final entry = h.controller.history.entries.single;
      expect(entry.text, 'Versión corregida');
      expect(entry.formats, {ExportFormat.docx, ExportFormat.pdf});
    });

    test(
      '[HD-H1-E3] [SC-701] un guardado cancelado o fallido no aparece',
      () async {
        final h = TestHarness();
        await h.reachEditor();

        h.fileSaver.outcome = const SaveCancelled();
        await h.controller.export(ExportFormat.docx);
        h.fileSaver.outcome = const SaveCompleted();
        h.api.exportError = const AppFailure(FailureKind.exportFailed);
        await h.controller.export(ExportFormat.docx);
        h.api.exportError = null;
        h.fileSaver.error = const AppFailure(FailureKind.saveFailed);
        await h.controller.export(ExportFormat.pdf);

        expect(h.controller.history.entries, isEmpty);
        expect(h.historyStore.saves, 0);
      },
    );

    test(
      'un documento nuevo (otro reconocimiento) crea otra entrada',
      () async {
        final h = TestHarness();
        await h.reachEditor(text: 'Primer documento');
        await h.controller.export(ExportFormat.docx);

        h.controller.startAnotherImage();
        await h.controller.pickFromGallery();
        await h.controller.recognize(consentGranted: true);
        await h.controller.export(ExportFormat.docx);

        expect(h.controller.history.entries, hasLength(2));
      },
    );

    test(
      'si el historial no se puede guardar, el archivo igual se guarda bien',
      () async {
        final h = TestHarness();
        h.historyStore.failSaves = true;
        await h.reachEditor();

        await h.controller.export(ExportFormat.docx);

        expect(h.controller.status!.event, StatusEvent.saved);
        expect(h.fileSaver.savedNames, hasLength(1));
        expect(h.controller.history.entries, hasLength(1)); // sigue en memoria
      },
    );

    test('[HD-H1-E5] al abrir la app se lee el historial guardado', () async {
      final h = TestHarness()..historyStore.stored = [_saved];

      await h.controller.initialize();

      expect(h.controller.history.entries.single.id, _saved.id);
    });
  });

  group('Historia 2: abrir un documento guardado', () {
    test('[HD-H2-E1] se abre en el editor, sin cambios por exportar', () async {
      final h = TestHarness()..historyStore.stored = [_saved];
      await h.controller.initialize();

      await h.controller.openFromHistory(_saved);

      expect(h.controller.step, FlowStep.editor);
      expect(h.controller.documentText, _saved.text);
      expect(h.controller.uncertainRanges, isEmpty);
      expect(h.controller.hasUnexportedChanges, isFalse);
      expect(h.controller.status!.event, StatusEvent.historyOpened);
    });

    test('abrirlo reemplaza el borrador del texto anterior', () async {
      final h = TestHarness()..historyStore.stored = [_saved];
      await h.reachEditor(text: 'Texto sin exportar');
      expect(h.drafts.stored, 'Texto sin exportar');

      await h.controller.openFromHistory(_saved);

      expect(h.drafts.stored, isNull);
    });

    test(
      '[HD-H2-E3] [SC-702] corregirlo y guardarlo actualiza esa entrada',
      () async {
        final h = TestHarness()..historyStore.stored = [_saved];
        await h.controller.initialize();
        await h.controller.openFromHistory(_saved);

        h.controller.updateText('Guía de la semana\nEjercicios 1 a 6');
        await h.controller.export(ExportFormat.docx);

        final entry = h.controller.history.entries.single;
        expect(entry.id, _saved.id);
        expect(entry.text, endsWith('1 a 6'));
        expect(entry.formats, {ExportFormat.docx, ExportFormat.pdf});
      },
    );

    test(
      '[HD-H2-E4] el borrador sigue unido a su entrada al volver a abrir la app',
      () async {
        final h = TestHarness()..historyStore.stored = [_saved];
        await h.controller.initialize();
        await h.controller.openFromHistory(_saved);
        h.controller.updateText('Guía corregida');
        await h.controller.flushDraft();
        expect(h.drafts.storedHistoryId, _saved.id);

        // La app se cierra y se abre: otro controlador con el mismo teléfono.
        final reopened = h.buildController(testUser, () {});
        await reopened.initialize();
        await reopened.export(ExportFormat.docx);

        expect(reopened.history.entries.single.id, _saved.id);
        expect(reopened.history.entries.single.text, 'Guía corregida');
      },
    );
  });

  group('Historia 3: borrar', () {
    test('[HD-H1-E5] cerrar sesión conserva el historial', () async {
      final h = TestHarness();
      await h.reachEditor();
      await h.controller.export(ExportFormat.docx);

      await h.controller.clearLocalData();

      expect(h.historyStore.stored, hasLength(1));
      expect(h.historyStore.deletes, 0);
    });

    test('[HD-H3-E4] [SC-704] eliminar la cuenta borra el historial', () async {
      final h = TestHarness();
      await h.reachEditor();
      await h.controller.export(ExportFormat.docx);

      await h.controller.clearLocalData(deleteHistory: true);

      expect(h.controller.history.entries, isEmpty);
      expect(h.historyStore.stored, isEmpty);
      expect(h.historyStore.deletes, 1);
    });

    test('descartar el texto no toca el historial', () async {
      final h = TestHarness();
      await h.reachEditor();
      await h.controller.export(ExportFormat.docx);
      h.controller.updateText('Cambio');

      await h.controller.discardDocument();

      expect(h.controller.history.entries, hasLength(1));
    });
  });
}
