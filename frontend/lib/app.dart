// Widget raíz de la app (tareas T044 y T127).
//
// - Aplica los temas centralizados: claro u oscuro según el sistema [CU-H3-E4]
//   (theme/app_theme.dart), con la tipografía Poppins.
// - Configura el español también para los textos propios de Flutter (por ejemplo,
//   «Copiar» y «Pegar» en el editor).
// - Inicia la sesión (AuthController) al abrir y la libera al cerrar.
// - AppRoot decide qué se muestra: bienvenida, ingreso y registro, o la app.
// - Spec 005 (tarea T403): el tema sigue el ajuste elegido (automático, claro u oscuro)
//   y SettingsScope da acceso a los ajustes en todas las pantallas.
// - Spec 008 (tarea T704): el idioma sigue el ajuste (español, inglés o el del
//   teléfono). Los textos de la app llegan con AppStrings.delegate, junto con los de
//   Flutter; al cambiar el idioma, todo se vuelve a dibujar sin reiniciar.
// - Spec 011 (tarea T1005): AppLockGate tapa toda la app con la pantalla de bloqueo
//   cuando corresponde, y AppLockScope da acceso al bloqueo desde Ajustes.

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'models/app_settings.dart';
import 'presentation/app_lock_scope.dart';
import 'presentation/screens/app_root.dart';
import 'presentation/screens/lock_screen.dart';
import 'presentation/settings_scope.dart';
import 'presentation/strings.dart';
import 'state/app_lock_controller.dart';
import 'state/auth_controller.dart';
import 'state/settings_controller.dart';
import 'theme/app_theme.dart';

class HandTextApp extends StatefulWidget {
  const HandTextApp({
    super.key,
    required this.auth,
    required this.settings,
    required this.lock,
    required this.createDocumentController,
  });

  final AuthController auth;
  final SettingsController settings;

  /// Spec 011: bloqueo con huella, rostro o el bloqueo de pantalla del teléfono.
  final AppLockController lock;
  final DocumentControllerFactory createDocumentController;

  @override
  State<HandTextApp> createState() => _HandTextAppState();
}

class _HandTextAppState extends State<HandTextApp> {
  @override
  void initState() {
    super.initState();
    unawaited(widget.auth.initialize()); // [CU-H1-E9] ¿hay una sesión guardada?
    widget.lock.start(); // spec 011: observa la app para saber cuándo bloquear
  }

  @override
  void dispose() {
    widget.lock.dispose();
    widget.auth.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SettingsScope(
      settings: widget.settings,
      child: AppLockScope(
        lock: widget.lock,
        child: ListenableBuilder(
          listenable: widget.settings,
          builder: (context, _) => MaterialApp(
            onGenerateTitle: (context) => context.strings.appName,
            debugShowCheckedModeBanner: false,
            theme: AppTheme.light(),
            darkTheme: AppTheme.dark(),
            // [AV-H1-E2] [AV-H1-E3] Tema elegido en Ajustes.
            themeMode: switch (widget.settings.settings.theme) {
              ThemePreference.system => ThemeMode.system,
              ThemePreference.light => ThemeMode.light,
              ThemePreference.dark => ThemeMode.dark,
            },
            // [IE-H1-E1] [IE-H1-E2] Idioma elegido; con «Automático», el del teléfono.
            locale: switch (widget.settings.settings.language) {
              AppLanguage.spanish => const Locale('es'),
              AppLanguage.english => const Locale('en'),
              AppLanguage.system => null,
            },
            supportedLocales: AppStrings.supportedLocales,
            localizationsDelegates: const [
              AppStrings.delegate,
              ...GlobalMaterialLocalizations.delegates,
            ],
            // [IE-H1-E3] Inglés si el teléfono está en inglés; español en cualquier
            // otro caso (research.md de 008, R5).
            localeResolutionCallback: (locale, _) =>
                locale?.languageCode == 'en'
                ? const Locale('en')
                : const Locale('es'),
            // [BL-H2-E1] La pantalla de bloqueo tapa todo, también Ajustes y los
            // diálogos (research.md de 011, R4).
            builder: (context, child) =>
                AppLockGate(lock: widget.lock, child: child!),
            home: AppRoot(
              auth: widget.auth,
              createDocumentController: widget.createDocumentController,
            ),
          ),
        ),
      ),
    );
  }
}
