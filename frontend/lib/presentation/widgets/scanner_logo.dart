// Logo animado «hoja que se escanea» (tareas T111 y T142; spec 002, módulo 5).
//
// Se dibuja con CustomPainter (sin imágenes), con la forma de un ícono de app:
// 1. Un cuadrado redondeado azul corporativo con sombra.
// 2. Una hoja blanca con renglones «manuscritos» grises (el primero, más oscuro, es el
//    título).
// 3. Las cuatro esquinas del marco del escáner, en blanco.
// 4. Una línea de escaneo celeste que sube y baja despacio, con una estela suave.
// Es decorativo: se excluye de los lectores de pantalla. Si se pidieron menos
// animaciones, la línea queda quieta [SC-207].

import 'package:flutter/material.dart';

import '../../theme/aurora.dart';
import 'motion.dart';

/// Logo animado de la app: una hoja que se escanea.
class ScannerLogo extends StatefulWidget {
  const ScannerLogo({super.key, this.size = 128});

  /// Lado del logo, en píxeles lógicos (dp).
  final double size;

  @override
  State<ScannerLogo> createState() => _ScannerLogoState();
}

class _ScannerLogoState extends State<ScannerLogo>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 3200),
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    syncLoopingAnimation(context, _controller, reverse: true); // [SC-207]
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ExcludeSemantics(
      child: SizedBox.square(
        dimension: widget.size,
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, _) => CustomPaint(
            painter: _ScannerPainter(
              progress: Curves.easeInOut.transform(_controller.value),
            ),
          ),
        ),
      ),
    );
  }
}

class _ScannerPainter extends CustomPainter {
  _ScannerPainter({required this.progress});

  /// Posición de la línea de escaneo: 0 arriba, 1 abajo.
  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // 1. Ícono: cuadrado redondeado azul con sombra.
    final tile = RRect.fromRectAndRadius(
      Offset.zero & size,
      Radius.circular(w * 0.24),
    );
    canvas.drawRRect(
      tile.shift(Offset(0, h * 0.04)),
      Paint()
        ..color = Colors.black.withValues(alpha: 0.35)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12),
    );
    canvas.drawRRect(tile, Paint()..color = Aurora.blue);

    // 2. Hoja blanca con renglones.
    final page = RRect.fromRectAndRadius(
      Rect.fromLTWH(w * 0.30, h * 0.22, w * 0.40, h * 0.56),
      Radius.circular(w * 0.04),
    );
    canvas.drawRRect(page, Paint()..color = Colors.white);
    const widths = [0.55, 0.85, 0.70, 0.80, 0.50];
    final line = Paint()
      ..strokeCap = StrokeCap.round
      ..strokeWidth = h * 0.028;
    for (var i = 0; i < widths.length; i++) {
      final y = page.top + page.height * (0.18 + i * 0.16);
      final left = page.left + page.width * 0.16;
      line.color = i == 0 ? Aurora.backgroundBottom : Aurora.textMuted;
      canvas.drawLine(
        Offset(left, y),
        Offset(left + page.width * 0.68 * widths[i], y),
        line,
      );
    }

    // 3. Esquinas del marco del escáner alrededor de la hoja.
    final frame = Rect.fromLTWH(w * 0.20, h * 0.13, w * 0.60, h * 0.74);
    final corner = w * 0.10;
    final framePaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.9)
      ..style = PaintingStyle.stroke
      ..strokeWidth = w * 0.03
      ..strokeCap = StrokeCap.round;
    final corners = Path()
      ..moveTo(frame.left, frame.top + corner)
      ..lineTo(frame.left, frame.top)
      ..lineTo(frame.left + corner, frame.top)
      ..moveTo(frame.right - corner, frame.top)
      ..lineTo(frame.right, frame.top)
      ..lineTo(frame.right, frame.top + corner)
      ..moveTo(frame.right, frame.bottom - corner)
      ..lineTo(frame.right, frame.bottom)
      ..lineTo(frame.right - corner, frame.bottom)
      ..moveTo(frame.left + corner, frame.bottom)
      ..lineTo(frame.left, frame.bottom)
      ..lineTo(frame.left, frame.bottom - corner);
    canvas.drawPath(corners, framePaint);

    // 4. Línea de escaneo con estela suave, solo sobre la hoja.
    final y = page.top + page.height * progress;
    final trail = Rect.fromLTRB(page.left, y - h * 0.10, page.right, y);
    canvas.save();
    canvas.clipRRect(page);
    canvas.drawRect(
      trail,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Aurora.sky.withValues(alpha: 0),
            Aurora.sky.withValues(alpha: 0.25),
          ],
        ).createShader(trail),
    );
    canvas.restore();
    canvas.drawLine(
      Offset(frame.left + w * 0.04, y),
      Offset(frame.right - w * 0.04, y),
      Paint()
        ..color = Aurora.sky
        ..strokeWidth = w * 0.022
        ..strokeCap = StrokeCap.round,
    );
  }

  @override
  bool shouldRepaint(_ScannerPainter oldDelegate) =>
      oldDelegate.progress != progress;
}
