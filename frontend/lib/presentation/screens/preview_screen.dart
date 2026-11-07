// Vista previa de la imagen (tareas T043 y T132; spec 001, módulos 1 y 2).
//
// - Muestra la imagen antes del reconocimiento y permite aceptarla, reemplazarla o
//   cancelar la selección (spec 001, módulo 1; H1-E2; H2-E3).
// - «Aceptar y reconocer texto» pide primero la autorización de envío [H1-E3].
// - Mientras se reconoce, una línea de escaneo recorre la imagen [CU-H3-E2], el botón
//   muestra el progreso y las acciones quedan inactivas [H1-E5].
// - Si no hubo texto o hubo un fallo, muestra el aviso con «Reintentar», «Elegir otra
//   imagen» o «Repetir captura» [H1-E7] [H1-E8] [H2-E5].
// - Spec 003 (tarea T213): «Recortar o girar» abre el editor de recorte y, si ya se
//   recortó, «Usar la imagen original» la recupera [EX-H2-E1] [EX-H2-E5].
// - Spec 004 (tarea T309):
//   - una tira de miniaturas muestra las páginas y permite agregar más [VP-H1-E1]
//     [VP-H1-E2];
//   - con dos páginas o más, la barra superior ofrece moverla antes o después y
//     quitarla [VP-H2-E2] [VP-H2-E3];
//   - recortar y reemplazar actúan sobre la página que se ve en grande [VP-H2-E4].

import 'package:flutter/material.dart';

import '../../models/operation_status.dart';
import '../../models/picked_image.dart';
import '../../state/document_flow_controller.dart';
import '../../theme/aurora.dart';
import '../strings.dart';
import '../widgets/aurora_scaffold.dart';
import '../widgets/consent_dialog.dart';
import '../widgets/page_strip.dart';
import '../widgets/primary_button.dart';
import '../widgets/scan_overlay.dart';
import '../widgets/status_banner.dart';
import '../widgets/surface_card.dart';

/// Vista previa antes de reconocer: aceptar, reemplazar, recortar, agregar, ordenar
/// o quitar páginas.
class PreviewScreen extends StatelessWidget {
  const PreviewScreen({super.key, required this.controller});

  /// El documento en curso: sus páginas y las acciones sobre ellas.
  final DocumentFlowController controller;

  /// Pide la autorización y, con la respuesta, inicia (o no) el reconocimiento.
  /// [VP-H1-E3] El diálogo dice cuántas imágenes se enviarán; si todas ya se
  /// reconocieron, no se envía nada y no hace falta preguntar.
  Future<void> _acceptAndRecognize(BuildContext context) async {
    final toSend = controller.pagesToSend;
    final granted =
        toSend == 0 || await showConsentDialog(context, imageCount: toSend);
    await controller.recognize(consentGranted: granted);
  }

