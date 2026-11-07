// Verificación de la persona con la huella, el rostro o el bloqueo de pantalla del
// teléfono (tarea T1001; spec 011; research.md de 011, R1).
//
// Usa local_auth, que muestra el cuadro de Android (BiometricPrompt). La huella y el
// rostro nunca llegan a la app: Android solo responde si la verificación fue correcta
// (spec 011, módulo 3).

import 'package:flutter/services.dart';
import 'package:local_auth/local_auth.dart';

/// Lo que la app necesita para verificar a la persona. Las pruebas usan uno falso.
abstract interface class DeviceAuthenticator {
  /// ¿El teléfono tiene huella, rostro o bloqueo de pantalla configurados?
  /// [BL-H1-E4]
  Future<bool> isAvailable();

  /// Pide la verificación mostrando [reason]. Devuelve true solo si fue correcta;
  /// cancelar o fallar devuelve false [BL-H2-E3].
  Future<bool> authenticate(String reason);
}

class LocalDeviceAuthenticator implements DeviceAuthenticator {
  LocalDeviceAuthenticator({LocalAuthentication? auth})
    : _auth = auth ?? LocalAuthentication();

  final LocalAuthentication _auth;

  @override
  Future<bool> isAvailable() async {
    try {
      return await _auth.isDeviceSupported();
    } on PlatformException {
      return false;
    }
  }

  @override
  Future<bool> authenticate(String reason) async {
    try {
      return await _auth.authenticate(
        localizedReason: reason,
        // Huella, rostro o el PIN, patrón o contraseña del teléfono (supuesto 3).
        biometricOnly: false,
        // Si la app pasa a segundo plano durante el cuadro, se retoma al volver.
        persistAcrossBackgrounding: true,
      );
    } on LocalAuthException {
      return false; // cancelada, sin credenciales o no disponible
    } on PlatformException {
      return false;
    }
  }
}
