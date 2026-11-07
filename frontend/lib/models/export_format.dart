// Formatos de exportación (tarea T015; constitución §3, Formatos de salida):
// Word (.docx) y PDF (.pdf). Cada formato conoce su «firma»: los primeros bytes que
// debe tener un archivo real de ese tipo. Con ella la app comprueba que lo recibido
// es de verdad un .docx o un .pdf y no un archivo renombrado (SC-001).

import 'dart:typed_data';

/// Formatos en que se guarda el texto: Word o PDF.
///
/// Cada uno sabe su nombre para la API, su extensión, su tipo MIME y su firma.
enum ExportFormat {
  /// Documento de Word (.docx). Por dentro es un ZIP: su firma es «PK».
  docx(
    apiValue: 'docx',
    extension: 'docx',
    label: 'Word',
    mimeType:
        'application/vnd.openxmlformats-officedocument.wordprocessingml.document',
    signature: [0x50, 0x4B], // "PK": un .docx es un archivo ZIP
  ),
  /// Documento PDF (.pdf). Su firma es «%PDF-».
  pdf(
    apiValue: 'pdf',
    extension: 'pdf',
    label: 'PDF',
    mimeType: 'application/pdf',
    signature: [0x25, 0x50, 0x44, 0x46, 0x2D], // "%PDF-"
  );

  const ExportFormat({
    required this.apiValue,
    required this.extension,
    required this.label,
    required this.mimeType,
    required this.signature,
  });

  /// Valor del campo `format` que espera la API.
  final String apiValue;

  /// Extensión del archivo que se guarda.
  final String extension;

  /// Nombre que se muestra al usuario.
  final String label;

  /// Tipo MIME, para que la app que recibe el archivo al compartirlo sepa abrirlo
  /// (spec 003).
  final String mimeType;

  /// Primeros bytes de un archivo real de este formato.
  final List<int> signature;

  /// Indica si [bytes] empiezan con la firma de este formato.
  bool matchesContent(Uint8List bytes) {
    if (bytes.length < signature.length) return false;
    for (var i = 0; i < signature.length; i++) {
      if (bytes[i] != signature[i]) return false;
    }
    return true;
  }
}
