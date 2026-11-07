// Editor del texto reconocido (tareas T043 y T132; spec 001, módulos 3 y 4).
//
// - [H1-E6] Muestra el texto en un campo editable y la advertencia permanente de que
//   el reconocimiento puede contener errores.
// - Permite agregar, borrar y cambiar palabras, corregir títulos y separar párrafos.
//   Cada cambio llega al controlador (updateText), que guarda el borrador.
// - «Exportar» abre el selector Word/PDF [H3-E1] y exporta el texto actual [H1-E9].
// - El menú ofrece «Procesar otra imagen» [H1-E13] y «Descartar texto» [H1-E17],
//   ambos con confirmación (spec 001, módulo 3). El avatar abre el menú de cuenta.
// - Mientras se exporta, el texto queda en solo lectura y el botón inactivo [SC-008].
//
// Estilo Aurora (spec 002): encabezado azul marino sólido y el texto sobre una
// superficie clara u oscura según el sistema, para leer cómodamente textos largos
// [CU-H3-E4].
//
// Spec 003 (tareas T210 y T216):
// - Las palabras dudosas se ven resaltadas (ReviewTextController). Una barra indica
//   cuántas quedan y ofrece «Siguiente» y «Está bien» [EX-H1-E1] [EX-H1-E3]
//   [EX-H1-E5] [EX-H1-E9].
// - Después de guardar, el aviso de éxito ofrece «Compartir» [EX-H3-E1].
//
// Spec 005: el texto usa el tamaño de letra elegido en Ajustes [AV-H1-E4].
//
// Spec 010 (tarea T903): el menú ofrece «Copiar todo el texto» si hay texto
// [OR-H2-E1] [OR-H2-E2].
//
// Spec 006 (tareas T508 y T512):
// - Al ir a una palabra dudosa con «Siguiente», TalkBack la lee [PA-H2-E3].
// - Con la letra grande del sistema, los avisos de arriba se desplazan en un espacio
//   de hasta el 45 % del alto y el texto conserva lugar para editarse [PA-H3-E2]
//   (research.md de 006, R5).

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter/services.dart';

import '../../models/operation_status.dart';
import '../../state/auth_controller.dart';
import '../../state/document_flow_controller.dart';
import '../../theme/aurora.dart';
import '../settings_scope.dart';
import '../strings.dart';
import '../widgets/account_menu.dart';
import '../widgets/confirm_dialog.dart';
import '../widgets/export_format_sheet.dart';
import '../widgets/primary_button.dart';
import '../widgets/review_text_controller.dart';
import '../widgets/status_banner.dart';
import 'settings_screen.dart';

/// Opciones del menú del editor.
enum _EditorAction { copyAll, processAnotherImage, discard }

/// Editor del texto reconocido: revisar las palabras dudosas, corregir y guardar
/// como Word o PDF.
class EditorScreen extends StatefulWidget {
  const EditorScreen({super.key, required this.controller, required this.auth});

  /// El documento en edición: el texto, sus marcas y las acciones (exportar,
  /// descartar, copiar…).
  final DocumentFlowController controller;
  /// Sesión, para el menú de la cuenta.
  final AuthController auth;

  @override
  State<EditorScreen> createState() => _EditorScreenState();
}

class _EditorScreenState extends State<EditorScreen> {
  /// Controla el contenido del campo de texto; empieza con el texto del documento y
  /// pinta las palabras dudosas que indica el controlador del flujo.
  late final ReviewTextController _textController = ReviewTextController(
    text: widget.controller.documentText ?? '',
    uncertainRanges: () => widget.controller.uncertainRanges,
  );

  /// Foco del campo de texto: «Siguiente» lo activa para mostrar la selección.
  final FocusNode _textFocus = FocusNode();

  @override
  void dispose() {
    _textController.dispose();
    _textFocus.dispose();
    super.dispose();
  }

  /// La marca que contiene la selección actual, o null si no hay ninguna.
  TextRange? _selectedUncertainWord(TextSelection selection) {
    if (!selection.isValid) return null;
    for (final range in widget.controller.uncertainRanges) {
      if (range.start <= selection.start && selection.end <= range.end) {
        return range;
      }
    }
    return null;
  }

  /// [EX-H1-E3] Selecciona la siguiente palabra dudosa después del cursor; tras la
  /// última, vuelve a la primera.
  void _selectNextUncertainWord() {
    final ranges = widget.controller.uncertainRanges;
    if (ranges.isEmpty) return;
    final selection = _textController.selection;
    final from = selection.isValid ? selection.end : 0;
    final next = ranges.firstWhere(
      (range) => range.start >= from,
      orElse: () => ranges.first,
    );
    _textController.selection = TextSelection(
      baseOffset: next.start,
      extentOffset: next.end,
    );
    _textFocus.requestFocus(); // muestra la selección y la lleva a la vista
    // [PA-H2-E3] El resaltado no se ve con TalkBack: se lee la palabra elegida.
    SemanticsService.announce(
      context.strings.uncertainWordAnnouncement(
        _textController.text.substring(next.start, next.end),
      ),
      Directionality.of(context),
    );
  }

