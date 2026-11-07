// Pruebas de ajustes, versión y licencias (tareas T401 y T406; spec 005).
// Spec 006 (tarea T501): el aviso de que los consejos ya se vieron.

import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:handtext_ai/config/app_config.dart';
import 'package:handtext_ai/models/app_settings.dart';
import 'package:handtext_ai/presentation/font_licenses.dart';
import 'package:handtext_ai/services/settings_store.dart';
import 'package:handtext_ai/state/settings_controller.dart';
import 'package:path/path.dart' as p;

import '../support/fakes.dart';

void main() {
  group('FileSettingsStore', () {
    late Directory folder;

    setUp(() async {
      folder = await Directory.systemTemp.createTemp('handtext_ajustes_');
    });

    tearDown(() async {
      if (await folder.exists()) await folder.delete(recursive: true);
    });

    test('[AV-H1-E5] [SC-501] guarda y recupera los ajustes', () async {
      final store = FileSettingsStore(directory: () async => folder);
      const chosen = AppSettings(
        theme: ThemePreference.dark,
        textSize: EditorTextSize.extraLarge,
      );

      await store.save(chosen);
      final loaded = await FileSettingsStore(
        directory: () async => folder,
      ).load();

      expect(loaded.theme, ThemePreference.dark);
      expect(loaded.textSize, EditorTextSize.extraLarge);
      expect(
        File(p.join(folder.path, 'settings.json.tmp')).existsSync(),
        isFalse,
      );
    });

    test('[AV-H1-E6] sin archivo, se usan los valores por omisión', () async {
      final loaded = await FileSettingsStore(
        directory: () async => folder,
      ).load();

      expect(loaded.theme, ThemePreference.system);
      expect(loaded.textSize, EditorTextSize.normal);
    });

    test(
      '[AV-H1-E6] un archivo dañado o con valores desconocidos no rompe nada',
      () {
        expect(decodeSettings('no es json').theme, ThemePreference.system);
        final odd = decodeSettings('{"theme": "violeta", "textSize": "large"}');
        expect(odd.theme, ThemePreference.system);
        expect(odd.textSize, EditorTextSize.large);
      },
    );

    test(
      '[PA-H1-E4] [SC-601] recuerda que los consejos ya se vieron',
      () async {
        final store = FileSettingsStore(directory: () async => folder);

        await store.save(const AppSettings(tipsSeen: true));
        final loaded = await FileSettingsStore(
          directory: () async => folder,
        ).load();

        expect(loaded.tipsSeen, isTrue);
      },
    );

    test('[IE-H1-E4] [SC-804] guarda y recupera el idioma', () async {
      final store = FileSettingsStore(directory: () async => folder);

      await store.save(const AppSettings(language: AppLanguage.english));
      final loaded = await FileSettingsStore(
        directory: () async => folder,
      ).load();

      expect(loaded.language, AppLanguage.english);
    });

    test('[IE-H1-E1] [IE-H1-E5] sin idioma o con uno desconocido, español', () {
      expect(const AppSettings().language, AppLanguage.spanish);
      expect(
        decodeSettings('{"theme": "dark", "tipsSeen": true}').language,
        AppLanguage.spanish,
      );
      expect(
        decodeSettings('{"language": "klingon"}').language,
        AppLanguage.spanish,
      );
    });

    test(
      '[PA-H1-E1] los ajustes de 005, sin tipsSeen, muestran los consejos',
      () {
        final previous = decodeSettings(
          '{"theme": "dark", "textSize": "large"}',
        );

        expect(previous.tipsSeen, isFalse);
        expect(previous.theme, ThemePreference.dark); // lo demás se conserva
        expect(decodeSettings('{"tipsSeen": "sí"}').tipsSeen, isFalse);
      },
    );
  });

  group('SettingsController', () {
    test('[AV-H1-E2] [AV-H1-E4] cada cambio se aplica y se guarda', () async {
      final store = InMemorySettingsStore();
      final controller = SettingsController(store: store);
      var notified = 0;
      controller.addListener(() => notified++);

      await controller.setTheme(ThemePreference.light);
      await controller.setTextSize(EditorTextSize.large);

      expect(controller.settings.theme, ThemePreference.light);
      expect(store.stored.textSize, EditorTextSize.large);
      expect(store.saves, 2);
      expect(notified, 2);
    });

    test(
      '[PA-H1-E4] marcar los consejos como vistos conserva lo demás',
      () async {
        final store = InMemorySettingsStore()
          ..stored = const AppSettings(theme: ThemePreference.dark);
        final controller = SettingsController(store: store);
        await controller.load();

        await controller.markTipsSeen();

        expect(controller.settings.tipsSeen, isTrue);
        expect(store.stored.tipsSeen, isTrue);
        expect(store.stored.theme, ThemePreference.dark);
      },
    );

    test(
      '[PA-H1-E4] si no se puede guardar, no se repiten en esta sesión',
      () async {
        final controller = SettingsController(store: _FailingSettingsStore());

        await controller.markTipsSeen();

        expect(controller.settings.tipsSeen, isTrue);
      },
    );
  });

  test('[SC-502] la versión de «Acerca de» es la de pubspec.yaml', () {
    // Las pruebas se ejecutan desde la carpeta frontend.
    final pubspec = File('pubspec.yaml').readAsStringSync();
    final version = RegExp(
      r'^version:\s*(\S+)\+(\d+)',
      multiLine: true,
    ).firstMatch(pubspec)!;

    expect(AppConfig.appVersion, version.group(1));
    expect(AppConfig.appBuild, int.parse(version.group(2)!));
  });

  test('[SC-503] las licencias incluyen la de Poppins', () async {
    TestWidgetsFlutterBinding.ensureInitialized();
    registerFontLicenses();

    final packages = <String>{
      await for (final entry in LicenseRegistry.licenses) ...entry.packages,
    };

    expect(packages, contains('Poppins'));
  });
}

/// Almacén que no puede guardar (por ejemplo, teléfono sin espacio).
class _FailingSettingsStore implements SettingsStore {
  @override
  Future<AppSettings> load() async => const AppSettings();

  @override
  Future<void> save(AppSettings settings) async =>
      throw const FileSystemException('sin espacio');
}
