// Prueba de punta a punta (tareas T1101 y T1102; spec 012; research.md de 012).
//
// Un robot recorre la app en el emulador, como una persona, contra la API y la base de
// datos reales: crea una cuenta, elige una hoja, autoriza el envío, corrige el texto,
// lo guarda como Word y lo vuelve a encontrar en Mis documentos después de cerrar e
// iniciar sesión.
//
// Lo único simulado (R2):
// - el reconocimiento, porque falta la clave de Google (T061 de 001);
// - el selector de fotos y el diálogo para guardar, que son pantallas de Android.
//
// Ejecutar (con la API local encendida y el emulador abierto):
//   flutter test integration_test -d emulator-5554 --dart-define=API_BASE_URL=http://10.0.2.2:8000/

import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:handtext_ai/app.dart';
import 'package:handtext_ai/config/app_config.dart';
import 'package:handtext_ai/models/export_format.dart';
import 'package:handtext_ai/models/image_format.dart';
import 'package:handtext_ai/models/operation_status.dart';
import 'package:handtext_ai/models/recognition_result.dart';
import 'package:handtext_ai/presentation/strings_es.dart';
import 'package:handtext_ai/services/auth_api_client.dart';
import 'package:handtext_ai/services/camera_permission_service.dart';
import 'package:handtext_ai/services/device_authenticator.dart';
import 'package:handtext_ai/services/document_scanner_service.dart';
import 'package:handtext_ai/services/draft_storage.dart';
import 'package:handtext_ai/services/file_save_service.dart';
import 'package:handtext_ai/services/handtext_api_client.dart';
import 'package:handtext_ai/services/history_store.dart';
import 'package:handtext_ai/services/image_editor_service.dart';
import 'package:handtext_ai/services/image_rules.dart';
import 'package:handtext_ai/services/image_source_service.dart';
import 'package:handtext_ai/services/session_store.dart';
import 'package:handtext_ai/services/settings_store.dart';
import 'package:handtext_ai/services/share_service.dart';
import 'package:handtext_ai/services/working_copy_service.dart';
import 'package:handtext_ai/state/app_lock_controller.dart';
import 'package:handtext_ai/state/auth_controller.dart';
import 'package:handtext_ai/state/document_flow_controller.dart';
import 'package:handtext_ai/state/document_history.dart';
import 'package:handtext_ai/state/settings_controller.dart';
import 'package:image_picker/image_picker.dart';
import 'package:integration_test/integration_test.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

const es = AppStringsEs();

/// Texto que «reconoce» la simulación, con una palabra dudosa («celula»).
const _recognizedText =
    'Apuntes de prueba\nLa celula es la unidad basica de la vida.';
