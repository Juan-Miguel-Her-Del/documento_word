// Pantalla de bloqueo (tarea T1005; spec 011, Historia 2; research.md de 011, R4).
//
// AppLockGate envuelve toda la app (encima del Navigator, así también tapa Ajustes, Mis
// documentos y los diálogos). Mientras está bloqueada:
// - la app queda oculta pero viva (Offstage): al desbloquear, todo sigue donde estaba
//   [BL-H2-E2] [SC-1103];
// - se ve LockScreen, que pide la verificación sola una vez y luego con «Desbloquear»
//   [BL-H2-E3].

import 'package:flutter/material.dart';

import '../../state/app_lock_controller.dart';
import '../../theme/aurora.dart';
import '../strings.dart';
import '../widgets/aurora_scaffold.dart';
import '../widgets/brand_title.dart';
import '../widgets/primary_button.dart';
import '../widgets/scanner_logo.dart';

/// Envuelve toda la app: si está bloqueada, la oculta y pone [LockScreen] encima.
///
/// Va en `MaterialApp.builder` (app.dart), por encima de todas las pantallas y
/// diálogos (research.md de 011, R4). [lock] dice si está bloqueada.
class AppLockGate extends StatelessWidget {
  const AppLockGate({super.key, required this.lock, required this.child});

  final AppLockController lock;
  /// La app completa, tal como la arma MaterialApp.
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: lock,
      builder: (context, _) {
        final locked = lock.isLocked;
        return Stack(
          children: [
            // [BL-H2-E1] Bloqueada, no se ve ni se lee ningún documento.
            Offstage(offstage: locked, child: child),
            if (locked) LockScreen(lock: lock),
          ],
        );
      },
    );
  }
}

/// Pantalla de bloqueo: logo y «Desbloquear». Al aparecer pide la verificación una
/// vez sola; si se cancela, el botón la vuelve a pedir.
class LockScreen extends StatefulWidget {
  const LockScreen({super.key, required this.lock});

  final AppLockController lock;

  @override
  State<LockScreen> createState() => _LockScreenState();
}

class _LockScreenState extends State<LockScreen> {
  @override
  void initState() {
    super.initState();
    // Pide la huella apenas aparece, como las apps de banco.
    WidgetsBinding.instance.addPostFrameCallback((_) => _unlock());
  }

  Future<void> _unlock() async {
    if (!mounted) return;
    await widget.lock.unlock(context.strings.unlockReason);
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return AuroraScaffold(
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const ScannerLogo(size: 96),
              const SizedBox(height: 20),
              BrandTitle(style: textTheme.headlineMedium),
              const SizedBox(height: 24),
              Semantics(
                container: true,
                header: true,
                child: Text(
                  context.strings.lockedTitle,
                  textAlign: TextAlign.center,
                  style: textTheme.titleLarge?.copyWith(color: Colors.white),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                context.strings.lockedMessage,
                textAlign: TextAlign.center,
                style: textTheme.bodyMedium?.copyWith(
                  color: Aurora.textSecondary,
                ),
              ),
              const SizedBox(height: 32),
              PrimaryButton(
                label: context.strings.unlock,
                icon: Icons.fingerprint,
                onPressed: _unlock,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
