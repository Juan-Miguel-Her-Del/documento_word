// Raíz de la app según la sesión (tarea T127; spec 002; data-model.md de 002).
//
// - Comprobando la sesión → pantalla de presentación.
// - Sin sesión → bienvenida, ingreso y registro (AuthFlow).
// - Con sesión → el flujo de documentos de esa persona (SignedInScope).
//
// SignedInScope crea un DocumentFlowController propio para cada cuenta y lo libera al
// cerrar sesión. Así el borrador de una persona nunca aparece en la sesión de otra
// [SC-206].
//
// Spec 006 (tarea T505; research.md de 006, R2): la primera vez en el teléfono,
// SignedInScope muestra los consejos para una buena foto antes del inicio. El
// controlador de documentos se inicia igual, así el borrador se recupera en paralelo.

import 'dart:async';

import 'package:flutter/material.dart';

import '../../models/user_account.dart';
import '../../state/auth_controller.dart';
import '../../state/document_flow_controller.dart';
import '../settings_scope.dart';
import '../widgets/motion.dart';
import 'auth/auth_flow.dart';
import 'flow_screen.dart';
import 'splash_screen.dart';
import 'tips_screen.dart';

/// Crea el controlador de documentos de una cuenta. main.dart arma el real y las
/// pruebas uno con servicios falsos.
typedef DocumentControllerFactory =
    DocumentFlowController Function(
      UserAccount user,
      VoidCallback onSessionExpired,
    );

/// Decide qué se ve según la sesión: la presentación mientras se comprueba, la
/// bienvenida si no hay sesión o el flujo de documentos si la hay.
///
/// Recibe la sesión ([auth]) y cómo crear el controlador de documentos de cada
/// cuenta ([createDocumentController]).
class AppRoot extends StatelessWidget {
  const AppRoot({
    super.key,
    required this.auth,
    required this.createDocumentController,
  });

  final AuthController auth;
  final DocumentControllerFactory createDocumentController;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: auth,
      builder: (context, _) {
        final Widget child = switch (auth.status) {
          AuthStatus.checking => const SplashScreen(key: ValueKey('checking')),
          AuthStatus.signedOut => AuthFlow(
            key: const ValueKey('signedOut'),
            auth: auth,
          ),
          AuthStatus.signedIn => SignedInScope(
            key: ValueKey('user-${auth.user!.id}'),
            auth: auth,
            createDocumentController: createDocumentController,
          ),
        };
        return AnimatedSwitcher(
          duration: motionDuration(context, const Duration(milliseconds: 450)),
          child: child,
        );
      },
    );
  }
}

/// Zona con sesión: crea, inicia y libera el controlador de documentos de la cuenta.
class SignedInScope extends StatefulWidget {
  const SignedInScope({
    super.key,
    required this.auth,
    required this.createDocumentController,
  });

  final AuthController auth;
  final DocumentControllerFactory createDocumentController;

  @override
  State<SignedInScope> createState() => _SignedInScopeState();
}

class _SignedInScopeState extends State<SignedInScope> {
  late final DocumentFlowController _documents = widget
      .createDocumentController(
        widget.auth.user!,
        widget.auth.handleSessionExpired, // [CU-H2-E5]
      );

  @override
  void initState() {
    super.initState();
    unawaited(_documents.initialize());
  }

  @override
  void dispose() {
    _documents.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final settings = SettingsScope.of(context);
    // [PA-H1-E1] Consejos la primera vez; [PA-H1-E4] después, ya no [SC-601].
    final Widget child = settings.settings.tipsSeen
        ? FlowScreen(
            key: const ValueKey('flow'),
            controller: _documents,
            auth: widget.auth,
          )
        : PopScope(
            key: const ValueKey('tips'),
            // [PA-H1-E3] El botón atrás de Android también los salta (sin cerrar
            // la app).
            canPop: false,
            onPopInvokedWithResult: (didPop, _) {
              if (!didPop) unawaited(settings.markTipsSeen());
            },
            child: TipsScreen(onDone: settings.markTipsSeen),
          );
    return AnimatedSwitcher(
      duration: motionDuration(context, const Duration(milliseconds: 350)),
      child: child,
    );
  }
}