const _corrected =
    'Apuntes de prueba\nLa célula es la unidad básica de la vida.';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('[PP-H1] [PP-H2] de la cuenta al Word, y volver a encontrarlo', (
    tester,
  ) async {
    final times = <String, Duration>{};
    final total = Stopwatch()..start();
    Future<void> step(String name, Future<void> Function() body) async {
      final watch = Stopwatch()..start();
      await body();
      times[name] = watch.elapsed;
    }

    // Las animaciones decorativas en bucle se quitan, como en las pruebas de widgets.
    tester.platformDispatcher.accessibilityFeaturesTestValue =
        const FakeAccessibilityFeatures(disableAnimations: true);

    // Carpetas propias de esta ejecución: los consejos aparecen como la primera vez.
    final support = await Directory(
      p.join((await getApplicationSupportDirectory()).path, 'e2e'),
    ).create(recursive: true);
    final saved = await Directory(
      p.join((await getTemporaryDirectory()).path, 'e2e_guardados'),
    ).create(recursive: true);
    await SecureSessionStore().clear(); // sin sesión de una ejecución anterior

    final page = await _syntheticPage();
    final saver = _PrivateFolderSaver(saved);
    final settings = SettingsController(
      store: FileSettingsStore(directory: () async => support),
    );
    await settings.load();
    final auth = AuthController(
      api: AuthApiClient(baseUrl: AppConfig.apiBaseUrl),
      sessions: SecureSessionStore(),
    );
    final realApi = HandTextApiClient(
      baseUrl: AppConfig.apiBaseUrl,
      tokenProvider: () => auth.token,
    );

    await tester.pumpWidget(
      HandTextApp(
        auth: auth,
        settings: settings,
        lock: AppLockController(
          settings: settings,
          auth: auth,
          authenticator: LocalDeviceAuthenticator(),
        ),
        createDocumentController: (user, onSessionExpired) =>
            DocumentFlowController(
              imageSource: _SyntheticPicker(page),
              cameraPermission: const HandlerCameraPermissionService(),
              readImageDimensions: readImageDimensionsWithEngine,
              workingCopies: WorkingCopyService(
                cacheDirectory: getTemporaryDirectory,
              ),
              api: _SimulatedRecognition(realApi),
              fileSaver: saver,
              drafts: FileDraftStore(
                directory: () async => support,
                fileName: draftFileNameFor(user.id),
              ),
              imageEditor: NativeImageEditor(title: () => es.imageEditorTitle),
              sharer: SystemDocumentSharer(
                cacheDirectory: getTemporaryDirectory,
              ),
              scanner: const MlKitDocumentScanner(),
              history: DocumentHistory(
                store: FileHistoryStore(
                  directory: () async => support,
                  fileName: historyFileNameFor(user.id),
                ),
              ),
              onSessionExpired: onSessionExpired,
            ),
      ),
    );

    final email = 'e2e${DateTime.now().millisecondsSinceEpoch}@correo.com';
    const password = 'clave-segura-e2e';

    // [PP-H1-E1] Cuenta nueva en la API real.
    await step('crear la cuenta', () async {
      await _waitFor(tester, find.text(es.createAccount));
      await _tap(tester, es.createAccount);
      await _type(tester, es.nameLabel, 'Robot de Prueba');
      await _type(tester, es.emailLabel, email);
      await _type(tester, es.passwordLabel, password);
      await _type(tester, es.confirmPasswordLabel, password);
      await _tap(tester, es.dataPolicyConsent);
      await _tap(tester, es.createAccount, last: true);
      await _waitFor(tester, find.text(es.tipsSkip));
      await _tap(tester, es.tipsSkip);
      await _waitFor(tester, find.text(es.greeting('Robot')));
    });

    // [PP-H1-E2] Hoja, autorización y editor con la palabra dudosa.
    await step('elegir la hoja y reconocer', () async {
      await _tap(tester, es.pickFromGallery);
      await _waitFor(tester, find.text(es.previewTitle));
      await _tap(tester, es.acceptAndRecognize);
      await _tap(tester, es.consentAccept);
      await _waitFor(tester, find.text(es.uncertainWordsCount(1)));
    });

    // [PP-H1-E3] Corregir y guardar como Word generado por la API.
    await step('corregir y guardar el Word', () async {
      await tester.enterText(find.byType(TextField), _corrected);
      await tester.pump();
      await _tap(tester, es.export);
      await _tap(tester, es.wordOption);
      await _waitFor(
        tester,
        find.text(
          es.statusText(
            const OperationStatus.success(
              StatusEvent.saved,
              format: ExportFormat.docx,
            ),
          ),
        ),
      );
    });

    // [SC-1202] Es un .docx real con el texto corregido.
    final file = saver.files.single;
    final bytes = await file.readAsBytes();
    expect(file.path, endsWith('Apuntes de prueba.docx')); // nombre de 010
    expect(bytes.sublist(0, 2), [0x50, 0x4B]); // «PK»: un .docx es un ZIP
    expect(_docxText(bytes), contains('La célula es la unidad básica'));

    // [PP-H1-E4] El documento está en Mis documentos.
    await step('encontrarlo en Mis documentos', () async {
      await tester.tap(find.byTooltip(es.moreActionsTooltip));
      await tester.pumpAndSettle();
      await _tap(tester, es.processAnotherImage);
      await _tap(tester, es.replaceTextConfirm);
      await _tap(tester, es.historyTitle);
      await _waitFor(tester, find.text('Apuntes de prueba'));
      await tester.tap(find.byTooltip(es.back));
      await tester.pumpAndSettle();
    });

    // [PP-H2-E1] Cerrar sesión, volver a entrar y encontrarlo.
    await step('cerrar sesión, volver y encontrarlo', () async {
      await _tapTooltip(tester, es.accountTooltip);
      await _tap(tester, es.signOut);
      await _waitFor(tester, find.text(es.haveAccount));
      await _tap(tester, es.haveAccount);
      await _type(tester, es.emailLabel, email);
      await _type(tester, es.passwordLabel, password);
      await _tap(tester, es.signIn, last: true);
      await _waitFor(tester, find.text(es.greeting('Robot')));
      await _tap(tester, es.historyTitle);
      await _waitFor(tester, find.text('Apuntes de prueba'));
    });

    // Limpieza: cerrar sesión y borrar las carpetas de la prueba.
    await tester.tap(find.byTooltip(es.back));
    await tester.pumpAndSettle();
    await _tapTooltip(tester, es.accountTooltip);
    await _tap(tester, es.signOut);
    await support.delete(recursive: true);
    await saved.delete(recursive: true);

    // [SC-1201] Tiempos de cada paso.
    for (final MapEntry(:key, :value) in times.entries) {
      debugPrint(
        'PASO $key: ${(value.inMilliseconds / 1000).toStringAsFixed(1)} s',
      );
    }
    debugPrint(
      'TOTAL: ${(total.elapsedMilliseconds / 1000).toStringAsFixed(1)} s',
    );
    expect(total.elapsed, lessThan(const Duration(minutes: 3)));
  });
}

/// Espera (con la red real) hasta que [finder] aparezca, como máximo [timeout].
Future<void> _waitFor(
  WidgetTester tester,
  Finder finder, {
  Duration timeout = const Duration(seconds: 30),
}) async {
  final end = DateTime.now().add(timeout);
  while (DateTime.now().isBefore(end)) {
    await tester.pump(const Duration(milliseconds: 200));
    if (finder.evaluate().isNotEmpty) return;
  }
  throw TestFailure('No apareció a tiempo: $finder (¿está encendida la API?)');
}

