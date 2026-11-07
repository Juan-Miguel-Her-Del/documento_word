// Pruebas de las reglas de los formularios de cuenta (tarea T119; spec 002, CU-H1-E4).
// Son las mismas reglas que aplica el backend (backend/app/services/accounts/rules.py).

import 'package:flutter_test/flutter_test.dart';
import 'package:handtext_ai/models/app_failure.dart';
import 'package:handtext_ai/services/account_rules.dart';

FailureKind? _registration({
  String name = 'Ana',
  String email = 'ana@correo.com',
  String password = 'clave-segura-1',
  String? confirmation,
  bool accepts = true,
}) => validateRegistrationForm(
  displayName: name,
  email: email,
  password: password,
  confirmation: confirmation ?? password,
  acceptsDataPolicy: accepts,
)?.kind;

void main() {
  test('un registro correcto no tiene problemas', () {
    expect(_registration(), isNull);
  });

  test('cada regla tiene su motivo', () {
    expect(_registration(name: '   '), FailureKind.invalidDisplayName);
    expect(_registration(name: 'x' * 61), FailureKind.invalidDisplayName);
    expect(_registration(email: 'sin-arroba'), FailureKind.invalidEmail);
    expect(_registration(email: 'ana@correo'), FailureKind.invalidEmail);
    expect(_registration(password: '1234567'), FailureKind.weakPassword);
    expect(_registration(password: ' ' * 9), FailureKind.weakPassword);
    expect(_registration(confirmation: 'otra'), FailureKind.passwordMismatch);
    expect(_registration(accepts: false), FailureKind.dataPolicyNotAccepted);
  });

  test('el correo se acepta sin importar mayúsculas ni espacios', () {
    expect(isValidEmail('  Ana@Correo.COM '), isTrue);
  });

  test('el ingreso exige correo y contraseña', () {
    expect(
      validateLoginForm(email: '', password: 'x')?.kind,
      FailureKind.missingCredentials,
    );
    expect(validateLoginForm(email: 'a@b.co', password: 'x'), isNull);
  });

  test('la guía de seguridad de la contraseña', () {
    expect(passwordStrength('corta'), 0);
    expect(passwordStrength('solominusculas'), 1);
    expect(passwordStrength('Clave-Segura-2026'), 2);
  });
}