  /// [VP-H1-E2] Elige de dónde agregar páginas: cámara o galería.
  Future<void> _addPage(BuildContext context) async {
    final origin = await showModalBottomSheet<ImageOrigin>(
      context: context,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // [ED-H1-E4] Spec 009: escanear más hojas.
            ListTile(
              leading: const Icon(Icons.document_scanner_outlined),
              title: Text(context.strings.addPageFromScanner),
              onTap: () => Navigator.of(context).pop(ImageOrigin.scanner),
            ),
            ListTile(
              leading: const Icon(Icons.photo_camera_outlined),
              title: Text(context.strings.addPageFromCamera),
              onTap: () => Navigator.of(context).pop(ImageOrigin.camera),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: Text(context.strings.addPageFromGallery),
              onTap: () => Navigator.of(context).pop(ImageOrigin.gallery),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
    if (origin != null) await controller.addPages(origin);
  }

  @override
  Widget build(BuildContext context) {
    final image = controller.pendingImage;
    if (image == null) return const SizedBox.shrink();
    final busy = controller.isBusy;
    final status = controller.status;
    final recognizing = busy && status?.event == StatusEvent.recognizing;
    final replaceLabel = context.strings.replaceImageLabel(image.origin);
    final textTheme = Theme.of(context).textTheme;
    final pageCount = controller.pages.length;
    final pageNumber = controller.selectedPageIndex + 1;
    final manyPages = pageCount > 1;

    return AuroraScaffold(
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Barra superior: cerrar (cancelar la selección) y título.
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 4, 16, 4),
            child: Row(
              children: [
                IconButton(
                  tooltip: context.strings.cancelSelectionTooltip,
                  icon: const Icon(Icons.close, color: Colors.white),
                  onPressed: busy ? null : controller.cancelPreview,
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // [PA-H2-E5] Título como encabezado para TalkBack.
                      Semantics(
                        // Nodo propio: no se mezcla con los botones vecinos.
                        container: true,
                        header: true,
                        child: Text(
                          context.strings.previewTitle,
                          style: textTheme.titleLarge?.copyWith(
                            color: Colors.white,
                          ),
                        ),
                      ),
                      if (manyPages)
                        Text(
                          context.strings.pageOf(pageNumber, pageCount),
                          style: textTheme.bodySmall?.copyWith(
                            color: Aurora.textSecondary,
                          ),
                        ),
                    ],
                  ),
                ),
                // [VP-H2-E2] [VP-H2-E3] Acciones de la página elegida; con una sola
                // página no se muestran [VP-H2-E5]. Desactivadas se ven en gris.
                if (manyPages) ...[
                  IconButton(
                    tooltip: context.strings.movePageBefore,
                    icon: const Icon(Icons.chevron_left),
                    color: Colors.white,
                    disabledColor: Aurora.textMuted.withValues(alpha: 0.4),
                    onPressed: busy || pageNumber == 1
                        ? null
                        : () => controller.moveSelectedPage(-1),
                  ),
                  IconButton(
                    tooltip: context.strings.movePageAfter,
                    icon: const Icon(Icons.chevron_right),
                    color: Colors.white,
                    disabledColor: Aurora.textMuted.withValues(alpha: 0.4),
                    onPressed: busy || pageNumber == pageCount
                        ? null
                        : () => controller.moveSelectedPage(1),
                  ),
                  IconButton(
                    tooltip: context.strings.removePage,
                    icon: const Icon(Icons.delete_outline),
                    color: Colors.white,
                    disabledColor: Aurora.textMuted.withValues(alpha: 0.4),
                    onPressed: busy ? null : controller.removeSelectedPage,
                  ),
                ],
              ],
            ),
          ),
          // La imagen, con la animación de escaneo mientras se reconoce.
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(Aurora.radiusLarge),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    const ColoredBox(color: Color(0x33000000)),
                    InteractiveViewer(
                      // Permite acercar la imagen con dos dedos para revisarla.
                      child: Image.memory(
                        image.bytes,
                        fit: BoxFit.contain,
                        cacheWidth:
                            1600, // ahorra memoria con fotos muy grandes
                        errorBuilder: (context, error, stackTrace) => Center(
                          child: Padding(
                            padding: const EdgeInsets.all(24),
                            child: Text(
                              context.strings.imagePreviewUnavailable,
                              textAlign: TextAlign.center,
                              style: textTheme.bodyMedium?.copyWith(
                                color: Aurora.textSecondary,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    if (recognizing) ...[
                      const ScanOverlay(),
                      Positioned(
                        left: 0,
                        right: 0,
                        bottom: 18,
                        child: Center(
                          child: _ReadingChip(
                            text: context.strings.readingHandwriting,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
          // [VP-H1-E1] Miniaturas de las páginas y «Agregar página».
          const SizedBox(height: 12),
          PageStrip(
            pages: controller.pages,
            selectedIndex: controller.selectedPageIndex,
            onSelect: busy ? null : controller.selectPage,
            onAdd: busy ? null : () => _addPage(context),
          ),
          // Panel inferior: datos, avisos y acciones.
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
            child: SurfaceCard(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    busy
                        ? context.strings.recognizingHint
                        : manyPages
                        ? '${context.strings.pageOf(pageNumber, pageCount)} · '
                              '${context.strings.imageDetails(image)}'
                        : context.strings.imageDetails(image),
                    textAlign: TextAlign.center,
                    style: textTheme.bodySmall?.copyWith(
                      color: Aurora.textSecondary,
                    ),
                  ),
                  if (status != null && !busy) ...[
                    const SizedBox(height: 12),
                    StatusBanner(
                      status: status,
                      onAurora: true,
                      actionLabel: switch (status.action) {
                        StatusAction.retryRecognition => context.strings.retry,
                        StatusAction.replaceImage => replaceLabel,
                        // Spec 009: sin escáner, se agrega una fotografía.
                        StatusAction.takePhoto => context.strings.takePhoto,
                        // Compartir solo existe en el editor (spec 003).
                        StatusAction.shareExport || null => null,
                      },
                      onAction: switch (status.action) {
                        StatusAction.retryRecognition =>
                          () => _acceptAndRecognize(context),
                        StatusAction.replaceImage => controller.replaceImage,
                        StatusAction.takePhoto => () => controller.addPages(
                          ImageOrigin.camera,
                        ),
                        StatusAction.shareExport || null => null,
                      },
                    ),
                  ],
                  const SizedBox(height: 14),
                  PrimaryButton(
                    label: manyPages
                        ? context.strings.recognizePages(pageCount)
                        : context.strings.acceptAndRecognize,
                    icon: Icons.auto_awesome,
                    isLoading: recognizing,
                    onPressed: busy ? null : () => _acceptAndRecognize(context),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      // [EX-H2-E1] Recortar o girar antes de reconocer.
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: busy ? null : controller.editImage,
                          icon: const Icon(Icons.crop_rotate),
                          label: Text(
                            context.strings.editImage,
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: OutlinedButton(
                          onPressed: busy ? null : controller.replaceImage,
                          child: Text(
                            replaceLabel,
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                    ],
                  ),
                  // «Usar la imagen original» solo si ya se recortó [EX-H2-E5].
                  Row(
                    children: [
                      // Toma todo el espacio libre, para que el texto quepa en una
                      // línea; sin él, «Cancelar» queda a la derecha.
                      if (controller.canRestoreOriginalImage)
                        Expanded(
                          child: Align(
                            alignment: Alignment.centerLeft,
                            child: TextButton.icon(
                              onPressed: busy
                                  ? null
                                  : controller.restoreOriginalImage,
                              icon: const Icon(Icons.undo),
                              label: Text(context.strings.restoreOriginalImage),
                            ),
                          ),
                        )
                      else
                        const Spacer(),
                      TextButton(
                        onPressed: busy ? null : controller.cancelPreview,
                        child: Text(context.strings.cancel),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Píldora «Leyendo su escritura…» sobre la imagen durante el reconocimiento.
class _ReadingChip extends StatelessWidget {
  const _ReadingChip({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return SurfaceCard(
      radius: 30,
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.auto_awesome, color: Aurora.sky, size: 18),
          const SizedBox(width: 8),
          Text(
            text,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
