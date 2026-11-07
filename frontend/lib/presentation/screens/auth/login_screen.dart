// Pantalla de ingreso (tarea T126; spec 002, CU-H1-E6 a CU-H1-E8).
//
// Correo y contraseña en una tarjeta. Antes de enviar se revisa que ambos
// campos estén llenos; los errores del servidor (datos incorrectos o cuenta bloqueada)
// se muestran en el aviso rojo, con el mismo mensaje para correo y contraseña [SC-203].

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

/// Pantalla de ingreso con correo y contraseña.
class LoginScreen extends StatefulWidget {
  const LoginScreen({
    super.key,
    required this.auth,
    required this.onBack,
    required this.onCreateAccount,
  });

  /// Sesión: envía el ingreso a la API.
  final AuthController auth;
  /// Vuelve a la bienvenida.
  final VoidCallback onBack;
  /// Abre el registro, para quien todavía no tiene cuenta.
  final VoidCallback onCreateAccount;

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _email = TextEditingController();
  final _password = TextEditingController();
  AppFailure? _formFailure;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    final failure = validateLoginForm(
      email: _email.text,
      password: _password.text,
    );
    setState(() => _formFailure = failure);
    if (failure != null) return;
    await widget.auth.signIn(email: _email.text, password: _password.text);
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return ListenableBuilder(
      listenable: widget.auth,
      builder: (context, _) {
        final failure = _formFailure ?? widget.auth.failure;
        final notice = widget.auth.notice;
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
                  context.strings.loginTitle,
                  style: textTheme.headlineMedium?.copyWith(
                    color: Colors.white,
                  ),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                context.strings.loginSubtitle,
                style: textTheme.bodyLarge?.copyWith(
                  color: Aurora.textSecondary,
                ),
              ),
              const SizedBox(height: 24),
              if (notice == StatusEvent.sessionExpired) ...[
                const StatusBanner(
                  status: OperationStatus.info(StatusEvent.sessionExpired),
                  onAurora: true,
                ),
                const SizedBox(height: 16),
              ],
              SurfaceCard(
                child: AutofillGroup(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
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
                        autofillHints: const [AutofillHints.password],
                        textInputAction: TextInputAction.done,
                        onSubmitted: (_) => _submit(),
                      ),
                      if (failure != null) ...[
                        const SizedBox(height: 16),
                        StatusBanner(
                          status: OperationStatus.failure(failure),
                          onAurora: true,
                        ),
                      ],
                      const SizedBox(height: 20),
                      PrimaryButton(
                        label: context.strings.signIn,
                        icon: Icons.login,
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
                    context.strings.noAccountQuestion,
                    style: textTheme.bodyMedium?.copyWith(
                      color: Aurora.textSecondary,
                    ),
                  ),
                  TextButton(
                    onPressed: widget.onCreateAccount,
                    child: Text(context.strings.createAccountLink),
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
