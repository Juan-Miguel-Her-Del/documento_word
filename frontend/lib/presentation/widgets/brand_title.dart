// Título de marca «HandText AI» (tarea T141; research.md de 002, R9).
//
// «HandText» en blanco y «AI» en azul claro, como un logotipo de texto. Reemplaza al
// título con degradado de la paleta anterior.
// Spec 006: es el encabezado de la bienvenida y de «Acerca de» [PA-H2-E5].

import 'package:flutter/material.dart';

import '../../theme/aurora.dart';
import '../strings.dart';

/// Nombre «HandText AI» como logotipo de texto, con «AI» en azul claro.
class BrandTitle extends StatelessWidget {
  const BrandTitle({super.key, this.style});

  /// Estilo del texto, para usar el título en distintos tamaños.
  final TextStyle? style;

  @override
  Widget build(BuildContext context) {
    // Separa la última palabra del nombre («AI») para pintarla de otro color.
    final name = context.strings.appName;
    final split = name.lastIndexOf(' ');
    return Semantics(
      container: true, // nodo propio: no se mezcla con los botones vecinos
      header: true,
      child: Text.rich(
        TextSpan(
          children: [
            TextSpan(text: name.substring(0, split)),
            TextSpan(
              text: name.substring(split),
              style: const TextStyle(color: Aurora.blueLight),
            ),
          ],
        ),
        textAlign: TextAlign.center,
        style: (style ?? const TextStyle()).copyWith(
          color: Aurora.textPrimary,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.5,
        ),
      ),
    );
  }
}