  /// [EX-H1-E5] «Está bien»: quita la marca de la palabra seleccionada.
  void _acceptSelectedWord() {
    final range = _selectedUncertainWord(_textController.selection);
    if (range != null) widget.controller.acceptUncertainWord(range);
  }

  Future<void> _export() async {
    final format = await showExportFormatSheet(context);
    if (format == null) return; // cerró la hoja sin elegir
    await widget.controller.export(format);
  }

  Future<void> _processAnotherImage() async {
    final confirmed = await showConfirmDialog(
      context,
      title: context.strings.replaceTextTitle,
      message: context.strings.replaceTextMessage,
      confirmLabel: context.strings.replaceTextConfirm,
    );
    if (confirmed) widget.controller.startAnotherImage();
  }

  Future<void> _discard() async {
    final confirmed = await showConfirmDialog(
      context,
      title: context.strings.discardTitle,
      message: context.strings.discardMessage,
      confirmLabel: context.strings.discardConfirm,
      destructive: true,
    );
    if (confirmed) await widget.controller.discardDocument();
  }

  /// [OR-H2-E1] [SC-1002] Copia el texto tal cual está, sin las marcas de palabras
  /// dudosas (research.md de 010, R2).
  Future<void> _copyAll() async {
    final messenger = ScaffoldMessenger.of(context);
    final copied = context.strings.textCopied;
    await Clipboard.setData(ClipboardData(text: _textController.text));
    messenger.showSnackBar(SnackBar(content: Text(copied)));
  }

  void _onMenuSelected(_EditorAction action) {
    switch (action) {
      case _EditorAction.copyAll:
        unawaited(_copyAll());
      case _EditorAction.processAnotherImage:
        unawaited(_processAnotherImage());
      case _EditorAction.discard:
        unawaited(_discard());
    }
  }

