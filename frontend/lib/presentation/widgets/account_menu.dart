// Menú de la cuenta: avatar con la inicial y opciones «Cerrar sesión» y «Eliminar
// cuenta» (tarea T130; spec 002, Historia 2).
//
// - [CU-H2-E2] Si hay texto sin exportar, cerrar sesión pide confirmación porque el
//   texto se descartará.
// - [CU-H2-E3] Eliminar la cuenta pide la contraseña; si es correcta se borran la
//   cuenta, sus sesiones y su borrador local.
// - Spec 005 (tarea T405): también abre «Ajustes» y «Acerca de» [AV-H1-E1].
// - Spec 006 (tareas T507 y T511): el avatar mide 48 dp y TalkBack lo lee «Cuenta»,
//   sin la inicial [PA-H2-E1] [PA-H3-E3]; el diálogo de eliminar la cuenta se desplaza
//   con la letra grande [PA-H3-E1].

import 'dart:async';

import 'package:flutter/material.dart';

import '../../models/app_failure.dart';
import '../../state/auth_controller.dart';
import '../../state/document_flow_controller.dart';
import '../../theme/aurora.dart';
import '../screens/about_screen.dart';
import '../screens/settings_screen.dart';
import '../strings.dart';
import 'confirm_dialog.dart';

enum _AccountAction { settings, about, signOut, deleteAccount }

/// Avatar con la inicial de la persona. Abre el menú de la cuenta: Ajustes, Acerca
/// de, Cerrar sesión y Eliminar cuenta.
class AccountButton extends StatelessWidget {
  const AccountButton({super.key, required this.auth, required this.documents});

  /// Sesión: el nombre, cerrar sesión y eliminar la cuenta.
  final AuthController auth;
  /// El documento en curso: para avisar si hay texto sin exportar antes de cerrar
  /// sesión.
  final DocumentFlowController documents;

  Future<void> _signOut(BuildContext context) async {
    if (documents.hasUnexportedChanges) {
      final confirmed = await showConfirmDialog(
        context,
        title: context.strings.signOutTitle,
        message: context.strings.signOutUnexportedMessage,
        confirmLabel: context.strings.signOut,
        destructive: true,
      );
      if (!confirmed) return; // cancelar conserva todo
    }
    await auth.signOut(beforeSignOut: documents.clearLocalData);
  }

  Future<void> _deleteAccount(BuildContext context) async {
    final messenger = ScaffoldMessenger.of(context);
    final strings = context.strings; // antes de esperar: el menú puede cerrarse
    final password = await showDeleteAccountDialog(context);
    if (password == null) return;
    final deleted = await auth.deleteAccount(
      password,
      // Spec 007: eliminar la cuenta también borra su historial [HD-H3-E4].
      beforeSignOut: () => documents.clearLocalData(deleteHistory: true),
    );
    if (!deleted) {
      // [CU-H2-E4] Contraseña incorrecta u otro problema: la cuenta se conserva.
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            strings.failureText(
              auth.failure ?? const AppFailure(FailureKind.unexpected),
            ),
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = auth.user;
    // Nodo propio para TalkBack: «Cuenta, botón», sin absorber el saludo ni el título
    // que tiene al lado [PA-H2-E1].
    return Semantics(
      container: true,
      child: PopupMenuButton<_AccountAction>(
        tooltip: context.strings.accountTooltip,
        enabled: !documents.isBusy && !auth.isBusy,
        position: PopupMenuPosition.under,
        onSelected: (action) => switch (action) {
          _AccountAction.settings => unawaited(
            Navigator.of(context).push(
              MaterialPageRoute<void>(builder: (_) => const SettingsScreen()),
            ),
          ),
          _AccountAction.about => unawaited(AboutScreen.open(context)),
          _AccountAction.signOut => unawaited(_signOut(context)),
          _AccountAction.deleteAccount => unawaited(_deleteAccount(context)),
        },
        itemBuilder: (context) => [
          if (user != null)
            PopupMenuItem<_AccountAction>(
              // Encabezado informativo: no se puede tocar, pero se lee con colores
              // normales (no en gris de «desactivado»).
              enabled: false,
              child: ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(
                  user.displayName,
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurface,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                subtitle: Text(
                  user.email,
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            ),
          const PopupMenuDivider(),
          PopupMenuItem(
            value: _AccountAction.settings,
            child: ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Icon(Icons.tune),
              title: Text(context.strings.settingsTitle),
            ),
          ),
          PopupMenuItem(
            value: _AccountAction.about,
            child: ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Icon(Icons.info_outline),
              title: Text(context.strings.aboutTitle),
            ),
          ),
          const PopupMenuDivider(),
          PopupMenuItem(
            value: _AccountAction.signOut,
            child: ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Icon(Icons.logout),
              title: Text(context.strings.signOut),
            ),
          ),
          PopupMenuItem(
            value: _AccountAction.deleteAccount,
            child: ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Icon(
                Icons.delete_forever_outlined,
                color: Theme.of(context).colorScheme.error,
              ),
              title: Text(context.strings.deleteAccount),
            ),
          ),
        ],
        child: _Avatar(initial: user?.initial ?? '?'),
      ),
    );
  }
}

/// Círculo azul corporativo con la inicial y un borde fino. Mide 48 dp, el mínimo
/// para tocar que recomienda Android [SC-603].
class _Avatar extends StatelessWidget {
  const _Avatar({required this.initial});

  final String initial;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 48,
      height: 48,
      padding: const EdgeInsets.all(2),
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        color: Aurora.surfaceBorder,
      ),
      child: CircleAvatar(
        backgroundColor: Aurora.blue,
        // TalkBack lee el nombre del botón («Cuenta»), no la letra suelta.
        child: ExcludeSemantics(
          child: Text(
            initial,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ),
    );
  }
}

/// Pide la contraseña para eliminar la cuenta. Devuelve null si se cancela.
Future<String?> showDeleteAccountDialog(BuildContext context) =>
    showDialog<String>(
      context: context,
      builder: (_) => const _DeleteAccountDialog(),
    );

class _DeleteAccountDialog extends StatefulWidget {
  const _DeleteAccountDialog();

  @override
  State<_DeleteAccountDialog> createState() => _DeleteAccountDialogState();
}

class _DeleteAccountDialogState extends State<_DeleteAccountDialog> {
  final _password = TextEditingController();

  @override
  void dispose() {
    _password.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return AlertDialog(
      // Con la letra grande, el mensaje y el campo se desplazan (research.md de
      // 006, R6).
      scrollable: true,
      icon: Icon(Icons.warning_amber_rounded, color: colors.error, size: 40),
      title: Text(context.strings.deleteAccountTitle),
      // Botones apilados centrados si no caben, con la acción principal arriba.
      actionsOverflowAlignment: OverflowBarAlignment.center,
      actionsOverflowDirection: VerticalDirection.up,
      actionsOverflowButtonSpacing: 8,
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(context.strings.deleteAccountMessage),
          const SizedBox(height: 16),
          TextField(
            controller: _password,
            obscureText: true,
            autofocus: true,
            decoration: InputDecoration(
              labelText: context.strings.passwordLabel,
              prefixIcon: Icon(Icons.lock_outline),
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(context.strings.cancel),
        ),
        ValueListenableBuilder<TextEditingValue>(
          valueListenable: _password,
          builder: (context, value, _) => FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: colors.error,
              foregroundColor: colors.onError,
            ),
            onPressed: value.text.isEmpty
                ? null
                : () => Navigator.of(context).pop(value.text),
            child: Text(context.strings.deleteAccountConfirm),
          ),
        ),
      ],
    );
  }
}
