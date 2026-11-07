// Selector de formato de exportación (tareas T052 y T133; Historia 3, escenario 1).
//
// Dos tarjetas grandes: Word (ícono azul) y PDF (ícono rojo). Devuelve null si la
// persona cierra la hoja sin elegir; en ese caso no se exporta nada.
// Spec 006: con la letra grande, la hoja crece y se desplaza [PA-H3-E1].

import 'package:flutter/material.dart';

import '../../models/export_format.dart';
import '../strings.dart';

/// Abre la hoja para elegir Word o PDF. Devuelve el formato elegido, o null si se
/// cerró sin elegir.
Future<ExportFormat?> showExportFormatSheet(BuildContext context) {
  return showModalBottomSheet<ExportFormat>(
    context: context,
    showDragHandle: true,
    isScrollControlled:
        true, // puede pasar de 9/16 de la pantalla si lo necesita
    builder: (context) => SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              context.strings.chooseFormatTitle,
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            _FormatTile(
              icon: Icons.description_outlined,
              color: const Color(0xFF2B579A), // azul de Word
              title: context.strings.wordOption,
              subtitle: context.strings.wordOptionHint,
              onTap: () => Navigator.of(context).pop(ExportFormat.docx),
            ),
            const SizedBox(height: 12),
            _FormatTile(
              icon: Icons.picture_as_pdf_outlined,
              color: const Color(0xFFD93025), // rojo de PDF
              title: context.strings.pdfOption,
              subtitle: context.strings.pdfOptionHint,
              onTap: () => Navigator.of(context).pop(ExportFormat.pdf),
            ),
          ],
        ),
      ),
    ),
  );
}

class _FormatTile extends StatelessWidget {
  const _FormatTile({
    required this.icon,
    required this.color,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Material(
      color: colors.surfaceContainerHighest,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon, color: Colors.white),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: Theme.of(context).textTheme.titleMedium),
                    Text(
                      subtitle,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right, color: colors.onSurfaceVariant),
            ],
          ),
        ),
      ),
    );
  }
}
