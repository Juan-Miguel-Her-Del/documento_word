// Da acceso a los ajustes desde cualquier pantalla (tarea T403; spec 005).
//
// Está por encima de MaterialApp, así también lo ven las pantallas que se abren con
// Navigator (Ajustes, Acerca de). Al cambiar un ajuste, se reconstruye lo que lo usa.

import 'package:flutter/widgets.dart';

import '../state/settings_controller.dart';

/// Pone los ajustes ([SettingsController]) al alcance de todas las pantallas. Al
/// cambiar un ajuste, se vuelve a dibujar lo que lo usa.
class SettingsScope extends InheritedNotifier<SettingsController> {
  const SettingsScope({
    super.key,
    required SettingsController settings,
    required super.child,
  }) : super(notifier: settings);

  /// El controlador de ajustes; quien lo pide se reconstruye cuando cambia.
  static SettingsController of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<SettingsScope>()!.notifier!;
}
