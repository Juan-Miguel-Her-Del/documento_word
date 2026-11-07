// Pantalla «Acerca de» (tarea T407; spec 005, Historia 2).
//
// Logo, nombre y versión [AV-H2-E2], y accesos a Privacidad [AV-H2-E3] y Licencias
// [AV-H2-E4]. Se puede abrir sin sesión, desde la bienvenida [AV-H2-E1].

import 'package:flutter/material.dart';

import '../../config/app_config.dart';
import '../../theme/aurora.dart';
import '../strings.dart';
import '../widgets/aurora_header.dart';
import '../widgets/aurora_scaffold.dart';
import '../widgets/brand_title.dart';
import '../widgets/scanner_logo.dart';
import '../widgets/surface_card.dart';
import 'privacy_screen.dart';

/// Pantalla «Acerca de»: logo, nombre y versión de la app, con accesos a Privacidad
/// y a las licencias de las bibliotecas que usa.
class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  /// Abre «Acerca de» encima de la pantalla actual.
  static Future<void> open(BuildContext context) => Navigator.of(
    context,
  ).push(MaterialPageRoute<void>(builder: (_) => const AboutScreen()));

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return AuroraScaffold(
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AuroraHeader(title: context.strings.aboutTitle),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
              children: [
                const Center(child: ScannerLogo(size: 96)),
                const SizedBox(height: 16),
                BrandTitle(style: textTheme.headlineMedium),
                const SizedBox(height: 4),
                Text(
                  context.strings.version(
                    AppConfig.appVersion,
                    AppConfig.appBuild,
                  ),
                  textAlign: TextAlign.center,
                  style: textTheme.bodyMedium?.copyWith(
                    color: Aurora.textSecondary,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  context.strings.aboutDescription,
                  textAlign: TextAlign.center,
                  style: textTheme.bodyLarge?.copyWith(
                    color: Aurora.textPrimary,
                  ),
                ),
                const SizedBox(height: 24),
                SurfaceCard(
                  padding: EdgeInsets.zero,
                  child: Column(
                    children: [
                      _Link(
                        icon: Icons.privacy_tip_outlined,
                        title: context.strings.privacyTitle,
                        subtitle: context.strings.aboutPrivacyHint,
                        onTap: () => Navigator.of(context).push(
                          MaterialPageRoute<void>(
                            builder: (_) => const PrivacyScreen(),
                          ),
                        ),
                      ),
                      const Divider(height: 1, color: Aurora.surfaceBorder),
                      _Link(
                        icon: Icons.description_outlined,
                        title: context.strings.licensesTitle,
                        subtitle: context.strings.aboutLicensesHint,
                        // [SC-503] Página de licencias de Flutter (incluye Poppins).
                        onTap: () => showLicensePage(
                          context: context,
                          applicationName: context.strings.appName,
                          applicationVersion: context.strings.version(
                            AppConfig.appVersion,
                            AppConfig.appBuild,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Fila de la tarjeta: ícono en insignia, título, descripción y flecha.
class _Link extends StatelessWidget {
  const _Link({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: Aurora.iconBadge,
          borderRadius: BorderRadius.circular(Aurora.radiusSmall),
        ),
        child: Icon(icon, color: Aurora.blueLight, size: 20),
      ),
      title: Text(title, style: const TextStyle(color: Aurora.textPrimary)),
      subtitle: Text(
        subtitle,
        style: const TextStyle(color: Aurora.textSecondary),
      ),
      trailing: const Icon(Icons.chevron_right, color: Aurora.textMuted),
    );
  }
}
