// Escáner de documentos (tarea T801; spec 009; research.md de 009, R1 a R4).
//
// Abre el escáner de documentos de Google ML Kit: detecta los bordes de la hoja, la
// recorta y endereza, y deja elegir un filtro. Todo pasa en el teléfono; no envía nada.
// - Modo con filtros, sin limpieza automática, para no borrar trazos de la escritura
//   (R2; constitución §3).
// - Cancelar devuelve null [ED-H1-E5]; si el escáner no puede abrirse, avisa que no está
//   disponible [ED-H2-E1] (R3).
// - Las hojas se leen en memoria y sus archivos se borran enseguida (R4): solo quedan
//   las copias de trabajo de la app.

import 'dart:io';

import 'package:flutter/services.dart';
import 'package:google_mlkit_document_scanner/google_mlkit_document_scanner.dart';
import 'package:image_picker/image_picker.dart';

import '../models/app_failure.dart';

/// Lo que el controlador necesita del escáner. Las pruebas usan uno falso.
abstract interface class DocumentScannerService {
  /// Escanea hasta [pageLimit] hojas. Devuelve las imágenes JPEG, o null si la persona
  /// canceló. Lanza [AppFailure] si el escáner no está disponible o falla.
  Future<List<XFile>?> scan({required int pageLimit});
}

class MlKitDocumentScanner implements DocumentScannerService {
  const MlKitDocumentScanner();

  /// Mensajes del complemento (DocumentScanner.kt) para cancelar y para no poder abrir.
  static const _cancelled = 'Operation cancelled';
  static const _cannotStart = 'Failed to start document scanner';

  @override
  Future<List<XFile>?> scan({required int pageLimit}) async {
    final scanner = DocumentScanner(
      options: DocumentScannerOptions(
        documentFormats: const {DocumentFormat.jpeg},
        mode: ScannerMode.filter, // R2
        pageLimit: pageLimit,
      ),
    );
    try {
      final result = await scanner.scanDocument();
      final pages = <XFile>[];
      for (final (index, path) in (result.images ?? const <String>[]).indexed) {
        final file = File(path);
        pages.add(
          XFile.fromData(
            await file.readAsBytes(),
            name: 'escaneo_${index + 1}.jpg',
            mimeType: 'image/jpeg',
          ),
        );
        await _deleteQuietly(file); // R4: no quedan archivos del escáner
      }
      return pages;
    } on PlatformException catch (error) {
      if (error.message == _cancelled) return null;
      throw AppFailure(
        error.message == _cannotStart
            ? FailureKind.scannerUnavailable
            : FailureKind.scannerFailed,
      );
    } on FileSystemException {
      throw const AppFailure(FailureKind.scannerFailed);
    } finally {
      await scanner.close();
    }
  }

  static Future<void> _deleteQuietly(File file) async {
    try {
      await file.delete();
    } on FileSystemException {
      // Si no se puede borrar, queda en la caché, que Android limpia solo.
    }
  }
}
