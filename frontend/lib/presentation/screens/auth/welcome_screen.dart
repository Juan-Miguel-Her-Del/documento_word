// Pantalla de bienvenida (tareas T126 y T143; spec 002, CU-H1-E1).
//
// Logo animado, título de marca, los tres pasos de la app en una tarjeta y los botones
// «Crear cuenta» y «Ya tengo cuenta». Si hay un aviso (sesión cerrada, vencida o cuenta
// eliminada), lo muestra arriba de los botones.
// Spec 005 (tarea T408): «Privacidad y acerca de» se puede leer antes de crear la
// cuenta [AV-H2-E1].
// Spec 008 (tarea T706): botón de idioma arriba, para elegirlo antes de crear la cuenta
// [IE-H1-E2].

import 'package:flutter/material.dart';

import '../../../models/operation_status.dart';
import '../../../state/auth_controller.dart';
import '../../../theme/aurora.dart';
import '../../strings.dart';
import '../../widgets/aurora_scaffold.dart';
import '../../widgets/brand_title.dart';
import '../../widgets/language_sheet.dart';
import '../../widgets/primary_button.dart';
import '../../widgets/scanner_logo.dart';
import '../../widgets/status_banner.dart';
import '../../widgets/surface_card.dart';
import '../about_screen.dart';

/// Primera pantalla sin sesión: presenta la app y ofrece crear una cuenta o
/// ingresar.
class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({
    super.key,
    required this.auth,
    required this.onCreateAccount,
    required this.onSignIn,
  });

  /// Sesión: de ella sale el aviso que se muestra (sesión cerrada, vencida o cuenta
  /// eliminada).
  final AuthController auth;
  /// Abre el registro.
  final VoidCallback onCreateAccount;
  /// Abre el ingreso.
  final VoidCallback onSignIn;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final notice = auth.notice;
    return AuroraScaffold(
      body: ListView(
        padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
        children: [
          const Align(
            alignment: Alignment.centerRight,
            child: LanguageButton(),
          ),
          const Center(child: ScannerLogo(size: 128)),
          const SizedBox(height: 20),
          BrandTitle(style: textTheme.headlineLarge),
          const SizedBox(height: 8),
          Text(
            context.strings.welcomeTagline,
            textAlign: TextAlign.center,
            style: textTheme.titleMedium?.copyWith(
              color: Aurora.textSecondary,
              fontWeight: FontWeight.w400,
            ),
          ),
          const SizedBox(height: 32),
          SurfaceCard(
            child: Column(
              children: [
                _Step(
                  icon: Icons.photo_camera_outlined,
                  text: context.strings.welcomeStep1,
                ),
                SizedBox(height: 16),
                _Step(
                  icon: Icons.auto_awesome,
                  text: context.strings.welcomeStep2,
                ),
                SizedBox(height: 16),
                _Step(
                  icon: Icons.description_outlined,
                  text: context.strings.welcomeStep3,
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),
          if (notice != null) ...[
            StatusBanner(
              status: notice == StatusEvent.accountDeleted
                  ? OperationStatus.success(notice)
                  : OperationStatus.info(notice),
              onAurora: true,
            ),
            const SizedBox(height: 16),
          ],
          PrimaryButton(
            label: context.strings.createAccount,
            icon: Icons.person_add_alt_1_outlined,
            onPressed: onCreateAccount,
          ),
          const SizedBox(height: 12),
          OutlinedButton(
            onPressed: onSignIn,
            child: Text(context.strings.haveAccount),
          ),
          const SizedBox(height: 24),
          Text(
            context.strings.welcomePrivacyNote,
            textAlign: TextAlign.center,
            style: textTheme.bodySmall?.copyWith(color: Aurora.textMuted),
          ),
          Center(
            child: TextButton(
              onPressed: () => AboutScreen.open(context),
              child: Text(context.strings.privacyAndAbout),
            ),
          ),
        ],
      ),
    );
  }
}

/// Un paso de «cómo funciona»: ícono en una insignia azul y su texto.
class _Step extends StatelessWidget {
  const _Step({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: Aurora.iconBadge,
            borderRadius: BorderRadius.circular(Aurora.radiusSmall),
          ),
          child: Icon(icon, color: Aurora.blueLight, size: 20),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Text(
            text,
            style: Theme.of(
              context,
            ).textTheme.bodyLarge?.copyWith(color: Aurora.textPrimary),
          ),
        ),
      ],
    );
  }
}
