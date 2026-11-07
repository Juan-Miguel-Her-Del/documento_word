// Pantalla de presentación (tarea T126): se ve un instante al abrir la app, mientras se
// comprueba si hay una sesión guardada [CU-H1-E9].

import 'package:flutter/material.dart';

import '../widgets/aurora_scaffold.dart';
import '../widgets/brand_title.dart';
import '../widgets/scanner_logo.dart';

/// Presentación con el logo mientras se comprueba si hay una sesión guardada.
class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return AuroraScaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const ScannerLogo(size: 120),
            const SizedBox(height: 20),
            BrandTitle(style: Theme.of(context).textTheme.headlineMedium),
          ],
        ),
      ),
    );
  }
}
