// Pantalla raíz del flujo de documentos (tareas T043 y T132).
//
// - Muestra la pantalla que corresponde al paso del controlador: inicio, vista previa
//   o editor (data-model.md, «Estados del flujo en la app»), con un desvanecimiento
//   suave entre pantallas (estilo Aurora; sin animación si se pidió reducirlas).
// - Maneja el botón «atrás» de Android: en la vista previa cancela la selección; en
//   el inicio vuelve al texto en edición, si lo hay; en el editor guarda el borrador
//   y sale.
// - [H1-E15] Cuando la app pasa a segundo plano, guarda el borrador de inmediato,
//   porque Android puede cerrarla en cualquier momento.

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../state/auth_controller.dart';
import '../../state/document_flow_controller.dart';
import '../widgets/motion.dart';
import 'editor_screen.dart';
import 'preview_screen.dart';
import 'start_screen.dart';

/// Muestra la pantalla del paso en que va el documento (inicio, vista previa o
/// editor) y maneja el botón «atrás» y el paso a segundo plano.
class FlowScreen extends StatefulWidget {
  const FlowScreen({super.key, required this.controller, required this.auth});

  /// El documento en curso: su paso decide qué pantalla se ve.
  final DocumentFlowController controller;
  /// Sesión, para el menú de la cuenta.
  final AuthController auth;

  @override
  State<FlowScreen> createState() => _FlowScreenState();
}

class _FlowScreenState extends State<FlowScreen> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.hidden ||
        state == AppLifecycleState.detached) {
      unawaited(widget.controller.flushDraft());
    }
  }

  /// Botón «atrás» de Android.
  Future<void> _handleBack() async {
    final controller = widget.controller;
    switch (controller.step) {
      case FlowStep.preview:
        await controller.cancelPreview();
      case FlowStep.start:
        controller.returnToDocument();
      case FlowStep.editor:
        await controller.flushDraft(); // el texto queda a salvo antes de salir
        await SystemNavigator.pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.controller,
      builder: (context, _) {
        final controller = widget.controller;
        if (!controller.isReady) {
          // Mientras se limpian las copias antiguas y se lee el borrador.
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        return PopScope(
          // Solo se deja salir directamente desde el inicio y sin documento abierto.
          canPop: controller.step == FlowStep.start && !controller.hasDocument,
          onPopInvokedWithResult: (didPop, _) {
            if (!didPop) unawaited(_handleBack());
          },
          child: AnimatedSwitcher(
            duration: motionDuration(
              context,
              const Duration(milliseconds: 350),
            ),
            child: switch (controller.step) {
              FlowStep.start => StartScreen(
                key: const ValueKey(FlowStep.start),
                controller: controller,
                auth: widget.auth,
              ),
              FlowStep.preview => PreviewScreen(
                key: const ValueKey(FlowStep.preview),
                controller: controller,
              ),
              FlowStep.editor => EditorScreen(
                key: const ValueKey(FlowStep.editor),
                controller: controller,
                auth: widget.auth,
              ),
            },
          ),
        );
      },
    );
  }
}
