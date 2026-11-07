// Controlador de la sesión (tarea T125; spec 002, Historias 1 y 2).
//
// Decide si se muestra la bienvenida (sin sesión) o la app (con sesión), y concentra
// el registro, el ingreso, el cierre de sesión, la eliminación de la cuenta y el
// vencimiento de la sesión. No contiene widgets (constitución §4).
// Etiquetas: [CU-H1-E2] = spec 002, Historia 1, escenario 2.

import 'dart:async';

import 'package:flutter/foundation.dart';

import '../models/app_failure.dart';
import '../models/operation_status.dart';
import '../models/user_account.dart';
import '../services/auth_api_client.dart';
import '../services/session_store.dart';

/// Estado de la sesión: comprobando (al abrir la app), sin sesión o con sesión.
enum AuthStatus { checking, signedOut, signedIn }

class AuthController extends ChangeNotifier {
  AuthController({required AuthApi api, required SessionStore sessions})
    : _api = api,
      _sessions = sessions;

  final AuthApi _api;
  final SessionStore _sessions;

  AuthStatus _status = AuthStatus.checking;
  StoredSession? _session;
  bool _isBusy = false;
  AppFailure? _failure;
  StatusEvent? _notice;
  bool _isDisposed = false;

  AuthStatus get status => _status;

  /// Cuenta con sesión (null sin sesión).
  UserAccount? get user => _session?.user;

  /// Token para la cabecera Authorization (lo lee HandTextApiClient).
  String? get token => _session?.token;

  /// [SC-008] Hay una operación de cuenta en curso.
  bool get isBusy => _isBusy;

  /// Último fallo del registro, el ingreso o la eliminación (para mostrarlo).
  AppFailure? get failure => _failure;

  /// Aviso para la bienvenida: sesión vencida, sesión cerrada o cuenta eliminada.
  StatusEvent? get notice => _notice;

  /// Al abrir la app: [CU-H1-E9] si hay una sesión guardada, se comprueba con la API.
  Future<void> initialize() async {
    StoredSession? stored;
    try {
      stored = await _sessions.read();
    } on Exception {
      stored = null;
    }
    if (stored == null) {
      _status = AuthStatus.signedOut;
      _notify();
      return;
    }

    _session = stored;
    try {
      final user = await _api.me(stored.token);
      _session = StoredSession(token: stored.token, user: user);
      await _saveQuietly(_session!);
      _status = AuthStatus.signedIn;
    } on AppFailure catch (failure) {
      if (failure.kind == FailureKind.sessionExpired) {
        // [CU-H2-E5] El servidor ya no reconoce la sesión: se pide ingresar de nuevo.
        await _clearQuietly();
        _session = null;
        _status = AuthStatus.signedOut;
        _notice = StatusEvent.sessionExpired;
      } else {
        // Caso límite de la spec 002: sin conexión se entra con los datos guardados.
        _status = AuthStatus.signedIn;
      }
    }
    _notify();
  }

  /// [CU-H1-E2] Crea la cuenta e inicia la sesión. Devuelve true si lo logró.
  Future<bool> register({
    required String displayName,
    required String email,
    required String password,
    required bool acceptsDataPolicy,
  }) => _startSession(
    () => _api.register(
      displayName: displayName,
      email: email,
      password: password,
      acceptsDataPolicy: acceptsDataPolicy,
    ),
  );

  /// [CU-H1-E6] Inicia sesión con correo y contraseña.
  Future<bool> signIn({required String email, required String password}) =>
      _startSession(() => _api.login(email: email, password: password));

  Future<bool> _startSession(Future<AuthResult> Function() request) async {
    if (_isBusy) return false;
    _isBusy = true;
    _failure = null;
    _notify();
    try {
      final result = await request();
      _session = StoredSession(token: result.token, user: result.user);
      // [CU-H1-E9] Guardada en el almacenamiento seguro: sobrevive al cierre de la app.
      await _saveQuietly(_session!);
      _status = AuthStatus.signedIn;
      _notice = null;
      return true;
    } on AppFailure catch (failure) {
      _failure = failure; // [CU-H1-E3] [CU-H1-E7] [CU-H1-E8]
      return false;
    } on Exception {
      _failure = const AppFailure(FailureKind.unexpected);
      return false;
    } finally {
      _isBusy = false;
      _notify();
    }
  }

  /// [CU-H2-E1] Cierra la sesión. [beforeSignOut] borra antes los datos locales de la
  /// cuenta (el borrador), si la pantalla lo pidió con confirmación [CU-H2-E2].
  Future<void> signOut({Future<void> Function()? beforeSignOut}) async {
    if (_isBusy) return;
    final token = this.token;
    _isBusy = true;
    _notify();
    try {
      await beforeSignOut?.call();
      if (token != null) {
        try {
          await _api.logout(token); // el token deja de servir en el servidor
        } on Exception {
          // Sin conexión: la sesión local se borra igual y vencerá en el servidor.
        }
      }
    } finally {
      await _clearQuietly();
      _session = null;
      _status = AuthStatus.signedOut;
      _notice = StatusEvent.signedOut;
      _isBusy = false;
      _notify();
    }
  }

  /// [CU-H2-E3] Elimina la cuenta confirmando con la contraseña. Devuelve true si lo
  /// logró; con una contraseña incorrecta la cuenta se conserva [CU-H2-E4].
  Future<bool> deleteAccount(
    String password, {
    Future<void> Function()? beforeSignOut,
  }) async {
    final token = this.token;
    if (token == null || _isBusy) return false;
    _isBusy = true;
    _failure = null;
    _notify();
    try {
      await _api.deleteAccount(token, password);
      await beforeSignOut?.call(); // borra el borrador de esta persona
      await _clearQuietly();
      _session = null;
      _status = AuthStatus.signedOut;
      _notice = StatusEvent.accountDeleted;
      return true;
    } on AppFailure catch (failure) {
      _failure = failure;
      return false;
    } finally {
      _isBusy = false;
      _notify();
    }
  }

  /// [CU-H2-E5] La API rechazó la sesión (401): se vuelve a la bienvenida. El borrador
  /// de esta persona se conserva y se recupera cuando vuelva a ingresar.
  void handleSessionExpired() {
    if (_status != AuthStatus.signedIn) return;
    _session = null;
    _status = AuthStatus.signedOut;
    _notice = StatusEvent.sessionExpired;
    _notify();
    unawaited(_clearQuietly());
  }

  /// Borra el fallo mostrado (por ejemplo, al cambiar de pantalla).
  void clearFailure() {
    if (_failure == null) return;
    _failure = null;
    _notify();
  }

  Future<void> _saveQuietly(StoredSession session) async {
    try {
      await _sessions.save(session);
    } on Exception catch (error) {
      debugPrint('No se pudo guardar la sesión: ${error.runtimeType}');
    }
  }

  Future<void> _clearQuietly() async {
    try {
      await _sessions.clear();
    } on Exception catch (error) {
      debugPrint('No se pudo borrar la sesión: ${error.runtimeType}');
    }
  }

  void _notify() {
    if (!_isDisposed) notifyListeners();
  }

  @override
  void dispose() {
    _isDisposed = true;
    super.dispose();
  }
}
