// Cuándo la app está bloqueada (tarea T1005; spec 011; research.md de 011, R3).
//
// - Con el bloqueo activo, la app empieza bloqueada si abre con una sesión guardada
//   [BL-H2-E1]. Sin sesión no hay nada que bloquear [BL-H2-E5].
// - Al volver después de más de 1 minuto en segundo plano, se bloquea; si pasó menos,
//   no [BL-H2-E4] (supuesto 2).
// - Desbloquear o activar el bloqueo pide la verificación del teléfono
//   (DeviceAuthenticator); si se cancela o falla, nada cambia [BL-H2-E3] [SC-1102].
// La hora se recibe desde afuera para probar sin esperar.

import 'package:flutter/widgets.dart';

import '../services/device_authenticator.dart';
import 'auth_controller.dart';
import 'settings_controller.dart';

class AppLockController extends ChangeNotifier with WidgetsBindingObserver {
  AppLockController({
    required SettingsController settings,
    required AuthController auth,
    required this.authenticator,
    DateTime Function() now = DateTime.now,
    this.timeout = const Duration(minutes: 1),
  }) : _settings = settings,
       _auth = auth,
       _now = now,
       // [BL-H2-E1] Con el bloqueo activo, la app abre bloqueada.
       _locked = settings.settings.appLock;

  final SettingsController _settings;
  final AuthController _auth;
  final DateTime Function() _now;

  /// Verificación del teléfono (huella, rostro o bloqueo de pantalla).
  final DeviceAuthenticator authenticator;

  /// Tiempo en segundo plano que hace bloquear al volver (supuesto 2).
  final Duration timeout;

  bool _locked;
  bool _verifying = false;
  DateTime? _backgroundedAt;

  /// [SC-1101] true: se ve la pantalla de bloqueo en lugar de la app. Solo con el
  /// bloqueo activo y una sesión iniciada.
  bool get isLocked =>
      _locked &&
      _settings.settings.appLock &&
      _auth.status == AuthStatus.signedIn;

  /// Empieza a observar la app (al abrirla).
  void start() {
    WidgetsBinding.instance.addObserver(this);
    _auth.addListener(_onAuthChanged);
    _settings.addListener(notifyListeners);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _auth.removeListener(_onAuthChanged);
    _settings.removeListener(notifyListeners);
    super.dispose();
  }

  /// [BL-H2-E5] Sin sesión no hay nada que bloquear; quien ingresa con su contraseña
  /// ya se verificó.
  void _onAuthChanged() {
    if (_auth.status == AuthStatus.signedOut) _locked = false;
    notifyListeners();
  }

  /// [BL-H2-E4] Al volver después de más de [timeout] en segundo plano, se bloquea.
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.paused || AppLifecycleState.hidden:
        _backgroundedAt ??= _now();
      case AppLifecycleState.resumed:
        final since = _backgroundedAt;
        _backgroundedAt = null;
        if (since != null &&
            _now().difference(since) > timeout &&
            _auth.status == AuthStatus.signedIn) {
          _locked = true;
          notifyListeners();
        }
      case AppLifecycleState.inactive || AppLifecycleState.detached:
        break;
    }
  }

  /// [BL-H2-E2] [BL-H2-E3] Pide la verificación; solo una a la vez.
  Future<void> unlock(String reason) async {
    if (_verifying || !isLocked) return;
    _verifying = true;
    try {
      if (await authenticator.authenticate(reason)) {
        _locked = false; // [SC-1103] la app sigue donde estaba
      }
    } finally {
      _verifying = false;
      notifyListeners();
    }
  }

  /// [BL-H1-E2] [BL-H1-E3] [SC-1104] Activa el bloqueo solo si la verificación es
  /// correcta. Devuelve si quedó activo.
  Future<bool> enable(String reason) async {
    if (_verifying) return false;
    _verifying = true;
    try {
      final verified = await authenticator.authenticate(reason);
      if (verified) await _settings.setAppLock(true);
      return verified;
    } finally {
      _verifying = false;
    }
  }

  /// [BL-H3-E1] Desactiva el bloqueo: la app deja de pedir la verificación.
  Future<void> disable() async {
    _locked = false;
    await _settings.setAppLock(false);
  }
}
