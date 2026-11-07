// Historial de documentos de una cuenta (tarea T603; spec 007; research.md de 007, R4,
// R5 y R8).
//
// Mantiene la lista «Mis documentos» en memoria y la guarda en el teléfono:
// - registrar un guardado correcto, al principio de la lista y sin duplicar el mismo
//   documento [HD-H1-E1] [HD-H1-E2];
// - como máximo 50 documentos: sale el más antiguo (caso límite);
// - eliminar uno o todos [HD-H3-E1] [HD-H3-E2];
// - spec 010: renombrar, y volver a guardar conserva el nombre [OR-H3-E3]
//   [OR-H3-E4].
// Si el teléfono no deja escribir, la lista sigue en memoria y nada falla: el historial
// es un extra del guardado, no parte de él (caso límite del spec).

import 'dart:math' as math;

import 'package:flutter/foundation.dart';

import '../config/app_config.dart';
import '../models/export_format.dart';
import '../models/history_entry.dart';
import '../services/history_store.dart';

class DocumentHistory extends ChangeNotifier {
  DocumentHistory({required HistoryStore store, String Function()? newId})
    : _store = store,
      _newId = newId ?? _randomId;

  final HistoryStore _store;
  final String Function() _newId;
  List<HistoryEntry> _entries = const [];

  /// Documentos guardados, el más reciente primero.
  List<HistoryEntry> get entries => _entries;

  /// Id nuevo: la hora en microsegundos y un número al azar (R3).
  static String _randomId() =>
      '${DateTime.now().microsecondsSinceEpoch}-${math.Random().nextInt(100000)}';

  /// [HD-H1-E5] Lee el historial guardado de la cuenta.
  Future<void> load() async {
    try {
      _entries = await _store.load();
    } on Exception {
      _entries = const [];
    }
    notifyListeners();
  }

  /// [HD-H1-E1] [HD-H1-E2] [SC-701] [SC-702] Registra un guardado correcto y devuelve
  /// el id del documento. Con [id] (un documento ya guardado) se actualiza su entrada;
  /// sin él, se crea una nueva.
  Future<String> record({
    String? id,
    required String text,
    required ExportFormat format,
    required DateTime savedAt,
  }) async {
    final previous = _entries.where((entry) => entry.id == id).firstOrNull;
    // Spec 010: si la persona le dio un nombre, se conserva [OR-H3-E4].
    final keepName = previous?.renamed ?? false;
    final entry = HistoryEntry(
      id: id ?? _newId(),
      title: keepName ? previous!.title : historyTitleFor(text),
      text: text,
      formats: {...?previous?.formats, format},
      savedAt: savedAt,
      renamed: keepName,
    );
    _entries = [
      entry,
      ..._entries.where((other) => other.id != entry.id),
    ].take(AppConfig.maxHistoryEntries).toList(growable: false);
    notifyListeners();
    await _persist();
    return entry.id;
  }

  /// [OR-H3-E3] [SC-1004] Cambia el título de un documento (de 1 a 60 caracteres, sin
  /// los espacios de los lados). No toca su texto ni los archivos guardados.
  Future<void> rename(String id, String title) async {
    final name = String.fromCharCodes(title.trim().runes.take(60)).trim();
    if (name.isEmpty) return;
    _entries = [
      for (final entry in _entries)
        entry.id == id ? entry.renamedTo(name) : entry,
    ];
    notifyListeners();
    await _persist();
  }

  /// [HD-H3-E1] Quita un documento del historial (no toca el archivo guardado).
  Future<void> remove(String id) async {
    _entries = _entries
        .where((entry) => entry.id != id)
        .toList(growable: false);
    notifyListeners();
    await _persist();
  }

  /// [HD-H3-E2] [HD-H3-E4] Vacía el historial y borra su archivo.
  Future<void> clear() async {
    _entries = const [];
    notifyListeners();
    try {
      await _store.delete();
    } on Exception catch (error) {
      debugPrint('No se borró el historial: ${error.runtimeType}');
    }
  }

  Future<void> _persist() async {
    try {
      await _store.save(_entries);
    } on Exception catch (error) {
      // Solo el tipo de error, nunca el contenido (constitución §5).
      debugPrint('No se guardó el historial: ${error.runtimeType}');
    }
  }
}
