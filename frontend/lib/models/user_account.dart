// Cuenta de usuario visible en la app (tarea T120; spec 002; data-model.md de 002).
// Nunca contiene la contraseña: solo el id, el nombre y el correo.

/// La cuenta con la sesión iniciada, tal como la devuelve la API.
///
/// Se guarda junto con la sesión (SessionStore) para mostrar el nombre al abrir la
/// app sin volver a pedirlo.
class UserAccount {
  const UserAccount({
    required this.id,
    required this.displayName,
    required this.email,
  });

  /// Lee el objeto `user` que devuelve la API. Lanza FormatException si no coincide.
  factory UserAccount.fromJson(Object? json) => switch (json) {
    {
      'id': final String id,
      'display_name': final String displayName,
      'email': final String email,
    } =>
      UserAccount(id: id, displayName: displayName, email: email),
    _ => throw const FormatException('Cuenta con formato inesperado'),
  };

  /// Identificador (UUID) que genera la base de datos. También separa en el teléfono
  /// los archivos de cada cuenta: el borrador y el historial.
  final String id;

  /// Nombre que la persona escribió al crear la cuenta (de 1 a 60 caracteres).
  final String displayName;

  /// Correo con el que ingresa.
  final String email;

  /// El mismo formato de [UserAccount.fromJson], para guardarla con la sesión.
  Map<String, String> toJson() => {
    'id': id,
    'display_name': displayName,
    'email': email,
  };

  /// Primer nombre para el saludo: «Ana María» → «Ana».
  String get firstName => displayName.split(' ').first;

  /// Inicial para el avatar.
  String get initial => displayName.isEmpty
      ? '?'
      : String.fromCharCode(displayName.runes.first).toUpperCase();
}
