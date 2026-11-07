// Imagen elegida por el usuario y su copia de trabajo (tarea T015; data-model.md).

import 'dart:typed_data';

import 'image_format.dart';

/// De dónde vino la imagen. Define qué se ofrece para reemplazarla:
/// «Elegir otra imagen» (galería), «Repetir captura» (cámara) o, desde la spec 009,
/// «Escanear de nuevo» (escáner de documentos) [ED-H3-E3].
enum ImageOrigin { gallery, camera, scanner }

/// Copia privada de la imagen dentro de la caché de la app.
/// Constitución §3: la app trabaja sobre esta copia, nunca sobre el original.
class WorkingCopy {
  const WorkingCopy({required this.path, required this.bytes});

  /// Ruta de la copia en `<caché>/handtext_work/`.
  final String path;

  /// Contenido de la imagen (como máximo 10 MB).
  final Uint8List bytes;
}

/// Imagen que ya pasó la validación y se muestra en la vista previa.
class PickedImage {
  const PickedImage({
    required this.workingCopy,
    required this.format,
    required this.width,
    required this.height,
    required this.origin,
  });

  /// Copia privada sobre la que trabaja la app.
  final WorkingCopy workingCopy;
  /// JPEG o PNG, según el contenido del archivo.
  final ImageFormat format;
  /// Ancho en píxeles.
  final int width;
  /// Alto en píxeles.
  final int height;
  /// De dónde vino: galería, cámara o escáner.
  final ImageOrigin origin;

  /// Contenido de la imagen (el de la copia de trabajo).
  Uint8List get bytes => workingCopy.bytes;
  /// Tamaño en bytes (el máximo es 10 MB).
  int get sizeBytes => workingCopy.bytes.length;
}
