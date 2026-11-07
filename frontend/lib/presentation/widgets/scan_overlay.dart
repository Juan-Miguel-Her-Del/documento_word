// Animación de escaneo sobre la imagen mientras la IA lee (tareas T134 y T142; CU-H3-E2).
//
// Oscurece levemente la imagen y la recorre con una línea celeste y su estela suave.
// Si se pidieron menos animaciones, la línea queda quieta [SC-207].

import 'package:flutter/material.dart';

import '../../theme/aurora.dart';
import 'motion.dart';

/// Línea de escaneo que recorre la imagen mientras se reconoce el texto.
class ScanOverlay extends StatefulWidget {
  const ScanOverlay({super.key});

  @override
  State<ScanOverlay> createState() => _ScanOverlayState();
}

class _ScanOverlayState extends State<ScanOverlay>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1800),
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    syncLoopingAnimation(context, _controller, reverse: true, stillValue: 0.5);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) => CustomPaint(
          size: Size.infinite,
          painter: _ScanPainter(
            progress: Curves.easeInOut.transform(_controller.value),
          ),
        ),
      ),
    );
  }
}

class _ScanPainter extends CustomPainter {
  _ScanPainter({required this.progress});

  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    final area = Offset.zero & size;
    // Velo oscuro para que la línea destaque.
    canvas.drawRect(
      area,
      Paint()..color = Aurora.backgroundTop.withValues(alpha: 0.30),
    );

    final y = size.height * progress;
    final trail = Rect.fromLTRB(0, y - size.height * 0.18, size.width, y);
    canvas.drawRect(
      trail,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Aurora.sky.withValues(alpha: 0),
            Aurora.sky.withValues(alpha: 0.28),
          ],
        ).createShader(trail),
    );
    canvas.drawLine(
      Offset(0, y),
      Offset(size.width, y),
      Paint()
        ..color = Aurora.sky
        ..strokeWidth = 2.5,
    );
  }

  @override
  bool shouldRepaint(_ScanPainter oldDelegate) =>
      oldDelegate.progress != progress;
}
