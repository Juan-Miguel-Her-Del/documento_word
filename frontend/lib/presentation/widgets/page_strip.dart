// Tira de miniaturas de las páginas en la vista previa (tarea T309; spec 004, módulo 2;
// research.md de 004, R6).
//
// - Cada miniatura muestra su número; la página elegida tiene borde azul claro
//   [VP-H1-E1] [VP-H2-E1].
// - Al final, la tarjeta «Agregar página» [VP-H1-E2].
// - Las miniaturas se decodifican a 160 px de ancho para no ocupar memoria de más.

import 'package:flutter/material.dart';

import '../../models/document_page.dart';
import '../../theme/aurora.dart';
import '../strings.dart';

/// Tira horizontal con las miniaturas de las páginas y, al final, la tarjeta
/// «Agregar página».
class PageStrip extends StatelessWidget {
  const PageStrip({
    super.key,
    required this.pages,
    required this.selectedIndex,
    required this.onSelect,
    required this.onAdd,
  });

  /// Las páginas del documento, en orden.
  final List<DocumentPage> pages;
  /// Posición de la página que se ve en grande (la primera es 0).
  final int selectedIndex;

  /// null = inactiva (por ejemplo, mientras se reconoce).
  final ValueChanged<int>? onSelect;
  /// Agrega una página; null desactiva la tarjeta (por ejemplo, mientras se
  /// reconoce).
  final VoidCallback? onAdd;

  static const double _height = 76;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: _height,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: pages.length + 1,
        separatorBuilder: (context, index) => const SizedBox(width: 10),
        itemBuilder: (context, index) {
          if (index == pages.length) return _AddTile(onTap: onAdd);
          final select = onSelect;
          return _Thumbnail(
            page: pages[index],
            number: index + 1,
            selected: index == selectedIndex,
            onTap: select == null ? null : () => select(index),
          );
        },
      ),
    );
  }
}

class _Thumbnail extends StatelessWidget {
  const _Thumbnail({
    required this.page,
    required this.number,
    required this.selected,
    required this.onTap,
  });

  final DocumentPage page;
  final int number;
  final bool selected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final shape = BorderRadius.circular(Aurora.radiusSmall);
    return Semantics(
      button: true,
      selected: selected,
      label: context.strings.pageThumbnail(number, selected),
      excludeSemantics: true,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          width: 58,
          decoration: BoxDecoration(
            borderRadius: shape,
            border: Border.all(
              color: selected ? Aurora.blueLight : Aurora.surfaceBorder,
              width: selected ? 2.5 : 1,
            ),
          ),
          child: ClipRRect(
            borderRadius: shape,
            child: Stack(
              fit: StackFit.expand,
              children: [
                Image.memory(
                  page.image.bytes,
                  fit: BoxFit.cover,
                  cacheWidth: 160, // miniatura: poca memoria
                  errorBuilder: (context, error, stackTrace) =>
                      const ColoredBox(color: Aurora.surface),
                ),
                // Número de página en la esquina.
                Positioned(
                  left: 4,
                  bottom: 4,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 1,
                    ),
                    decoration: BoxDecoration(
                      color: selected ? Aurora.blue : Aurora.backgroundTop,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '$number',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Tarjeta «Agregar página».
class _AddTile extends StatelessWidget {
  const _AddTile({required this.onTap});

  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: context.strings.addPage,
      excludeSemantics: true,
      child: Material(
        color: Aurora.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(Aurora.radiusSmall),
          side: const BorderSide(color: Aurora.surfaceBorder),
        ),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(Aurora.radiusSmall),
          child: SizedBox(
            width: 58,
            child: Icon(
              Icons.add_photo_alternate_outlined,
              color: onTap == null ? Aurora.textMuted : Aurora.blueLight,
            ),
          ),
        ),
      ),
    );
  }
}
