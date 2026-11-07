// Almacén del historial de una cuenta (tarea T602; spec 007; research.md de 007, R1 y
// R2).
//
// Un archivo history_<id>.json en la carpeta privada de soporte de la app, uno por
// cuenta, con escritura atómica (como el borrador y los ajustes). La app no permite
// copias de seguridad, así que no sale del teléfono. Si el archivo falta o está dañado,
// el historial está vacío y la app sigue funcionando (caso límite del spec).

import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;

import '../models/export_format.dart';
import '../models/history_entry.dart';

/// Nombre del historial de una cuenta. Solo se dejan letras, números y guiones del id,
/// para que nunca pueda formar una ruta distinta [SC-703].
String historyFileNameFor(String userId) {
  final safeId = userId.replaceAll(RegExp(r'[^A-Za-z0-9-]'), '');
  return 'history_$safeId.json';
}

/// Operaciones sobre el historial. Las pruebas usan una versión en memoria.
abstract interface class HistoryStore {
  /// Devuelve los documentos guardados, el más reciente primero.
  Future<List<HistoryEntry>> load();

  /// Guarda (o reemplaza) la lista completa.
  Future<void> save(List<HistoryEntry> entries);

  /// Borra el archivo del historial.
  Future<void> delete();
}

/// Convierte el historial a JSON (data-model.md de 007).
String encodeHistory(List<HistoryEntry> entries) => jsonEncode({
  'version': 1,
  'entries': [
    for (final entry in entries)
      {
        'id': entry.id,
        'title': entry.title,
        'text': entry.text,
        'formats': [for (final format in entry.formats) format.apiValue],
        'savedAt': entry.savedAt.toIso8601String(),
        if (entry.renamed) 'renamed': true, // spec 010
      },
  ],
});

/// Lee el historial. Un JSON dañado o de otra versión da una lista vacía, y una
/// entrada incompleta se omite sin perder las demás.
List<HistoryEntry> decodeHistory(String content) {
  Object? json;
  try {
    json = jsonDecode(content);
  } on FormatException {
    return const [];
  }
  if (json case {'version': 1, 'entries': final List entries}) {
    return [
      for (final item in entries)
        if (item case {
          'id': final String id,
          'title': final String title,
          'text': final String text,
          'formats': final List formats,
          'savedAt': final String savedAt,
        })
          if (DateTime.tryParse(savedAt) case final DateTime date)
            HistoryEntry(
              id: id,
              title: title,
              text: text,
              formats: {
                for (final format in ExportFormat.values)
                  if (formats.contains(format.apiValue)) format,
              },
              savedAt: date,
              renamed: item['renamed'] == true, // spec 010
            ),
    ];
  }
  return const [];
}

class FileHistoryStore implements HistoryStore {
  FileHistoryStore({
    required Future<Directory> Function() directory,
    required this.fileName,
  }) : _directory = directory;

  /// Nombre del archivo; la app usa historyFileNameFor(id) para cada cuenta.
  final String fileName;

  /// Carpeta privada de la app (getApplicationSupportDirectory en Android).
  final Future<Directory> Function() _directory;

  @override
  Future<List<HistoryEntry>> load() async {
    final file = File(p.join((await _directory()).path, fileName));
    try {
      if (!await file.exists()) return const [];
      return decodeHistory(await file.readAsString());
    } on FileSystemException {
      return const [];
    }
  }

  @override
  Future<void> save(List<HistoryEntry> entries) async {
    final folder = await _directory();
    await folder.create(recursive: true);
    // Escritura atómica: primero un temporal y luego se renombra.
    final temporary = File(p.join(folder.path, '$fileName.tmp'));
    await temporary.writeAsString(encodeHistory(entries), flush: true);
    await temporary.rename(p.join(folder.path, fileName));
  }

  @override
  Future<void> delete() async {
    final file = File(p.join((await _directory()).path, fileName));
    if (await file.exists()) await file.delete();
  }
}
