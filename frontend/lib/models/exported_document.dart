// Documento recién exportado, guardado solo en memoria para poder compartirlo
// (tarea T215; spec 003, Historia 3; data-model.md de 003).

import 'dart:typed_data';

import 'export_format.dart';

/// El último archivo exportado, guardado solo en memoria (no en el teléfono).
///
/// Sirve para «Compartir»: se comparte exactamente el mismo archivo que se guardó, sin
/// pedirlo otra vez a la API [SC-305].
class ExportedDocument {
  const ExportedDocument({
    required this.bytes,
    required this.fileName,
    required this.format,
  });

  /// El archivo tal como lo devolvió la API: se comparte idéntico [SC-305].
  final Uint8List bytes;

  /// Nombre propuesto al guardar (por ejemplo, HandText_20261028_1530.pdf).
  final String fileName;

  /// Word o PDF.
  final ExportFormat format;
}
