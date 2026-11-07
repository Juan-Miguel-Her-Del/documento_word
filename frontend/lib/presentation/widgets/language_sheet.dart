// Elegir el idioma de la app (tarea T706; spec 008, Historia 1; research.md de 008, R9).
//
// - languageOptions: las tres opciones, en el mismo orden en Ajustes y en la hoja.
// - LanguageButton: botón de la bienvenida con el ícono de idioma y el idioma actual;
//   abre la hoja para elegirlo antes de crear la cuenta [IE-H1-E2].
// Los nombres «Español» y «English» se escriben siempre en su propio idioma, para que
// se reconozcan aunque no se entienda la app.

import 'package:flutter/material.dart';

import '../../models/app_settings.dart';
import '../settings_scope.dart';
import '../strings.dart';

/// Las tres opciones de idioma: valor y nombre.
List<(AppLanguage, String)> languageOptions(AppStrings strings) => [
  (AppLanguage.spanish, AppStrings.spanishName),
  (AppLanguage.english, AppStrings.englishName),
  (AppLanguage.system, strings.languageSystem),
];

/// [IE-H1-E2] Hoja con las tres opciones; elegir una la aplica al instante y cierra.
Future<void> showLanguageSheet(
  BuildContext context,
) => showModalBottomSheet<void>(
  context: context,
  showDragHandle: true,
  // Con la letra grande, la hoja crece y se desplaza (spec 006).
  isScrollControlled: true,
  builder: (sheetContext) {
    final settings = SettingsScope.of(sheetContext);
    final strings = sheetContext.strings;
    final textTheme = Theme.of(sheetContext).textTheme;
    final selected = settings.settings.language;
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Semantics(
              container: true,
              header: true,
              child: Text(strings.languageSection, style: textTheme.titleLarge),
            ),
            const SizedBox(height: 8),
            for (final (value, label) in languageOptions(strings))
              // TalkBack lo lee como un botón de opción: «English, marcado».
              MergeSemantics(
                child: Semantics(
                  inMutuallyExclusiveGroup: true,
                  checked: value == selected,
                  child: ListTile(
                    contentPadding: EdgeInsets.zero,
                    selected: value == selected,
                    leading: Icon(
                      value == selected
                          ? Icons.radio_button_checked
                          : Icons.radio_button_unchecked,
                    ),
                    title: Text(label),
                    onTap: () {
                      settings.setLanguage(value);
                      Navigator.of(sheetContext).pop();
                    },
                  ),
                ),
              ),
            const SizedBox(height: 8),
            Text(strings.languageHint, style: textTheme.bodySmall),
          ],
        ),
      ),
    );
  },
);

/// Botón de idioma de la bienvenida: muestra el idioma en que se ve la app.
class LanguageButton extends StatelessWidget {
  const LanguageButton({super.key});

  @override
  Widget build(BuildContext context) {
    final current = Localizations.localeOf(context).languageCode == 'en'
        ? AppStrings.englishName
        : AppStrings.spanishName;
    return Tooltip(
      message: context.strings.languageTooltip,
      child: TextButton.icon(
        onPressed: () => showLanguageSheet(context),
        icon: const Icon(Icons.translate),
        label: Text(current),
      ),
    );
  }
}
