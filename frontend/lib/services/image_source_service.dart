// Obtención de la imagen desde la galería o la cámara (tareas T040 y T047).
//
// - Galería (Historia 1): selector de fotos del sistema; en Android no necesita permisos.
// - Cámara (Historia 2): la app de cámara del sistema. El permiso lo pide antes
//   camera_permission_service.dart.
// image_picker entrega una COPIA en la caché de la app; el original del usuario no se
// toca (constitución §3).
// Spec 004 (tarea T303): la galería permite elegir varias imágenes a la vez, hasta las
// páginas que todavía caben en el documento (research.md de 004, R1).

import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';

import '../models/app_failure.dart';

/// Lo que el controlador necesita para obtener imágenes. Las pruebas usan una falsa.
abstract interface class ImageSourceService {
  /// Devuelve la imagen elegida, o null si el usuario canceló.
  Future<XFile?> pickFromGallery();

  /// Devuelve las imágenes elegidas (como máximo [limit]); vacía si canceló.
  Future<List<XFile>> pickMultipleFromGallery({required int limit});

  /// Devuelve la fotografía tomada, o null si el usuario canceló.
  Future<XFile?> takePhoto();
}

class PickerImageSourceService implements ImageSourceService {
  PickerImageSourceService({ImagePicker? picker})
    : _picker = picker ?? ImagePicker();

  final ImagePicker _picker;

  @override
  Future<XFile?> pickFromGallery() async {
    try {
      return await _picker.pickImage(source: ImageSource.gallery);
    } on PlatformException {
      throw const AppFailure(FailureKind.imageUnreadable);
    }
  }

  @override
  Future<List<XFile>> pickMultipleFromGallery({required int limit}) async {
    // El selector múltiple de Android exige un límite de 2 o más.
    if (limit < 2) {
      final single = await pickFromGallery();
      return single == null ? const [] : [single];
    }
    try {
      return await _picker.pickMultiImage(limit: limit);
    } on PlatformException {
      throw const AppFailure(FailureKind.imageUnreadable);
    }
  }

  @override
  Future<XFile?> takePhoto() async {
    try {
      return await _picker.pickImage(source: ImageSource.camera);
    } on PlatformException catch (error) {
      if (error.code == 'camera_access_denied') {
        throw const AppFailure(FailureKind.cameraPermissionDenied);
      }
      // Por ejemplo, un teléfono sin cámara disponible.
      throw const AppFailure(FailureKind.cameraUnavailable);
    }
  }
}
