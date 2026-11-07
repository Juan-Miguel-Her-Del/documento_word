// Pantalla de inicio (tareas T043 y T132; spec 001, módulo 1; spec 002, módulo 5).
//
// Sobre el fondo Aurora:
// - Saludo con el nombre de la persona y su menú de cuenta (avatar) [CU-H1-E6].
// - Tarjeta principal con el logo-escáner animado.
// - Tarjetas de acción: «Tomar fotografía» (Historia 2) y «Elegir imagen guardada»
//   (Historia 1), más «Escanear hoja» (spec 009, abajo).
// - Requisitos de la imagen y avisos (permiso de cámara denegado, imagen rechazada…).
// - Si se llegó desde «Procesar otra imagen», ofrece volver al texto actual, que se
//   conserva [H1-E13].
// - Spec 006: enlace a los consejos para una buena foto [PA-H1-E5].
// - Spec 007: acceso a «Mis documentos», con cuántos hay guardados [HD-H1-E4].
// - Spec 009: «Escanear hoja» es la primera opción [ED-H1-E1]; si el escáner no está
//   disponible, el aviso ofrece «Tomar fotografía» [ED-H2-E1].

import 'package:flutter/material.dart';

import '../../models/operation_status.dart';
import '../../state/auth_controller.dart';
import '../../state/document_flow_controller.dart';
import '../../theme/aurora.dart';
import '../strings.dart';
import '../widgets/account_menu.dart';
import '../widgets/action_tile.dart';
import '../widgets/aurora_scaffold.dart';
import '../widgets/scanner_logo.dart';
import '../widgets/status_banner.dart';
import '../widgets/surface_card.dart';
import 'history_screen.dart';
import 'tips_screen.dart';

/// Pantalla de inicio: escanear, tomar una foto o elegir una imagen, y acceso a Mis
/// documentos.
class StartScreen extends StatelessWidget {
  const StartScreen({super.key, required this.controller, required this.auth});

  /// El documento en curso: recibe la imagen elegida y da los avisos.
  final DocumentFlowController controller;
  /// Sesión: el nombre del saludo y el menú de la cuenta.
  final AuthController auth;

  @override
  Widget build(BuildContext context) {
    final busy =
        controller.isBusy; // [SC-008] acciones inactivas mientras tanto
    final status = controller.status;
    final textTheme = Theme.of(context).textTheme;
    final firstName = auth.user?.firstName ?? '';

    return AuroraScaffold(
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
        children: [
          // Encabezado: saludo y avatar con el menú de la cuenta.
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      context.strings.greeting(firstName),
                      style: textTheme.titleMedium?.copyWith(
                        color: Aurora.textSecondary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    // [PA-H2-E5] Título como encabezado para TalkBack.
                    Semantics(
                      // Nodo propio: no se mezcla con los botones vecinos.
                      container: true,
                      header: true,
                      child: Text(
                        context.strings.startHeadline,
                        style: textTheme.headlineSmall?.copyWith(
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              AccountButton(auth: auth, documents: controller),
            ],
          ),
          const SizedBox(height: 20),
          SurfaceCard(
            child: Column(
              children: [
                const ScannerLogo(size: 96),
                const SizedBox(height: 12),
                Text(
                  context.strings.startTitle,
                  textAlign: TextAlign.center,
                  style: textTheme.titleLarge?.copyWith(color: Colors.white),
                ),
                const SizedBox(height: 6),
                Text(
                  context.strings.startDescription,
                  textAlign: TextAlign.center,
                  style: textTheme.bodyMedium?.copyWith(
                    color: Aurora.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          if (status != null) ...[
            const SizedBox(height: 16),
            StatusBanner(
              status: status,
              onAurora: true,
              actionLabel: status.action == StatusAction.takePhoto
                  ? context.strings.takePhoto
                  : null,
              onAction: status.action == StatusAction.takePhoto && !busy
                  ? controller.takePhoto
                  : null,
            ),
          ],
          const SizedBox(height: 16),
          // [ED-H1-E1] El escáner endereza la hoja: la opción recomendada.
          ActionTile(
            icon: Icons.document_scanner_outlined,
            title: context.strings.scanDocument,
            subtitle: context.strings.scanDocumentSubtitle,
            onTap: busy ? null : controller.scanDocument,
          ),
          const SizedBox(height: 12),
          ActionTile(
            icon: Icons.photo_camera_outlined,
            title: context.strings.takePhoto,
            subtitle: context.strings.takePhotoSubtitle,
            onTap: busy ? null : controller.takePhoto,
          ),
          const SizedBox(height: 12),
          ActionTile(
            icon: Icons.photo_library_outlined,
            title: context.strings.pickFromGallery,
            subtitle: context.strings.pickFromGallerySubtitle,
            onTap: busy ? null : controller.pickFromGallery,
          ),
          const SizedBox(height: 12),
          Text(
            context.strings.imageRequirements,
            textAlign: TextAlign.center,
            style: textTheme.bodySmall?.copyWith(color: Aurora.textMuted),
          ),
          Center(
            child: TextButton.icon(
              onPressed: busy ? null : () => TipsScreen.open(context),
              icon: const Icon(Icons.lightbulb_outline),
              label: Text(context.strings.tipsLink),
            ),
          ),
          const SizedBox(height: 8),
          // [HD-H1-E4] El subtítulo cambia cuando se guarda un documento.
          ListenableBuilder(
            listenable: controller.history,
            builder: (context, _) => ActionTile(
              icon: Icons.history,
              title: context.strings.historyTitle,
              subtitle: context.strings.historyCount(
                controller.history.entries.length,
              ),
              onTap: busy
                  ? null
                  : () => HistoryScreen.open(context, controller),
            ),
          ),
          if (controller.hasDocument) ...[
            const SizedBox(height: 20),
            SurfaceCard(
              child: Column(
                children: [
                  Row(
                    children: [
                      const Icon(Icons.edit_note, color: Aurora.blueLight),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          context.strings.documentInProgress,
                          style: textTheme.titleMedium?.copyWith(
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    context.strings.keepCurrentTextNotice,
                    style: textTheme.bodySmall?.copyWith(
                      color: Aurora.textSecondary,
                    ),
                  ),
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: busy ? null : controller.returnToDocument,
                      child: Text(context.strings.backToCurrentText),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
