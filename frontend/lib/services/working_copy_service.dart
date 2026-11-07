// Copias de trabajo de la imagen (tarea T036; research.md, R8; spec, módulo 6).
//
// Constitución §3, Conservación del original: la app nunca trabaja sobre el archivo
// del usuario. Copia la imagen a su carpeta privada `handtext_work`, dentro de la
// caché de la app, y trabaja con esa copia.
//
// Retención (Clarifications 2026-10-26): la copia se borra al terminar el
// reconocimiento, al cancelar o al reemplazar la imagen, y la carpeta entera se purga
// al abrir la app por si quedó algo de una sesión anterior.

import 'dart:io';

import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as p;

import '../models/picked_image.dart';

/// Operaciones sobre las copias de trabajo. Las pruebas de pantallas usan una versión
/// en memoria.
abstract interface class WorkingCopyStore {
  /// Copia la imagen elegida a la carpeta privada y devuelve la copia.
  Future<WorkingCopy> createFrom(XFile picked);

  /// Borra una copia de trabajo.
  Future<void> delete(WorkingCopy copy);

  /// Borra todas las copias (al abrir la app).
  Future<void> purgeAll();
}

class WorkingCopyService implements WorkingCopyStore {
  WorkingCopyService({
    required Future<Directory> Function() cacheDirectory,
    DateTime Function() now = DateTime.now,
  }) : _cacheDirectory = cacheDirectory,
       _now = now;

  /// Nombre de la carpeta propia dentro de la caché de la app.
  static const folderName = 'handtext_work';

  final Future<Directory> Function() _cacheDirectory;
  final DateTime Function() _now;

  @override
  Future<WorkingCopy> createFrom(XFile picked) async {
    final bytes = await picked.readAsBytes();
    final folder = Directory(
      p.join((await _cacheDirectory()).path, folderName),
    );
    await folder.create(recursive: true);

    final copy = File(
      p.join(
        folder.path,
        'imagen_${_now().microsecondsSinceEpoch}${p.extension(picked.path)}',
      ),
    );
    await copy.writeAsBytes(bytes, flush: true);

    // image_picker deja su propio archivo temporal en la caché; ya no se necesita.
    await _deletePickerTemporaryFile(picked.path);
    return WorkingCopy(path: copy.path, bytes: bytes);
  }

  /// Borra el archivo intermedio de image_picker SOLO si está dentro de la caché de
  /// la app. Así es imposible borrar el original del usuario, que vive en la
  /// galería o en el almacenamiento compartido.
  Future<void> _deletePickerTemporaryFile(String path) async {
    final cache = await _cacheDirectory();
    if (path.isEmpty || !p.isWithin(cache.path, path)) return;
    await _deleteIfExists(File(path));
  }

  @override
  Future<void> delete(WorkingCopy copy) => _deleteIfExists(File(copy.path));

  @override
  Future<void> purgeAll() async {
    final folder = Directory(
      p.join((await _cacheDirectory()).path, folderName),
    );
    if (await folder.exists()) await folder.delete(recursive: true);
  }

  Future<void> _deleteIfExists(File file) async {
    try {
      if (await file.exists()) await file.delete();
    } on FileSystemException {
      // Si ya no existe o no se puede borrar ahora, se intentará al abrir la app.
    }
  }
}
