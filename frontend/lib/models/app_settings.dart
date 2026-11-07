// Ajustes de la app en este teléfono (tarea T402; spec 005, módulo 1; research.md de
// 005, R1 a R3).
// Spec 006 (tarea T502): también recuerda si ya se vieron los consejos para una buena
// foto (research.md de 006, R1).

/// Spec 008: idioma de la interfaz. El español es el inicial (constitución §4);
/// [system] sigue al teléfono (research.md de 008, R4 y R5).
enum AppLanguage { spanish, english, system }

/// Tema elegido: automático (según el teléfono), claro u oscuro.
enum ThemePreference { system, light, dark }

/// Tamaño de letra del editor. [scale] multiplica el tamaño normal y se suma al
/// tamaño de letra del sistema (supuesto 2 del spec).
enum EditorTextSize {
  /// Tamaño normal.
  normal(1.0),
  /// 20 % más grande.
  large(1.2),
  /// 40 % más grande.
  extraLarge(1.4);

  const EditorTextSize(this.scale);

  /// Factor que multiplica el tamaño normal de la letra del editor.
  final double scale;
}

/// Ajustes de la app en este teléfono: tema, tamaño de letra, idioma, consejos y
/// bloqueo.
///
/// Son del teléfono, no de la cuenta: valen para cualquier persona que ingrese en él.
/// Se guardan en un archivo JSON (FileSettingsStore). La clase es inmutable: para
/// cambiar un ajuste se crea una copia con [copyWith].
class AppSettings {
  const AppSettings({
    this.theme = ThemePreference.system,
    this.textSize = EditorTextSize.normal,
    this.tipsSeen = false,
    this.language = AppLanguage.spanish,
    this.appLock = false,
  });

  /// Tema: automático (como el teléfono), claro u oscuro.
  final ThemePreference theme;
  /// Tamaño de la letra en el editor.
  final EditorTextSize textSize;

  /// true cuando los consejos ya se vieron o se saltaron en este teléfono: ya no
  /// aparecen solos [PA-H1-E4].
  final bool tipsSeen;

  /// Spec 008: idioma elegido en Ajustes o en la bienvenida [IE-H1-E1].
  final AppLanguage language;

  /// Spec 011: bloquear la app con la huella, el rostro o el bloqueo de pantalla del
  /// teléfono. Apagado por omisión [BL-H1-E1] [SC-1104].
  final bool appLock;

  /// Copia de estos ajustes con los valores indicados; los demás no cambian.
  AppSettings copyWith({
    ThemePreference? theme,
    EditorTextSize? textSize,
    bool? tipsSeen,
    AppLanguage? language,
    bool? appLock,
  }) => AppSettings(
    theme: theme ?? this.theme,
    textSize: textSize ?? this.textSize,
    tipsSeen: tipsSeen ?? this.tipsSeen,
    language: language ?? this.language,
    appLock: appLock ?? this.appLock,
  );
}
