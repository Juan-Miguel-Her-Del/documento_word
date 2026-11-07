// Pantalla «Mis documentos» (tareas T607, T609 y T611; spec 007; research.md de 007,
// R9).
//
// - Lista los documentos guardados, el más reciente primero, con título, fecha,
//   formatos y palabras [HD-H1-E1] [HD-H1-E4]; sin documentos, un mensaje lo explica.
// - Tocar un documento lo abre en el editor; si hay cambios sin exportar, primero pide
//   confirmación [HD-H2-E1] [HD-H2-E2].
// - «Eliminar» y «Borrar todo» piden confirmación y no tocan los archivos guardados
//   [HD-H3-E1] [HD-H3-E2] [HD-H3-E3].
// Cumple las guías de accesibilidad de 006: cada botón tiene nombre propio y la lista se
// desplaza con la letra grande.
//
// Spec 010 (tarea T906; research.md de 010, R3 a R5):
// - un campo de búsqueda filtra por título o texto, sin importar mayúsculas ni tildes
//   [OR-H3-E1]; si nada coincide, un mensaje lo dice [OR-H3-E2];
// - «Renombrar» cambia el título de un documento [OR-H3-E3].

import 'package:flutter/material.dart';

import '../../models/history_entry.dart';
import '../../state/document_flow_controller.dart';
import '../../theme/aurora.dart';
import '../strings.dart';
import '../widgets/aurora_header.dart';
import '../widgets/aurora_scaffold.dart';
import '../widgets/confirm_dialog.dart';
import '../widgets/surface_card.dart';

/// Pantalla «Mis documentos»: lista, busca, abre, renombra y elimina los documentos
/// guardados.
class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key, required this.controller});

  /// El documento en curso: da el historial y abre en el editor el documento
  /// elegido.
  final DocumentFlowController controller;

  /// [HD-H1-E4] Abre «Mis documentos» encima del inicio.
  static Future<void> open(
    BuildContext context,
    DocumentFlowController controller,
  ) => Navigator.of(context).push(
    MaterialPageRoute<void>(
      builder: (_) => HistoryScreen(controller: controller),
    ),
  );

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  /// Spec 010: lo que se busca [OR-H3-E1].
  String _query = '';

  DocumentFlowController get _controller => widget.controller;

  /// [HD-H2-E1] [HD-H2-E2] Abre el documento en el editor y vuelve al flujo.
  Future<void> _open(HistoryEntry entry) async {
    if (_controller.hasUnexportedChanges) {
      final confirmed = await showConfirmDialog(
        context,
        title: context.strings.historyOpenTitle,
        message: context.strings.historyOpenMessage,
        confirmLabel: context.strings.historyOpenConfirm,
      );
      if (!confirmed) return; // cancelar no cambia nada
    }
    await _controller.openFromHistory(entry);
    if (mounted) Navigator.of(context).pop();
  }

  /// [HD-H3-E1] Quita un documento del historial, con confirmación.
  Future<void> _delete(HistoryEntry entry) async {
    final confirmed = await showConfirmDialog(
      context,
      title: context.strings.historyDeleteTitle,
      message: context.strings.historyDeleteMessage(entry.title),
      confirmLabel: context.strings.historyDeleteConfirm,
      destructive: true,
    );
    if (confirmed) await _controller.history.remove(entry.id);
  }

  /// [OR-H3-E3] Pide el nombre nuevo; cancelar no cambia nada.
  Future<void> _rename(HistoryEntry entry) async {
    final name = await showDialog<String>(
      context: context,
      builder: (_) => _RenameDialog(initial: entry.title),
    );
    if (name != null) await _controller.history.rename(entry.id, name);
  }

  /// [HD-H3-E2] Vacía el historial, con confirmación.
  Future<void> _clearAll() async {
    final confirmed = await showConfirmDialog(
      context,
      title: context.strings.historyClearTitle,
      message: context.strings.historyClearMessage(
        _controller.history.entries.length,
      ),
      confirmLabel: context.strings.historyClearConfirm,
      destructive: true,
    );
    if (confirmed) await _controller.history.clear();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _controller.history,
      builder: (context, _) {
        final entries = _controller.history.entries;
        final shown = entries.where((entry) => entry.matchesQuery(_query));
        return AuroraScaffold(
          body: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              AuroraHeader(
                title: context.strings.historyTitle,
                actions: [
                  if (entries.isNotEmpty)
                    IconButton(
                      tooltip: context.strings.historyClearAll,
                      icon: const Icon(
                        Icons.delete_sweep_outlined,
                        color: Colors.white,
                      ),
                      onPressed: _clearAll,
                    ),
                ],
              ),
              // [OR-H3-E1] Búsqueda, solo si hay documentos.
              if (entries.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                  child: TextField(
                    onChanged: (value) => setState(() => _query = value),
                    textInputAction: TextInputAction.search,
                    decoration: InputDecoration(
                      hintText: context.strings.historySearchHint,
                      prefixIcon: const Icon(Icons.search),
                    ),
                  ),
                ),
              Expanded(
                child: entries.isEmpty
                    ? const _EmptyHistory()
                    : shown.isEmpty
                    ? _NoResults(query: _query.trim())
                    : ListView(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                        children: [
                          for (final entry in shown) ...[
                            _EntryCard(
                              entry: entry,
                              onOpen: () => _open(entry),
                              onRename: () => _rename(entry),
                              onDelete: () => _delete(entry),
                            ),
                            const SizedBox(height: 12),
                          ],
                        ],
                      ),
              ),
            ],
          ),
        );
      },
    );
  }
}

