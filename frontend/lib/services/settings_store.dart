// Almacén de los ajustes en el teléfono (tarea T402; spec 005; research.md de 005, R1).
//
// Un archivo settings.json en la carpeta privada de soporte de la app, con escritura
// atómica (como el borrador). No guarda datos personales ni documentos. Si el archivo
// falta o está dañado, se usan los valores por omisión [AV-H1-E6].
// Spec 006: el campo tipsSeen; si falta (ajustes de 005), vale false y los consejos se
// muestran una vez [PA-H1-E1].
// Spec 008: el campo language; si falta o es desconocido, español [IE-H1-E5].

import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;

import '../models/app_settings.dart';

/// Lo que el controlador necesita. Las pruebas usan una versión en memoria.
abstract interface class SettingsStore {
  Future<AppSettings> load();

  Future<void> save(AppSettings settings);
}

/// Convierte los ajustes a JSON:
/// `{"theme": "dark", "textSize": "large", "tipsSeen": true}`.
String encodeSettings(AppSettings settings) => jsonEncode({
  'theme': settings.theme.name,
  'textSize': settings.textSize.name,
  'tipsSeen': settings.tipsSeen,
  'language': settings.language.name,
  'appLock': settings.appLock,
});

/// Lee los ajustes. Un valor desconocido o un JSON dañado vuelven al valor por omisión.
AppSettings decodeSettings(String content) {
  Object? json;
  try {
    json = jsonDecode(content);
  } on FormatException {
    return const AppSettings();
  }
  if (json is! Map) return const AppSettings();
  T byName<T extends Enum>(List<T> values, Object? name, T fallback) =>
      values.where((value) => value.name == name).firstOrNull ?? fallback;
  return AppSettings(
    theme: byName(
      ThemePreference.values,
      json['theme'],
      ThemePreference.system,
    ),
    textSize: byName(
      EditorTextSize.values,
      json['textSize'],
      EditorTextSize.normal,
    ),
    tipsSeen: json['tipsSeen'] == true, // cualquier otro valor: no se vieron
    language: byName(AppLanguage.values, json['language'], AppLanguage.spanish),
    // Spec 011: cualquier valor que no sea true deja el bloqueo apagado.
    appLock: json['appLock'] == true,
  );
}

class FileSettingsStore implements SettingsStore {
  FileSettingsStore({required Future<Directory> Function() directory})
    : _directory = directory;

  static const fileName = 'settings.json';

  /// Carpeta privada de la app (getApplicationSupportDirectory en Android).
  final Future<Directory> Function() _directory;

  @override
  Future<AppSettings> load() async {
    final file = File(p.join((await _directory()).path, fileName));
    try {
      if (!await file.exists()) return const AppSettings();
      return decodeSettings(await file.readAsString());
    } on FileSystemException {
      return const AppSettings();
    }
  }

  @override
  Future<void> save(AppSettings settings) async {
    final folder = await _directory();
    await folder.create(recursive: true);
    // Escritura atómica: primero un temporal y luego se renombra.
    final temporary = File(p.join(folder.path, '$fileName.tmp'));
    await temporary.writeAsString(encodeSettings(settings), flush: true);
    await temporary.rename(p.join(folder.path, fileName));
  }
}
