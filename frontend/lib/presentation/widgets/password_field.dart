// Campo de contraseña con botón «mostrar/ocultar» (tarea T126; spec 002, módulo 1).
// Con [showStrength] muestra debajo una barra de seguridad (solo es una guía; la regla
// obligatoria es la longitud mínima de 8 caracteres).

import 'package:flutter/material.dart';

import '../../services/account_rules.dart';
import '../../theme/aurora.dart';
import '../strings.dart';

/// Campo de contraseña con un botón para mostrarla u ocultarla y, si se pide, una
/// barra de seguridad.
class PasswordField extends StatefulWidget {
  const PasswordField({
    super.key,
    required this.controller,
    required this.label,
    this.showStrength = false,
    this.autofillHints,
    this.textInputAction,
    this.onSubmitted,
  });

  /// Texto del campo.
  final TextEditingController controller;
  /// Etiqueta del campo (por ejemplo, «Contraseña»).
  final String label;
  /// Muestra la barra de seguridad debajo (en el registro).
  final bool showStrength;
  /// Pistas para que el gestor de contraseñas del teléfono la complete.
  final Iterable<String>? autofillHints;
  /// Botón del teclado: «siguiente» o «listo».
  final TextInputAction? textInputAction;
  /// Qué hacer al tocar ese botón del teclado.
  final ValueChanged<String>? onSubmitted;

  @override
  State<PasswordField> createState() => _PasswordFieldState();
}

class _PasswordFieldState extends State<PasswordField> {
  bool _obscured = true;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextField(
          controller: widget.controller,
          obscureText: _obscured,
          autocorrect: false,
          enableSuggestions: false,
          autofillHints: widget.autofillHints,
          textInputAction: widget.textInputAction,
          onSubmitted: widget.onSubmitted,
          decoration: InputDecoration(
            labelText: widget.label,
            hintText: widget.showStrength ? context.strings.passwordHint : null,
            prefixIcon: const Icon(Icons.lock_outline),
            suffixIcon: IconButton(
              tooltip: _obscured
                  ? context.strings.showPassword
                  : context.strings.hidePassword,
              icon: Icon(
                _obscured
                    ? Icons.visibility_outlined
                    : Icons.visibility_off_outlined,
              ),
              onPressed: () => setState(() => _obscured = !_obscured),
            ),
          ),
        ),
        if (widget.showStrength)
          ValueListenableBuilder<TextEditingValue>(
            valueListenable: widget.controller,
            builder: (context, value, _) => value.text.isEmpty
                ? const SizedBox.shrink()
                : _StrengthMeter(level: passwordStrength(value.text)),
          ),
      ],
    );
  }
}

/// Barra de tres segmentos: débil (rojo), aceptable (ámbar) o fuerte (verde).
class _StrengthMeter extends StatelessWidget {
  const _StrengthMeter({required this.level});

  final int level;

  @override
  Widget build(BuildContext context) {
    const colors = [Aurora.danger, Aurora.warning, Aurora.success];
    return Padding(
      padding: const EdgeInsets.only(top: 8, left: 4, right: 4),
      child: Row(
        children: [
          for (var i = 0; i < 3; i++) ...[
            Expanded(
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                height: 5,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(4),
                  color: i <= level ? colors[level] : Aurora.surfaceBorder,
                ),
              ),
            ),
            const SizedBox(width: 6),
          ],
          Text(
            context.strings.passwordStrength(level),
            style: Theme.of(
              context,
            ).textTheme.labelSmall?.copyWith(color: Aurora.textSecondary),
          ),
        ],
      ),
    );
  }
}
