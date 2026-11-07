// Permiso de cámara (tarea T046; Historia 2, escenarios 1 y 2; spec, módulo 1).
//
// Si el permiso no está concedido, Android muestra su diálogo. Si el usuario lo
// deniega, la app explica para qué se necesita y permite volver al paso anterior (el
// controlador muestra el mensaje). «Denegado permanentemente» significa que Android
// ya no volverá a preguntar; en ese caso el mensaje indica cómo activarlo en Ajustes.

import 'package:permission_handler/permission_handler.dart';

/// Resultado de pedir el permiso.
enum CameraPermission { granted, denied, permanentlyDenied }

/// Lo que el controlador necesita. Las pruebas usan una versión falsa.
abstract interface class CameraPermissionService {
  Future<CameraPermission> request();
}

class HandlerCameraPermissionService implements CameraPermissionService {
  const HandlerCameraPermissionService();

  @override
  Future<CameraPermission> request() async {
    // Si ya estaba concedido, Android responde de inmediato sin mostrar el diálogo.
    final status = await Permission.camera.request();
    if (status.isGranted || status.isLimited) return CameraPermission.granted;
    if (status.isPermanentlyDenied || status.isRestricted) {
      return CameraPermission.permanentlyDenied;
    }
    return CameraPermission.denied;
  }
}
