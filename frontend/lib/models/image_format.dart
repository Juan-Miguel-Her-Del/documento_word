// Formatos de imagen admitidos (tarea T015; spec, módulo 1): JPEG y PNG.
// El formato se identifica por el contenido del archivo, no por su extensión
// (ver services/image_rules.dart).

/// Formatos de imagen que la app acepta (spec, módulo 1).
enum ImageFormat {
  /// Fotografías de la cámara, del escáner y la mayoría de la galería.
  jpeg(mimeType: 'image/jpeg', label: 'JPEG'),
  /// Capturas de pantalla e imágenes guardadas sin pérdida de calidad.
  png(mimeType: 'image/png', label: 'PNG');

  const ImageFormat({required this.mimeType, required this.label});

  /// Tipo MIME que se envía a la API en la cabecera Content-Type.
  final String mimeType;

  /// Nombre que se muestra al usuario.
  final String label;
}