/// Un documento guardado: título, detalles y los botones «Renombrar» y «Eliminar».
class _EntryCard extends StatelessWidget {
  const _EntryCard({
    required this.entry,
    required this.onOpen,
    required this.onRename,
    required this.onDelete,
  });

  final HistoryEntry entry;
  final VoidCallback onOpen;
  final VoidCallback onRename;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return SurfaceCard(
      padding: EdgeInsets.zero,
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(
          onTap: onOpen,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 4, 12),
            child: Row(
              children: [
                ExcludeSemantics(
                  child: Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: Aurora.iconBadge,
                      borderRadius: BorderRadius.circular(Aurora.radiusSmall),
                    ),
                    child: const Icon(
                      Icons.description_outlined,
                      color: Aurora.blueLight,
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        entry.title,
                        style: textTheme.titleMedium?.copyWith(
                          color: Aurora.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        context.strings.historyDetails(entry),
                        style: textTheme.bodySmall?.copyWith(
                          color: Aurora.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                // Nombres propios para TalkBack: «Renombrar Apuntes de biología»
                // (spec 010, R5) y «Eliminar Apuntes de biología».
                IconButton(
                  tooltip: context.strings.historyRename(entry.title),
                  icon: const Icon(
                    Icons.edit_outlined,
                    color: Aurora.textMuted,
                  ),
                  onPressed: onRename,
                ),
                IconButton(
                  tooltip: context.strings.historyDelete(entry.title),
                  icon: const Icon(
                    Icons.delete_outline,
                    color: Aurora.textMuted,
                  ),
                  onPressed: onDelete,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// [OR-H3-E3] Diálogo para renombrar: de 1 a 60 caracteres, sin contar los espacios de
/// los lados. Devuelve el nombre, o null si se cancela.
class _RenameDialog extends StatefulWidget {
  const _RenameDialog({required this.initial});

  final String initial;

  @override
  State<_RenameDialog> createState() => _RenameDialogState();
}

class _RenameDialogState extends State<_RenameDialog> {
  late final _name = TextEditingController(text: widget.initial);

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      scrollable: true, // letra grande (spec 006)
      title: Text(context.strings.historyRenameTitle),
      content: TextField(
        controller: _name,
        autofocus: true,
        maxLength: 60,
        textInputAction: TextInputAction.done,
        decoration: InputDecoration(
          labelText: context.strings.historyRenameLabel,
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(context.strings.cancel),
        ),
        ValueListenableBuilder<TextEditingValue>(
          valueListenable: _name,
          builder: (context, value, _) => FilledButton(
            // Un nombre de solo espacios no se acepta (caso límite).
            onPressed: value.text.trim().isEmpty
                ? null
                : () => Navigator.of(context).pop(value.text.trim()),
            child: Text(context.strings.historyRenameConfirm),
          ),
        ),
      ],
    );
  }
}

/// [HD-H1-E4] Mensaje cuando todavía no hay documentos guardados.
class _EmptyHistory extends StatelessWidget {
  const _EmptyHistory();

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return ListView(
      padding: const EdgeInsets.fromLTRB(32, 48, 32, 24),
      children: [
        const ExcludeSemantics(
          child: Icon(Icons.history, size: 64, color: Aurora.textMuted),
        ),
        const SizedBox(height: 16),
        Text(
          context.strings.historyEmptyTitle,
          textAlign: TextAlign.center,
          style: textTheme.titleLarge?.copyWith(color: Colors.white),
        ),
        const SizedBox(height: 8),
        Text(
          context.strings.historyEmptyMessage,
          textAlign: TextAlign.center,
          style: textTheme.bodyMedium?.copyWith(color: Aurora.textSecondary),
        ),
      ],
    );
  }
}

/// [OR-H3-E2] Mensaje cuando la búsqueda no encuentra nada.
class _NoResults extends StatelessWidget {
  const _NoResults({required this.query});

  final String query;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(32, 32, 32, 24),
      children: [
        // Se lee solo para TalkBack al cambiar la búsqueda.
        Semantics(
          liveRegion: true,
          child: Text(
            context.strings.historyNoResults(query),
            textAlign: TextAlign.center,
            style: Theme.of(
              context,
            ).textTheme.bodyLarge?.copyWith(color: Aurora.textSecondary),
          ),
        ),
      ],
    );
  }
}
