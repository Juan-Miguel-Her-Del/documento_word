// Pantalla de Ajustes (tarea T404; spec 005, Historia 1).
//
// - Tema: automático, claro u oscuro [AV-H1-E2] [AV-H1-E3].
// - Letra del editor: normal, grande o muy grande, con una muestra [AV-H1-E4].
// Cada cambio se aplica al instante y se guarda en el teléfono [AV-H1-E5].
// Spec 006: acceso a los consejos para una buena foto [PA-H1-E5]. Con la letra grande,
// las opciones se muestran una debajo de otra para no partir palabras [PA-H3-E1].
// Spec 008 (tarea T706): el idioma de la app [IE-H1-E2].
// Spec 011 (tarea T1003): bloquear con huella o rostro [BL-H1-E1] a [BL-H1-E4].

import 'package:flutter/material.dart';

import '../../models/app_settings.dart';
import '../../theme/aurora.dart';
import '../app_lock_scope.dart';
import '../settings_scope.dart';
import '../strings.dart';
import '../widgets/action_tile.dart';
import '../widgets/aurora_header.dart';
import '../widgets/aurora_scaffold.dart';
import '../widgets/language_sheet.dart';
import '../widgets/surface_card.dart';
import 'tips_screen.dart';

/// Pantalla de Ajustes: tema, tamaño de letra, idioma, consejos y bloqueo con
/// huella. Cada cambio se aplica al instante y queda guardado en el teléfono.
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = SettingsScope.of(context);
    final settings = controller.settings;
    final textTheme = Theme.of(context).textTheme;
    final sectionStyle = textTheme.titleMedium?.copyWith(color: Colors.white);
    final hintStyle = textTheme.bodySmall?.copyWith(
      color: Aurora.textSecondary,
    );

    return AuroraScaffold(
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AuroraHeader(title: context.strings.settingsTitle),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
              children: [
                // [IE-H1-E2] Idioma: Español, English o el del teléfono.
                SurfaceCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        context.strings.languageSection,
                        style: sectionStyle,
                      ),
                      const SizedBox(height: 12),
                      _OptionGroup<AppLanguage>(
                        options: languageOptions(context.strings),
                        selected: settings.language,
                        onSelected: controller.setLanguage,
                      ),
                      const SizedBox(height: 10),
                      Text(context.strings.languageHint, style: hintStyle),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                SurfaceCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(context.strings.themeSection, style: sectionStyle),
                      const SizedBox(height: 12),
                      _OptionGroup<ThemePreference>(
                        options: [
                          (ThemePreference.system, context.strings.themeSystem),
                          (ThemePreference.light, context.strings.themeLight),
                          (ThemePreference.dark, context.strings.themeDark),
                        ],
                        selected: settings.theme,
                        onSelected: controller.setTheme,
                      ),
                      const SizedBox(height: 10),
                      Text(context.strings.themeHint, style: hintStyle),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                SurfaceCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        context.strings.textSizeSection,
                        style: sectionStyle,
                      ),
                      const SizedBox(height: 12),
                      _OptionGroup<EditorTextSize>(
                        options: [
                          (
                            EditorTextSize.normal,
                            context.strings.textSizeNormal,
                          ),
                          (EditorTextSize.large, context.strings.textSizeLarge),
                          (
                            EditorTextSize.extraLarge,
                            context.strings.textSizeExtraLarge,
                          ),
                        ],
                        selected: settings.textSize,
                        onSelected: controller.setTextSize,
                      ),
                      const SizedBox(height: 14),
                      // Muestra con el tamaño elegido, como se verá en el editor.
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: Aurora.fieldFill,
                          borderRadius: BorderRadius.circular(
                            Aurora.radiusSmall,
                          ),
                          border: Border.all(color: Aurora.surfaceBorder),
                        ),
                        child: Text(
                          context.strings.textSizePreview,
                          style: editorTextStyle(
                            context,
                            settings.textSize,
                          )?.copyWith(color: Colors.white),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                const _AppLockCard(), // spec 011
                const SizedBox(height: 16),
                ActionTile(
                  icon: Icons.lightbulb_outline,
                  title: context.strings.tipsLink,
                  subtitle: context.strings.tipsLinkHint,
                  onTap: () => TipsScreen.open(context),
                ),
                const SizedBox(height: 16),
                Text(
                  context.strings.settingsSavedHint,
                  textAlign: TextAlign.center,
                  style: hintStyle,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Opciones de un ajuste (spec 006; research.md de 006, R10).
///
/// Con la letra normal son botones segmentados. Si alguna opción no cabe en una línea
/// de su segmento (por ejemplo, con la letra del sistema al 200 %, «Autom-ático»), se
/// muestran una debajo de otra, con la elegida marcada [PA-H3-E1].
class _OptionGroup<T> extends StatelessWidget {
  const _OptionGroup({
    required this.options,
    required this.selected,
    required this.onSelected,
  });

  /// Valor y texto de cada opción, en orden.
  final List<(T, String)> options;
  final T selected;
  final ValueChanged<T> onSelected;

  /// Margen horizontal de cada segmento (TextButton de Material 3: 12 dp por lado con
  /// la letra normal; con la letra grande es menor, así que la cuenta es prudente).
  static const _segmentInsets = 2 * 12.0;

  /// ¿Cada texto cabe en una línea dentro de su segmento, con la letra actual?
  bool _fitsInSegments(BuildContext context, double width) {
    final style = Theme.of(context).textTheme.labelLarge;
    final scaler = MediaQuery.textScalerOf(context);
    final available = width / options.length - _segmentInsets;
    return options.every((option) {
      final painter = TextPainter(
        text: TextSpan(text: option.$2, style: style),
        textDirection: Directionality.of(context),
        textScaler: scaler,
        maxLines: 1,
      )..layout();
      final fits = painter.width <= available;
      painter.dispose();
      return fits;
    });
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (_fitsInSegments(context, constraints.maxWidth)) {
          return SegmentedButton<T>(
            segments: [
              for (final (value, label) in options)
                ButtonSegment(value: value, label: Text(label)),
            ],
            selected: {selected},
            showSelectedIcon: false,
            onSelectionChanged: (selection) => onSelected(selection.single),
          );
        }
        return Column(
          children: [
            for (final (value, label) in options)
              // TalkBack lo lee como un botón de opción: «Oscuro, marcado».
              MergeSemantics(
                child: Semantics(
                  inMutuallyExclusiveGroup: true,
                  checked: value == selected,
                  child: ListTile(
                    contentPadding: EdgeInsets.zero,
                    selected: value == selected,
                    textColor: Aurora.textPrimary,
                    iconColor: Aurora.textMuted,
                    selectedColor: Aurora.blueLight,
                    leading: Icon(
                      value == selected
                          ? Icons.radio_button_checked
                          : Icons.radio_button_unchecked,
                    ),
                    title: Text(label),
                    onTap: () => onSelected(value),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}

/// Spec 011: interruptor del bloqueo con huella o rostro.
/// - Apagado por omisión [BL-H1-E1]; activarlo pide la verificación [BL-H1-E2], y
///   cancelarla lo deja apagado [BL-H1-E3].
/// - Si el teléfono no tiene cómo verificar, lo explica y no se puede activar
///   [BL-H1-E4].
class _AppLockCard extends StatefulWidget {
  const _AppLockCard();

  @override
  State<_AppLockCard> createState() => _AppLockCardState();
}

class _AppLockCardState extends State<_AppLockCard> {
  /// Se pregunta una sola vez al abrir Ajustes.
  late final Future<bool> _available = AppLockScope.of(
    context,
  ).authenticator.isAvailable();

  @override
  Widget build(BuildContext context) {
    final lock = AppLockScope.of(context);
    final enabled = SettingsScope.of(context).settings.appLock;
    final strings = context.strings;
    return FutureBuilder<bool>(
      future: _available,
      builder: (context, snapshot) {
        final available = snapshot.data ?? false;
        return SurfaceCard(
          child: SwitchListTile(
            contentPadding: EdgeInsets.zero,
            value: enabled,
            secondary: const Icon(Icons.fingerprint, color: Aurora.blueLight),
            title: Text(
              strings.appLockTitle,
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(color: Colors.white),
            ),
            subtitle: Text(
              available || enabled
                  ? strings.appLockHint
                  : strings.appLockUnavailable,
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: Aurora.textSecondary),
            ),
            onChanged: !available && !enabled
                ? null
                : (value) => value
                      ? lock.enable(strings.enableLockReason)
                      : lock.disable(),
          ),
        );
      },
    );
  }
}

/// Estilo del texto del editor con el tamaño elegido (R3). Lo usan el editor y la
/// muestra de Ajustes, así siempre coinciden.
TextStyle? editorTextStyle(BuildContext context, EditorTextSize size) {
  final base = Theme.of(context).textTheme.bodyLarge;
  return base?.copyWith(
    height: 1.5,
    fontSize: (base.fontSize ?? 16) * size.scale,
  );
}
