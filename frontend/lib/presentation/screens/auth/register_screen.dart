// Pantalla de registro (tarea T126; spec 002, CU-H1-E2 a CU-H1-E5).
//
// Nombre, correo, contraseña (con barra de seguridad), confirmación y la autorización
// del tratamiento de datos. Antes de enviar se aplican las mismas reglas que el
// servidor (account_rules.dart); el servidor las vuelve a aplicar.

import 'package:flutter/material.dart';

import '../../../models/app_failure.dart';
import '../../../models/operation_status.dart';
import '../../../services/account_rules.dart';
import '../../../state/auth_controller.dart';
import '../../../theme/aurora.dart';
import '../../strings.dart';
import '../../widgets/aurora_scaffold.dart';
import '../../widgets/password_field.dart';
import '../../widgets/primary_button.dart';
import '../../widgets/status_banner.dart';
import '../../widgets/surface_card.dart';

/// Pantalla para crear una cuenta: nombre, correo, contraseña, confirmación y
/// autorización del tratamiento de los datos.
class RegisterScreen extends StatefulWidget {
  const RegisterScreen({
    super.key,
    required this.auth,
    required this.onBack,
    required this.onSignIn,
  });

  /// Sesión: envía el registro a la API.
  final AuthController auth;
  /// Vuelve a la bienvenida.
  final VoidCallback onBack;
  /// Abre el ingreso, para quien ya tiene cuenta.
  final VoidCallback onSignIn;

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _confirmation = TextEditingController();
  bool _acceptsDataPolicy = false;
  AppFailure? _formFailure;

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _password.dispose();
    _confirmation.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    final failure = validateRegistrationForm(
      displayName: _name.text,
      email: _email.text,
      password: _password.text,
      confirmation: _confirmation.text,
      acceptsDataPolicy: _acceptsDataPolicy,
    );
    setState(() => _formFailure = failure);
    if (failure != null) return; // [CU-H1-E4] [CU-H1-E5] no se envía nada
    await widget.auth.register(
      displayName: _name.text,
      email: _email.text,
      password: _password.text,
      acceptsDataPolicy: _acceptsDataPolicy,
    );
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return ListenableBuilder(
      listenable: widget.auth,
      builder: (context, _) {
        final failure = _formFailure ?? widget.auth.failure;
        return AuroraScaffold(
          body: ListView(
            padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
            children: [
              Align(
                alignment: Alignment.centerLeft,
                child: IconButton(
                  tooltip: context.strings.back,
                  icon: const Icon(Icons.arrow_back, color: Colors.white),
                  onPressed: widget.onBack,
                ),
              ),
              const SizedBox(height: 12),
              // [PA-H2-E5] Título como encabezado para TalkBack.
              Semantics(
                // Nodo propio: no se mezcla con los botones vecinos.
                container: true,
                header: true,
                child: Text(
                  context.strings.registerTitle,
                  style: textTheme.headlineMedium?.copyWith(
                    color: Colors.white,
                  ),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                context.strings.registerSubtitle,
                style: textTheme.bodyLarge?.copyWith(
                  color: Aurora.textSecondary,
                ),
              ),
              const SizedBox(height: 24),
              SurfaceCard(
                child: AutofillGroup(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      TextField(
                        controller: _name,
                        textCapitalization: TextCapitalization.words,
                        autofillHints: const [AutofillHints.name],
                        textInputAction: TextInputAction.next,
                        decoration: InputDecoration(
                          labelText: context.strings.nameLabel,
                          prefixIcon: Icon(Icons.person_outline),
                        ),
                      ),
                      const SizedBox(height: 14),
                      TextField(
                        controller: _email,
                        keyboardType: TextInputType.emailAddress,
                        autocorrect: false,
                        autofillHints: const [AutofillHints.email],
                        textInputAction: TextInputAction.next,
                        decoration: InputDecoration(
                          labelText: context.strings.emailLabel,
                          prefixIcon: Icon(Icons.alternate_email),
                        ),
                      ),
                      const SizedBox(height: 14),
                      PasswordField(
                        controller: _password,
                        label: context.strings.passwordLabel,
                        showStrength: true,
                        autofillHints: const [AutofillHints.newPassword],
                        textInputAction: TextInputAction.next,
                      ),
                      const SizedBox(height: 14),
                      PasswordField(
                        controller: _confirmation,
                        label: context.strings.confirmPasswordLabel,
                        textInputAction: TextInputAction.done,
                      ),
                      const SizedBox(height: 8),
                      // [CU-H1-E5] Autorización expresa del tratamiento de datos.
                      CheckboxListTile(
                        value: _acceptsDataPolicy,
                        onChanged: (value) =>
                            setState(() => _acceptsDataPolicy = value ?? false),
                        controlAffinity: ListTileControlAffinity.leading,
                        contentPadding: EdgeInsets.zero,
                        title: Text(
                          context.strings.dataPolicyConsent,
                          style: textTheme.bodySmall?.copyWith(
                            color: Aurora.textSecondary,
                          ),
                        ),
                      ),
                      if (failure != null) ...[
                        const SizedBox(height: 8),
                        StatusBanner(
                          status: OperationStatus.failure(failure),
                          onAurora: true,
                        ),
                      ],
                      const SizedBox(height: 20),
                      PrimaryButton(
                        label: context.strings.createAccount,
                        icon: Icons.person_add_alt_1_outlined,
                        isLoading: widget.auth.isBusy,
                        onPressed: _submit,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              // Wrap pasa el enlace a otra línea si no cabe (pantallas angostas o letra
              // grande de accesibilidad).
              Wrap(
                alignment: WrapAlignment.center,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  Text(
                    context.strings.haveAccountQuestion,
                    style: textTheme.bodyMedium?.copyWith(
                      color: Aurora.textSecondary,
                    ),
                  ),
                  TextButton(
                    onPressed: widget.onSignIn,
                    child: Text(context.strings.signIn),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}
