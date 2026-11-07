// Recorte y giro de la imagen (tarea T211; spec 003, módulo 2; research.md de 003, R6).
//
// Abre uCrop, el editor nativo de Android, a través de image_cropper:
// - uCrop recorta el archivo en código nativo, sin cargar en Dart una foto que podría
//   tener 10 000 × 10 000 píxeles;
// - recibe la ruta de la COPIA de trabajo, nunca la del original (constitución §3), y
//   deja el resultado en la caché de la app;
// - el resultado conserva el formato de la imagen (JPEG o PNG).
// Devuelve el archivo resultante o null si la persona canceló [EX-H2-E3]. El
// controlador lo copia a una nueva copia de trabajo, que borra el archivo de uCrop
// (WorkingCopyService borra los intermedios que están dentro de la caché).

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:image_picker/image_picker.dart';

import '../models/app_failure.dart';
import '../models/image_format.dart';
import '../models/picked_image.dart';
import '../theme/aurora.dart';

/// Lo que el controlador necesita para recortar. Las pruebas usan una versión falsa.
abstract interface class ImageEditor {
  /// Abre el editor con [copy]. Devuelve la imagen editada, o null si se canceló.
  Future<XFile?> cropAndRotate(WorkingCopy copy, ImageFormat format);
}

class NativeImageEditor implements ImageEditor {
  const NativeImageEditor({required this.title});

  /// Título de la barra del editor en el idioma actual (spec 008: se lee al abrirlo,
  /// desde AppStrings.current; research.md de 008, R3).
  final String Function() title;

  @override
  Future<XFile?> cropAndRotate(WorkingCopy copy, ImageFormat format) async {
    try {
      final cropped = await ImageCropper().cropImage(
        sourcePath: copy.path,
        compressFormat: format == ImageFormat.png
            ? ImageCompressFormat.png
            : ImageCompressFormat.jpg,
        compressQuality: 95,
        uiSettings: [
          // Colores de la identidad Aurora (paleta azul corporativo).
          AndroidUiSettings(
            toolbarTitle: title(),
            toolbarColor: Aurora.backgroundBottom,
            statusBarLight: false,
            navBarLight: false,
            toolbarWidgetColor: Colors.white,
            backgroundColor: Aurora.backgroundTop,
            activeControlsWidgetColor: Aurora.blue,
            cropFrameColor: Colors.white,
            cropGridColor: Colors.white54,
            lockAspectRatio: false, // recorte libre: cada hoja tiene su forma
            hideBottomControls: false, // botones de girar y escalar
          ),
        ],
      );
      return cropped == null ? null : XFile(cropped.path);
    } on PlatformException {
      // El editor no pudo abrir o procesar la imagen: la imagen no cambia.
      throw const AppFailure(FailureKind.imageEditFailed);
    }
  }
}
