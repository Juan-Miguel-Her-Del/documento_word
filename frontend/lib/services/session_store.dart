// Sesión guardada en el almacenamiento seguro del teléfono (tarea T123).
//
// Spec 002, módulo 3: «La sesión se guarda en el almacenamiento seguro del teléfono».
// flutter_secure_storage la cifra con una clave del Android Keystore (research.md de
// 002, R7). Se guardan el token y los datos visibles de la cuenta, para poder entrar
// sin conexión; nunca la contraseña.

import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../models/user_account.dart';

/// Token de sesión y la cuenta a la que pertenece.
class StoredSession {
  const StoredSession({required this.token, required this.user});

  final String token;
  final UserAccount user;
}

/// Operaciones sobre la sesión guardada. Las pruebas usan una versión en memoria.
abstract interface class SessionStore {
  Future<StoredSession?> read();

  Future<void> save(StoredSession session);

  Future<void> clear();
}

class SecureSessionStore implements SessionStore {
  SecureSessionStore({FlutterSecureStorage? storage})
    : _storage = storage ?? const FlutterSecureStorage();

  static const _key = 'handtext_session';

  final FlutterSecureStorage _storage;

  @override
  Future<StoredSession?> read() async {
    final raw = await _storage.read(key: _key);
    if (raw == null) return null;
    try {
      return switch (jsonDecode(raw)) {
        {'token': final String token, 'user': final Object user} =>
          StoredSession(token: token, user: UserAccount.fromJson(user)),
        _ => null,
      };
    } on FormatException {
      return null; // dato dañado: se ignora y se pide ingresar de nuevo
    }
  }

  @override
  Future<void> save(StoredSession session) => _storage.write(
    key: _key,
    value: jsonEncode({'token': session.token, 'user': session.user.toJson()}),
  );

  @override
  Future<void> clear() => _storage.delete(key: _key);
}
