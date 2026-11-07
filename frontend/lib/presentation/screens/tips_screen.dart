// Consejos para una buena foto (tarea T504; spec 006, Historia 1; research.md de 006,
// R3).
//
// Cuatro consejos, uno por página, sobre el fondo Aurora:
// - «Siguiente» pasa al siguiente y, en el último, «Empezar» termina [PA-H1-E2].
// - «Saltar» termina en cualquier momento [PA-H1-E3].
// - Cada página dice «Consejo 2 de 4», con el título como encabezado; el dibujo es
//   decorativo y TalkBack lo omite [PA-H2-E4]. Al cambiar de página se anuncia el
//   consejo nuevo.
//
// La misma pantalla sirve para la primera vez (app_root.dart marca los consejos como
// vistos) y para volver a verlos desde el inicio o Ajustes (open cierra la ruta)
// [PA-H1-E5]. No pide permisos ni envía nada.

import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';

import '../../theme/aurora.dart';
import '../strings.dart';
import '../widgets/aurora_scaffold.dart';
import '../widgets/motion.dart';
import '../widgets/primary_button.dart';

/// Dibujo de cada consejo, en el mismo orden que context.strings.tips.
const _tipIcons = [
  Icons.wb_sunny_outlined, // buena luz
  Icons.crop_free, // toda la hoja, de frente
  Icons.collections_outlined, // una hoja por foto
  Icons.fact_check_outlined, // revisar lo resaltado
];

/// Consejos para una buena foto, uno por página.
class TipsScreen extends StatefulWidget {
  const TipsScreen({super.key, required this.onDone});

  /// Qué hacer al terminar o saltar los consejos.
  final VoidCallback onDone;

  /// [PA-H1-E5] Abre los consejos encima de la pantalla actual; al terminar o
  /// saltarlos, se vuelve a ella.
  static Future<void> open(BuildContext context) => Navigator.of(context).push(
    MaterialPageRoute<void>(
      builder: (routeContext) =>
          TipsScreen(onDone: () => Navigator.of(routeContext).pop()),
    ),
  );

  @override
  State<TipsScreen> createState() => _TipsScreenState();
}

class _TipsScreenState extends State<TipsScreen> {
  final _pages = PageController();
  int _page = 0;

  bool get _isLast => _page == context.strings.tips.length - 1;

  @override
  void dispose() {
    _pages.dispose();
    super.dispose();
  }

  /// [PA-H1-E2] Pasa al siguiente consejo o, en el último, termina.
  void _next() {
    if (_isLast) {
      widget.onDone();
      return;
    }
    // Sin animación si se pidió quitarlas (SC-207).
    final duration = motionDuration(context, const Duration(milliseconds: 300));
    if (duration == Duration.zero) {
      _pages.jumpToPage(_page + 1);
    } else {
      _pages.nextPage(duration: duration, curve: Curves.easeOutCubic);
    }
  }

  void _onPageChanged(int page) {
    setState(() => _page = page);
    // [PA-H2-E4] TalkBack lee el consejo nuevo sin mover el foco del botón.
    final (title, _) = context.strings.tips[page];
    SemanticsService.announce(
      '${context.strings.tipOf(page + 1, context.strings.tips.length)}. $title',
      Directionality.of(context),
    );
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final count = context.strings.tips.length;
    return AuroraScaffold(
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 8, 8, 0),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    context.strings.tipsLink,
                    style: textTheme.titleMedium?.copyWith(
                      color: Aurora.textSecondary,
                    ),
                  ),
                ),
                TextButton(
                  onPressed: widget.onDone, // [PA-H1-E3]
                  child: Text(context.strings.tipsSkip),
                ),
              ],
            ),
          ),
          Expanded(
            child: PageView(
              controller: _pages,
              onPageChanged: _onPageChanged,
              children: [
                for (final (index, (title, body))
                    in context.strings.tips.indexed)
                  _TipPage(
                    icon: _tipIcons[index],
                    step: context.strings.tipOf(index + 1, count),
                    title: title,
                    body: body,
                  ),
              ],
            ),
          ),
          // Los puntos repiten «Consejo 2 de 4»: TalkBack no los lee.
          ExcludeSemantics(
            child: _Dots(count: count, current: _page),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 16),
            child: PrimaryButton(
              label: _isLast
                  ? context.strings.tipsStart
                  : context.strings.tipsNext,
              icon: _isLast ? Icons.check : Icons.arrow_forward,
              onPressed: _next,
            ),
          ),
        ],
      ),
    );
  }
}

/// Un consejo: dibujo, «Consejo 2 de 4», título y texto. Con letra grande se desplaza
/// (spec 006, Historia 3).
class _TipPage extends StatelessWidget {
  const _TipPage({
    required this.icon,
    required this.step,
    required this.title,
    required this.body,
  });

  final IconData icon;
  final String step;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return LayoutBuilder(
      builder: (context, constraints) => SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
        child: ConstrainedBox(
          // Centrado cuando cabe; desplazable cuando no.
          constraints: BoxConstraints(minHeight: constraints.maxHeight - 32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ExcludeSemantics(
                child: Container(
                  width: 112,
                  height: 112,
                  decoration: BoxDecoration(
                    color: Aurora.iconBadge,
                    borderRadius: BorderRadius.circular(Aurora.radius),
                    border: Border.all(color: Aurora.surfaceBorder),
                  ),
                  child: Icon(icon, size: 56, color: Aurora.blueLight),
                ),
              ),
              const SizedBox(height: 32),
              Text(
                step,
                style: textTheme.labelLarge?.copyWith(color: Aurora.sky),
              ),
              const SizedBox(height: 8),
              Semantics(
                // Nodo propio: no se mezcla con los botones vecinos.
                container: true,
                header: true, // [PA-H2-E5]
                child: Text(
                  title,
                  textAlign: TextAlign.center,
                  style: textTheme.headlineSmall?.copyWith(color: Colors.white),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                body,
                textAlign: TextAlign.center,
                style: textTheme.bodyLarge?.copyWith(
                  color: Aurora.textSecondary,
                  height: 1.5,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Puntos de avance: el actual es más ancho y azul.
class _Dots extends StatelessWidget {
  const _Dots({required this.count, required this.current});

  final int count;
  final int current;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        for (var index = 0; index < count; index++)
          AnimatedContainer(
            duration: motionDuration(
              context,
              const Duration(milliseconds: 250),
            ),
            margin: const EdgeInsets.symmetric(horizontal: 4),
            width: index == current ? 24 : 8,
            height: 8,
            decoration: BoxDecoration(
              color: index == current ? Aurora.blueLight : Aurora.surfaceBorder,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
      ],
    );
  }
}
