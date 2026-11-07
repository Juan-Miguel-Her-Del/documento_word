// Borrador local del texto en edición (tareas T037 y T208; research.md, R7).
//
// Clarifications del spec (2026-10-26): el texto con cambios no exportados se guarda
// en el almacenamiento PRIVADO de la app, se recupera al volver a abrirla (Historia 1,
// escenario 15) y se elimina al exportar correctamente o al descartarlo (escenarios
// 16 y 17; SC-011). AndroidManifest.xml excluye este archivo de las copias de
// seguridad.
//
// Spec 002 (tarea T131): cada cuenta tiene su propio archivo de borrador
// (draft_<id>.txt), así nadie ve el texto de otra persona en el mismo teléfono [SC-206].
//
// Spec 003 (tarea T208; research.md de 003, R5): el archivo guarda en JSON el texto y
// las marcas de palabras dudosas («formato 2»). Los borradores anteriores, que eran
// texto plano («formato 1»), se siguen leyendo.
//
// Spec 007 (tarea T609): el formato 2 suma el campo opcional historyId; sin él, el
// documento todavía no se guardó (data-model.md de 007).

import 'dart:convert';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:path/path.dart' as p;

import '../models/document_draft.dart';
import 'uncertain_ranges.dart';

/// Nombre del borrador de una cuenta. Solo se dejan letras, números y guiones del id,
/// para que nunca pueda formar una ruta distinta.
String draftFileNameFor(String userId) {
  final safeId = userId.replaceAll(RegExp(r'[^A-Za-z0-9-]'), '');
  return 'draft_$safeId.txt';
}

/// Operaciones sobre el borrador. Las pruebas usan una versión en memoria.
abstract interface class DraftStore {
  /// Devuelve el borrador guardado, o null si no hay.
  Future<DocumentDraft?> load();

  /// Guarda (o reemplaza) el borrador.
  Future<void> save(DocumentDraft draft);

  /// Elimina el borrador.
  Future<void> delete();
}

/// Convierte el borrador al formato 2:
/// `{"version": 2, "text": …, "uncertain": [[0, 4]], "historyId": …}`.
String encodeDraft(DocumentDraft draft) => jsonEncode({
  'version': 2,
  'text': draft.text,
  'uncertain': [
    for (final range in draft.uncertainRanges) [range.start, range.end],
  ],
  if (draft.historyId case final String id) 'historyId': id,
});

/// Lee un borrador en formato 2 o, si no lo es, toma todo el contenido como el texto
/// de un borrador en formato 1. Las marcas que no caben en el texto se descartan.
DocumentDraft decodeDraft(String content) {
  Object? json;
  try {
    json = jsonDecode(content);
  } on FormatException {
    json = null; // texto plano: formato 1
  }
  if (json case {'version': 2, 'text': final String text} && final Map map) {
    final ranges = <TextRange>[
      if (map['uncertain'] case final List pairs)
        for (final pair in pairs)
          if (pair case [final int start, final int end])
            TextRange(start: start, end: end),
    ];
    return DocumentDraft(
      text,
      uncertainRanges: validRanges(text, ranges),
      historyId: map['historyId'] is String ? map['historyId'] as String : null,
    );
  }
  return DocumentDraft(content);
}

class FileDraftStore implements DraftStore {
  FileDraftStore({
    required Future<Directory> Function() directory,
    this.fileName = 'draft.txt',
  }) : _directory = directory;

  /// Nombre del archivo; la app usa draftFileNameFor(id) para cada cuenta.
  final String fileName;

  String get _temporaryName => '$fileName.tmp';

  /// Carpeta privada de la app (getApplicationSupportDirectory en Android).
  final Future<Directory> Function() _directory;

  Future<File> _file(String name) async =>
      File(p.join((await _directory()).path, name));

  @override
  Future<DocumentDraft?> load() async {
    final file = await _file(fileName);
    if (!await file.exists()) return null;
    try {
      return decodeDraft(await file.readAsString()); // UTF-8
    } on FileSystemException {
      return null;
    } on FormatException {
      return null; // contenido dañado: se ignora en vez de cerrar la app
    }
  }

  @override
  Future<void> save(DocumentDraft draft) async {
    final folder = await _directory();
    await folder.create(recursive: true);
    // Escritura atómica: primero un archivo temporal y luego se renombra. Si el
    // teléfono se apaga a mitad de la escritura, el borrador anterior sigue intacto.
    final temporary = File(p.join(folder.path, _temporaryName));
    await temporary.writeAsString(encodeDraft(draft), flush: true);
    await temporary.rename(p.join(folder.path, fileName));
  }

  @override
  Future<void> delete() async {
    for (final name in [fileName, _temporaryName]) {
      final file = await _file(name);
      if (await file.exists()) await file.delete();
    }
  }
}
