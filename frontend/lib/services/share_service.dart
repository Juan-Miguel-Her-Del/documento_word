// Compartir el documento guardado (tarea T214; spec 003, módulo 3; research.md de 003,
// R7 y R8).
//
// 1. Borra lo que haya quedado de un envío anterior (purge).
// 2. Escribe en `<caché>/handtext_share/` una copia exacta del archivo exportado
//    [SC-305].
// 3. Abre el selector de Android con share_plus. La persona elige la app; HandText AI
//    no envía nada por su cuenta (constitución §3, Privacidad).
// 4. Borra esa copia en cuanto el selector se cierra.
//
// share_plus, por su parte, copia el archivo a `<caché>/share_plus/` y lo deja ahí
// hasta el próximo envío, para que la app elegida pueda leerlo. purge también borra
// esa carpeta. Se llama al compartir, al abrir la app y al cerrar sesión o eliminar la
// cuenta (research.md de 003, R8).

import 'dart:io';
import 'dart:typed_data';

import 'package:path/path.dart' as p;
import 'package:share_plus/share_plus.dart';

import '../models/app_failure.dart';
import '../models/export_format.dart';

/// Lo que el controlador necesita para compartir. Las pruebas usan una versión falsa.
abstract interface class DocumentSharer {
  /// Abre el selector de Android con el archivo. Termina cuando el selector se cierra.
  Future<void> share({
    required Uint8List bytes,
    required String fileName,
    required ExportFormat format,
  });

  /// Borra las copias temporales para compartir.
  Future<void> purge();
}

class SystemDocumentSharer implements DocumentSharer {
  SystemDocumentSharer({required Future<Directory> Function() cacheDirectory})
    : _cacheDirectory = cacheDirectory;

  /// Nombre de la carpeta propia dentro de la caché de la app.
  static const folderName = 'handtext_share';

  /// Carpeta donde share_plus deja su copia del último archivo compartido.
  static const sharePlusFolderName = 'share_plus';

  final Future<Directory> Function() _cacheDirectory;

  Future<Directory> _folder(String name) async =>
      Directory(p.join((await _cacheDirectory()).path, name));

  @override
  Future<void> share({
    required Uint8List bytes,
    required String fileName,
    required ExportFormat format,
  }) async {
    try {
      await purge(); // [EX-H3-E5] las copias anteriores se borran
      final folder = await _folder(folderName);
      await folder.create(recursive: true);
      // basename: el nombre nunca puede salir de la carpeta.
      final file = File(p.join(folder.path, p.basename(fileName)));
      await file.writeAsBytes(bytes, flush: true);
      try {
        await SharePlus.instance.share(
          ShareParams(files: [XFile(file.path, mimeType: format.mimeType)]),
        );
      } finally {
        // share_plus ya hizo su propia copia: la nuestra no se necesita más.
        if (await file.exists()) await file.delete();
      }
    } on Exception {
      throw const AppFailure(FailureKind.shareFailed);
    }
  }

  @override
  Future<void> purge() async {
    for (final name in [folderName, sharePlusFolderName]) {
      final folder = await _folder(name);
      if (await folder.exists()) await folder.delete(recursive: true);
    }
  }
}