  @override
  Widget build(BuildContext context) {
    final controller = widget.controller;
    final busy = controller.isBusy;
    final status = controller.status;
    final textTheme = Theme.of(context).textTheme;
    // [PA-H3-E2] ¿Letra del sistema muy grande? Entonces el encabezado se acorta.
    final largeText = MediaQuery.textScalerOf(context).scale(1) > 1.3;

    return Scaffold(
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Encabezado azul marino, como el fondo de las pantallas Aurora.
          AnnotatedRegion<SystemUiOverlayStyle>(
            value: SystemUiOverlayStyle.light,
            child: DecoratedBox(
              decoration: const BoxDecoration(color: Aurora.backgroundBottom),
              child: SafeArea(
                bottom: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 8, 8, 20),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // [PA-H2-E5] Título como encabezado para TalkBack.
                            // [PA-H3-E2] Crece hasta el 150 %, como los títulos con
                            // la escala no lineal de Android 14 (research.md de 006,
                            // R5).
                            MediaQuery.withClampedTextScaling(
                              maxScaleFactor: 1.5,
                              child: Semantics(
                                // Nodo propio: no se mezcla con los botones vecinos.
                                container: true,
                                header: true,
                                child: Text(
                                  context.strings.editorTitle,
                                  style: textTheme.headlineSmall?.copyWith(
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ),
                            // Con la letra muy grande se omite: la advertencia de
                            // abajo dice lo mismo y el texto gana espacio.
                            if (!largeText)
                              Text(
                                context.strings.editorSubtitle,
                                style: textTheme.bodyMedium?.copyWith(
                                  color: Aurora.textSecondary,
                                ),
                              ),
                          ],
                        ),
                      ),
                      PopupMenuButton<_EditorAction>(
                        tooltip: context.strings.moreActionsTooltip,
                        enabled: !busy,
                        icon: const Icon(Icons.more_vert, color: Colors.white),
                        onSelected: _onMenuSelected,
                        itemBuilder: (context) => [
                          // [OR-H2-E2] Solo si hay texto.
                          if (_textController.text.trim().isNotEmpty)
                            PopupMenuItem(
                              value: _EditorAction.copyAll,
                              child: Text(context.strings.copyAllText),
                            ),
                          PopupMenuItem(
                            value: _EditorAction.processAnotherImage,
                            child: Text(context.strings.processAnotherImage),
                          ),
                          PopupMenuItem(
                            value: _EditorAction.discard,
                            child: Text(context.strings.discardText),
                          ),
                        ],
                      ),
                      AccountButton(auth: widget.auth, documents: controller),
                      const SizedBox(width: 8),
                    ],
                  ),
                ),
              ),
            ),
          ),
          Expanded(
            child: SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: LayoutBuilder(
                  builder: (context, constraints) => Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // [PA-H3-E2] Avisos de arriba: con la letra normal caben enteros;
                      // con la letra grande se desplazan en hasta el 45 % del alto, y el
                      // campo de texto sigue en el mismo lugar (no pierde el foco).
                      ConstrainedBox(
                        constraints: BoxConstraints(
                          maxHeight: constraints.maxHeight * 0.45,
                        ),
                        child: SingleChildScrollView(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              const _RecognitionWarning(),
                              if (status != null) ...[
                                const SizedBox(height: 12),
                                StatusBanner(
                                  status: status,
                                  // [EX-H3-E1] «Compartir» el archivo recién guardado.
                                  actionLabel:
                                      status.action == StatusAction.shareExport
                                      ? context.strings.share
                                      : null,
                                  onAction:
                                      status.action ==
                                              StatusAction.shareExport &&
                                          !busy
                                      ? controller.shareLastExport
                                      : null,
                                ),
                              ],
                              // [EX-H1-E9] La barra solo aparece si quedan palabras dudosas.
                              if (controller.uncertainRanges.isNotEmpty) ...[
                                const SizedBox(height: 12),
                                ValueListenableBuilder<TextEditingValue>(
                                  valueListenable: _textController,
                                  builder: (context, value, _) => _ReviewBar(
                                    count: controller.uncertainRanges.length,
                                    onNext: busy
                                        ? null
                                        : _selectNextUncertainWord,
                                    onAccept:
                                        busy ||
                                            _selectedUncertainWord(
                                                  value.selection,
                                                ) ==
                                                null
                                        ? null
                                        : _acceptSelectedWord,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Expanded(
                        child: Card(
                          margin: EdgeInsets.zero,
                          clipBehavior: Clip.antiAlias,
                          child: TextField(
                            controller: _textController,
                            focusNode: _textFocus,
                            readOnly: busy,
                            expands: true,
                            maxLines: null,
                            minLines: null,
                            keyboardType: TextInputType.multiline,
                            textAlignVertical: TextAlignVertical.top,
                            // [AV-H1-E4] Tamaño de letra de Ajustes.
                            style: editorTextStyle(
                              context,
                              SettingsScope.of(context).settings.textSize,
                            ),
                            decoration: InputDecoration(
                              hintText: context.strings.editorHint,
                              border: InputBorder.none,
                              contentPadding: EdgeInsets.all(18),
                            ),
                            onChanged: controller.updateText,
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      // Contador de palabras y caracteres, se actualiza al escribir.
                      ValueListenableBuilder<TextEditingValue>(
                        valueListenable: _textController,
                        builder: (context, value, _) {
                          final trimmed = value.text.trim();
                          final words = trimmed.isEmpty
                              ? 0
                              : trimmed.split(RegExp(r'\s+')).length;
                          return Text(
                            context.strings.textStats(
                              words,
                              value.text.runes.length,
                            ),
                            textAlign: TextAlign.end,
                            style: textTheme.labelMedium,
                          );
                        },
                      ),
                      const SizedBox(height: 12),
                      PrimaryButton(
                        label: context.strings.export,
                        icon: Icons.file_download_outlined,
                        isLoading: busy,
                        onPressed: busy ? null : _export,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Barra de revisión de palabras dudosas (spec 003): cuántas quedan, «Está bien» y
/// «Siguiente».
class _ReviewBar extends StatelessWidget {
  const _ReviewBar({
    required this.count,
    required this.onNext,
    required this.onAccept,
  });

  final int count;
  final VoidCallback? onNext;

  /// null si la selección no está sobre una palabra marcada.
  final VoidCallback? onAccept;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 10, 10, 6),
      decoration: BoxDecoration(
        color: colors.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(Aurora.radius),
        border: Border.all(color: colors.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Semantics(
            liveRegion: true, // el lector de pantalla anuncia cuántas quedan
            child: Row(
              children: [
                Icon(Icons.rate_review_outlined, color: colors.primary),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        context.strings.uncertainWordsCount(count),
                        style: textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        onAccept == null
                            ? context.strings.uncertainWordsHint
                            : context.strings.acceptUncertainWordHint,
                        style: textTheme.bodySmall?.copyWith(
                          color: colors.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          // Wrap: si no caben en una fila (letra grande), los botones bajan.
          Wrap(
            alignment: WrapAlignment.end,
            spacing: 8,
            children: [
              TextButton.icon(
                onPressed: onAccept,
                icon: const Icon(Icons.check),
                label: Text(context.strings.acceptUncertainWord),
              ),
              TextButton.icon(
                onPressed: onNext,
                icon: const Icon(Icons.arrow_forward),
                label: Text(context.strings.nextUncertainWord),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// [H1-E6] Advertencia permanente: el texto reconocido puede tener errores.
class _RecognitionWarning extends StatelessWidget {
  const _RecognitionWarning();

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final foreground = dark ? Aurora.warning : const Color(0xFF7A4D00);
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Aurora.warning.withValues(alpha: dark ? 0.14 : 0.22),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Aurora.warning.withValues(alpha: 0.5)),
      ),
      child: Row(
        children: [
          Icon(Icons.warning_amber_rounded, color: foreground),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              context.strings.recognitionWarning,
              style: TextStyle(color: foreground),
            ),
          ),
        ],
      ),
    );
  }
}