/// Toca el texto (desplazando si hace falta) y espera.
Future<void> _tap(WidgetTester tester, String text, {bool last = false}) async {
  final finder = find.text(text);
  if (finder.evaluate().isEmpty) {
    await tester.scrollUntilVisible(
      finder,
      200,
      scrollable: find.byType(Scrollable).first,
    );
  }
  final target = last ? finder.last : finder.first;
  await tester.ensureVisible(target);
  await tester.pumpAndSettle();
  await tester.tap(target);
  await tester.pump(const Duration(milliseconds: 300));
}

/// Toca el botón con el tooltip [tooltip]. Si quedó fuera de la pantalla (por
/// ejemplo, el botón «Cuenta» del inicio después de bajar hasta «Mis documentos»),
/// primero sube: la lista del inicio no conserva lo que no se ve.
Future<void> _tapTooltip(WidgetTester tester, String tooltip) async {
  final finder = find.byTooltip(tooltip);
  if (finder.evaluate().isEmpty) {
    await tester.scrollUntilVisible(
      finder,
      -200,
      scrollable: find.byType(Scrollable).first,
    );
  }
  await tester.ensureVisible(finder);
  await tester.pumpAndSettle();
  await tester.tap(finder);
  await tester.pumpAndSettle();
}

/// Escribe en el campo cuya etiqueta es [label].
Future<void> _type(WidgetTester tester, String label, String value) async {
  final field = find.widgetWithText(TextField, label);
  await tester.ensureVisible(field);
  await tester.enterText(field, value);
  await tester.pump();
}

/// R3: una hoja sintética de 1200 × 1600 px, blanca y con líneas, en PNG.
Future<Uint8List> _syntheticPage() async {
  final recorder = ui.PictureRecorder();
  final canvas = Canvas(recorder);
  canvas.drawRect(
    const Rect.fromLTWH(0, 0, 1200, 1600),
    Paint()..color = Colors.white,
  );
  final ink = Paint()
    ..color = Colors.black
    ..strokeWidth = 6;
  for (var line = 0; line < 12; line++) {
    final y = 200.0 + line * 100;
    canvas.drawLine(Offset(120, y), Offset(1080 - line * 30, y), ink);
  }
  final image = await recorder.endRecording().toImage(1200, 1600);
  final data = await image.toByteData(format: ui.ImageByteFormat.png);
  return data!.buffer.asUint8List();
}

/// Lee el texto de `word/document.xml` dentro del .docx (un ZIP).
String _docxText(Uint8List zip) {
  final data = ByteData.sublistView(zip);
  var offset = 0;
  while (offset + 30 <= zip.length &&
      data.getUint32(offset, Endian.little) == 0x04034b50) {
    final method = data.getUint16(offset + 8, Endian.little);
    final compressed = data.getUint32(offset + 18, Endian.little);
    final nameLength = data.getUint16(offset + 26, Endian.little);
    final extraLength = data.getUint16(offset + 28, Endian.little);
    final name = utf8.decode(
      zip.sublist(offset + 30, offset + 30 + nameLength),
    );
    final start = offset + 30 + nameLength + extraLength;
    final body = zip.sublist(start, start + compressed);
    if (name == 'word/document.xml') {
      final xml = method == 8 ? ZLibDecoder(raw: true).convert(body) : body;
      return utf8.decode(xml).replaceAll(RegExp('<[^>]+>'), '');
    }
    offset = start + compressed;
  }
  return '';
}

/// Selector de fotos de prueba: entrega la hoja sintética (R2).
class _SyntheticPicker implements ImageSourceService {
  _SyntheticPicker(this.page);

  final Uint8List page;

  XFile get _file =>
      XFile.fromData(page, name: 'hoja.png', mimeType: 'image/png');

  @override
  Future<XFile?> pickFromGallery() async => _file;

  @override
  Future<List<XFile>> pickMultipleFromGallery({required int limit}) async => [
    _file,
  ];

  @override
  Future<XFile?> takePhoto() async => _file;
}

/// Reconocimiento simulado (falta la clave de Google); exportar usa la API real (R2).
class _SimulatedRecognition implements HandTextApi {
  _SimulatedRecognition(this._real);

  final HandTextApi _real;

  @override
  Future<RecognitionResult> recognize(
    Uint8List imageBytes,
    ImageFormat format,
  ) async => const RecognitionResult(
    hasText: true,
    text: _recognizedText,
    uncertainRanges: [TextRange(start: 21, end: 27)], // «celula»
  );

  @override
  Future<Uint8List> export(String text, ExportFormat format) =>
      _real.export(text, format);
}

/// Diálogo para guardar de prueba: guarda en la carpeta privada de la app (R2).
class _PrivateFolderSaver implements FileSaver {
  _PrivateFolderSaver(this.folder);

  final Directory folder;
  final files = <File>[];

  @override
  Future<SaveOutcome> save({
    required Uint8List bytes,
    required String fileName,
  }) async {
    final file = File(p.join(folder.path, fileName));
    await file.writeAsBytes(bytes, flush: true);
    files.add(file);
    return const SaveCompleted();
  }
}
