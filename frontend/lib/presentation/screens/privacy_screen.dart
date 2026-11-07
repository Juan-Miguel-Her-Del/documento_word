// Pantalla de Privacidad (tarea T407; spec 005, AV-H2-E3; research.md de 005, R6).
//
// Resume, en lenguaje simple, las reglas de privacidad de 001 a 011: qué datos usa la
// app, dónde quedan y cuándo se borran. Los textos están en strings_es.dart y
// strings_en.dart (privacySections).

import 'package:flutter/material.dart';

import '../../theme/aurora.dart';
import '../strings.dart';
import '../widgets/aurora_header.dart';
import '../widgets/aurora_scaffold.dart';
import '../widgets/surface_card.dart';

/// Pantalla de Privacidad: explica en lenguaje simple qué datos usa la app, dónde
/// quedan y cuándo se borran.
class PrivacyScreen extends StatelessWidget {
  const PrivacyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return AuroraScaffold(
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AuroraHeader(title: context.strings.privacyTitle),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
              children: [
                for (final (title, body)
                    in context.strings.privacySections) ...[
                  SurfaceCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: textTheme.titleMedium?.copyWith(
                            color: Aurora.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          body,
                          style: textTheme.bodyMedium?.copyWith(
                            color: Aurora.textSecondary,
                            height: 1.45,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
