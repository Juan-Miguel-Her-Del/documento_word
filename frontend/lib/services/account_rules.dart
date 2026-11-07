// Reglas de los formularios de cuenta (tarea T124; spec 002, módulo 1; CU-H1-E4).
//
// Son las mismas que aplica el backend (backend/app/services/accounts/rules.py). La app
// las comprueba ANTES de enviar, para orientar al usuario sin esperar al servidor; el
// servidor las vuelve a aplicar (constitución §5, Validación).

import '../models/app_failure.dart';

final _emailPattern = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');

const passwordMinChars = 8;
const passwordMaxChars = 128;
const displayNameMaxChars = 60;

/// Correo con forma válida (algo@dominio.ext, máximo 254 caracteres).
bool isValidEmail(String email) {
  final normalized = email.trim().toLowerCase();
  return normalized.length <= 254 && _emailPattern.hasMatch(normalized);
}

/// Revisa el formulario de registro; devuelve el primer problema o null si está bien.
AppFailure? validateRegistrationForm({
  required String displayName,
  required String email,
  required String password,
  required String confirmation,
  required bool acceptsDataPolicy,
}) {
  final name = displayName.trim().split(RegExp(r'\s+')).join(' ');
  if (name.isEmpty || name.length > displayNameMaxChars) {
    return const AppFailure(FailureKind.invalidDisplayName);
  }
  if (!isValidEmail(email)) return const AppFailure(FailureKind.invalidEmail);
  if (password.length < passwordMinChars ||
      password.length > passwordMaxChars ||
      password.trim().isEmpty) {
    return const AppFailure(FailureKind.weakPassword);
  }
  if (password != confirmation) {
    return const AppFailure(FailureKind.passwordMismatch);
  }
  if (!acceptsDataPolicy) {
    return const AppFailure(FailureKind.dataPolicyNotAccepted); // [CU-H1-E5]
  }
  return null;
}

/// Revisa el formulario de ingreso: ambos campos son obligatorios.
AppFailure? validateLoginForm({
  required String email,
  required String password,
}) {
  if (email.trim().isEmpty || password.isEmpty) {
    return const AppFailure(FailureKind.missingCredentials);
  }
  return null;
}

/// Nivel de seguridad de la contraseña (solo es una guía visual): 0 débil, 1
/// aceptable, 2 fuerte. La regla obligatoria es la longitud mínima de 8.
int passwordStrength(String password) {
  if (password.length < passwordMinChars) return 0;
  var points = 0;
  if (password.length >= 12) points++;
  if (RegExp(r'\d').hasMatch(password)) points++;
  if (RegExp(r'[A-ZÁÉÍÓÚÑ]').hasMatch(password) &&
      RegExp(r'[a-záéíóúñ]').hasMatch(password)) {
    points++;
  }
  if (RegExp(r'[^A-Za-z0-9ÁÉÍÓÚÑáéíóúñ]').hasMatch(password)) points++;
  return points >= 3 ? 2 : 1;
}
