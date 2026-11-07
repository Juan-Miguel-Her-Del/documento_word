// Da acceso al bloqueo con huella desde cualquier pantalla (tarea T1003; spec 011).
//
// Igual que SettingsScope: está por encima de MaterialApp, así también lo ve Ajustes,
// que se abre con Navigator.

import 'package:flutter/widgets.dart';

import '../state/app_lock_controller.dart';

/// Pone el bloqueo con huella ([AppLockController]) al alcance de todas las
/// pantallas. Ajustes lo usa para el interruptor «Bloquear con huella o rostro».
class AppLockScope extends InheritedNotifier<AppLockController> {
  const AppLockScope({
    super.key,
    required AppLockController lock,
    required super.child,
  }) : super(notifier: lock);

  /// El controlador del bloqueo; quien lo pide se reconstruye cuando cambia.
  static AppLockController of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<AppLockScope>()!.notifier!;
}
