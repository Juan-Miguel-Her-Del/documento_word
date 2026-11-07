// Versiones falsas de los servicios para las pruebas (tareas T025, T026, T045 y T119).
//
// Permiten probar toda la lógica y las pantallas sin cámara, sin red y sin tocar
// archivos reales. Constitución §6: las muestras son sintéticas (bytes inventados que
// solo imitan la firma de un PNG o un JPEG).

import 'dart:async';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:handtext_ai/models/app_failure.dart';
import 'package:handtext_ai/models/app_settings.dart';
import 'package:handtext_ai/models/document_draft.dart';
import 'package:handtext_ai/models/export_format.dart';
import 'package:handtext_ai/models/history_entry.dart';
import 'package:handtext_ai/models/image_format.dart';
import 'package:handtext_ai/models/picked_image.dart';
import 'package:handtext_ai/models/recognition_result.dart';
import 'package:handtext_ai/models/user_account.dart';
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

/// Firma de 8 bytes con la que empieza todo archivo PNG.
const _pngSignature = [0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A];

/// Bytes que empiezan con la firma de un PNG (no es una imagen completa).
Uint8List fakePngBytes() =>
    Uint8List.fromList([..._pngSignature, ...List.filled(64, 0)]);

/// Bytes que empiezan con la firma de un JPEG.
Uint8List fakeJpegBytes() =>
    Uint8List.fromList([0xFF, 0xD8, 0xFF, ...List.filled(64, 0)]);

/// Archivo «elegido» por el usuario, en memoria.
XFile pickedFile(Uint8List bytes) => XFile.fromData(bytes, name: 'apuntes.png');

/// Lector de dimensiones que siempre devuelve el tamaño indicado.
ImageDimensionsReader fixedDimensions(int width, int height) =>
    (bytes) async => ImageDimensions(width, height);

class FakeImageSource implements ImageSourceService {
  XFile? galleryResult;

  /// Spec 004: imágenes elegidas a la vez. Si es null, se usa [galleryResult].
  List<XFile>? galleryResults;
  XFile? cameraResult;
  AppFailure? cameraError;
  int galleryCalls = 0;
  int cameraCalls = 0;

  /// Límite que pidió el controlador en la última selección múltiple.
  int? lastLimit;

  @override
  Future<XFile?> pickFromGallery() async {
    galleryCalls++;
    return galleryResult;
  }

  @override
  Future<List<XFile>> pickMultipleFromGallery({required int limit}) async {
    galleryCalls++;
    lastLimit = limit;
    final single = galleryResult;
    return galleryResults ?? [?single];
  }

  @override
  Future<XFile?> takePhoto() async {
    cameraCalls++;
    final error = cameraError;
    if (error != null) throw error;
    return cameraResult;
  }
}

class FakeCameraPermission implements CameraPermissionService {
  CameraPermission result = CameraPermission.granted;
  int requests = 0;

  @override
  Future<CameraPermission> request() async {
    requests++;
    return result;
  }
}

class FakeApi implements HandTextApi {
  RecognitionResult recognitionResult = const RecognitionResult(
    hasText: true,
    text: 'Texto reconocido',
  );
  AppFailure? recognitionError;

  /// Si se asigna, el reconocimiento queda «en curso» hasta completarlo.
  Completer<void>? recognitionGate;
  final List<Uint8List> recognizedImages = [];

  Uint8List exportBytes = Uint8List.fromList([0x50, 0x4B, 0x03, 0x04]);
  AppFailure? exportError;
  final List<(String, ExportFormat)> exports = [];

  /// Spec 004: resultado según la imagen (si se asigna); si no, [recognitionResult].
  RecognitionResult Function(Uint8List imageBytes)? resultFor;

  /// Spec 004: falla solo con esta imagen (una vez), como un corte de red en una página.
  Uint8List? failOnceWith;

  @override
  Future<RecognitionResult> recognize(
    Uint8List imageBytes,
    ImageFormat format,
  ) async {
    recognizedImages.add(imageBytes);
    await recognitionGate?.future;
    final error = recognitionError;
    if (error != null) throw error;
    if (identical(imageBytes, failOnceWith)) {
      failOnceWith = null;
      throw const AppFailure(FailureKind.noConnection);
    }
    return resultFor?.call(imageBytes) ?? recognitionResult;
  }

  @override
  Future<Uint8List> export(String text, ExportFormat format) async {
    exports.add((text, format));
    final error = exportError;
    if (error != null) throw error;
    return exportBytes;
  }
}

class FakeFileSaver implements FileSaver {
  SaveOutcome outcome = const SaveCompleted();
  AppFailure? error;
  final List<String> savedNames = [];

  @override
  Future<SaveOutcome> save({
    required Uint8List bytes,
    required String fileName,
  }) async {
    final failure = error;
    if (failure != null) throw failure;
    savedNames.add(fileName);
    return outcome;
  }
}

class InMemoryDraftStore implements DraftStore {
  /// Texto del borrador (null si no hay).
  String? stored;

  /// Marcas guardadas con el borrador (spec 003).
  List<TextRange> storedRanges = const [];

  /// Entrada del historial guardada con el borrador (spec 007).
  String? storedHistoryId;
  int saves = 0;

  @override
  Future<DocumentDraft?> load() async {
    final text = stored;
    return text == null
        ? null
        : DocumentDraft(
            text,
            uncertainRanges: storedRanges,
            historyId: storedHistoryId,
          );
  }

  @override
  Future<void> save(DocumentDraft draft) async {
    saves++;
    stored = draft.text;
    storedRanges = draft.uncertainRanges;
    storedHistoryId = draft.historyId;
  }

  @override
  Future<void> delete() async {
    stored = null;
    storedRanges = const [];
    storedHistoryId = null;
  }
}

/// Editor de recorte falso (spec 003): devuelve [result] o lanza [error].
class FakeImageEditor implements ImageEditor {
  XFile? result;
  AppFailure? error;
  final List<WorkingCopy> edited = [];

  @override
  Future<XFile?> cropAndRotate(WorkingCopy copy, ImageFormat format) async {
    edited.add(copy);
    final failure = error;
    if (failure != null) throw failure;
    return result;
  }
}

/// Compartir falso (spec 003): anota lo que se compartió y las purgas.
class FakeDocumentSharer implements DocumentSharer {
  final List<(Uint8List, String, ExportFormat)> shared = [];
  AppFailure? error;
  int purges = 0;

  @override
  Future<void> share({
    required Uint8List bytes,
    required String fileName,
    required ExportFormat format,
  }) async {
    final failure = error;
    if (failure != null) throw failure;
    shared.add((bytes, fileName, format));
  }

  @override
  Future<void> purge() async => purges++;
}

class FakeWorkingCopyStore implements WorkingCopyStore {
  final List<WorkingCopy> created = [];
  final List<WorkingCopy> deleted = [];
  int purges = 0;

  @override
  Future<WorkingCopy> createFrom(XFile picked) async {
    final copy = WorkingCopy(
      path: 'copia_${created.length}',
      bytes: await picked.readAsBytes(),
    );
    created.add(copy);
    return copy;
  }

  @override
  Future<void> delete(WorkingCopy copy) async => deleted.add(copy);

  @override
  Future<void> purgeAll() async => purges++;
}

/// Ajustes en memoria (spec 005).
class InMemorySettingsStore implements SettingsStore {
  /// Por omisión, los consejos de 006 ya se vieron: las pruebas de 001 a 005 entran
  /// directo al inicio. Las de 006 empiezan con `tipsSeen: false`.
  AppSettings stored = const AppSettings(tipsSeen: true);
  int saves = 0;

  @override
  Future<AppSettings> load() async => stored;

  @override
  Future<void> save(AppSettings settings) async {
    saves++;
    stored = settings;
  }
}

// --- Cuentas (spec 002) -------------------------------------------------------------

/// Cuenta sintética de las pruebas.
const testUser = UserAccount(
  id: '0b6f2a3e-1111-4c4c-9a9a-123456789abc',
  displayName: 'Ana María',
  email: 'ana@correo.com',
);

class FakeAuthApi implements AuthApi {
  AppFailure? registerError;
  AppFailure? loginError;
  AppFailure? meError;
  AppFailure? deleteError;
  UserAccount user = testUser;
  final List<String> calls = [];

  @override
  Future<AuthResult> register({
    required String displayName,
    required String email,
    required String password,
    required bool acceptsDataPolicy,
  }) async {
    calls.add('register');
    final error = registerError;
    if (error != null) throw error;
    return AuthResult(token: 'token-nuevo', user: user);
  }

  @override
  Future<AuthResult> login({
    required String email,
    required String password,
  }) async {
    calls.add('login');
    final error = loginError;
    if (error != null) throw error;
    return AuthResult(token: 'token-nuevo', user: user);
  }

  @override
  Future<UserAccount> me(String token) async {
    calls.add('me');
    final error = meError;
    if (error != null) throw error;
    return user;
  }

  @override
  Future<void> logout(String token) async => calls.add('logout:$token');

  @override
  Future<void> deleteAccount(String token, String password) async {
    calls.add('delete');
    final error = deleteError;
    if (error != null) throw error;
  }
}

class InMemorySessionStore implements SessionStore {
  StoredSession? stored;

  @override
  Future<StoredSession?> read() async => stored;

  @override
  Future<void> save(StoredSession session) async => stored = session;

  @override
  Future<void> clear() async => stored = null;
}

/// Escáner falso (spec 009): devuelve [result] (null = canceló) o lanza [error].
class FakeDocumentScanner implements DocumentScannerService {
  List<XFile>? result;
  AppFailure? error;
  int calls = 0;
  int? lastPageLimit;

  @override
  Future<List<XFile>?> scan({required int pageLimit}) async {
    calls++;
    lastPageLimit = pageLimit;
    final failure = error;
    if (failure != null) throw failure;
    return result;
  }
}

/// Verificación del teléfono falsa (spec 011): [available] dice si el teléfono tiene
/// cómo verificar y [result], si la verificación es correcta.
class FakeDeviceAuthenticator implements DeviceAuthenticator {
  bool available = true;
  bool result = true;
  int calls = 0;

  @override
  Future<bool> isAvailable() async => available;

  @override
  Future<bool> authenticate(String reason) async {
    calls++;
    return result;
  }
}

/// Historial en memoria (spec 007). [failSaves] simula un teléfono sin espacio.
class InMemoryHistoryStore implements HistoryStore {
  List<HistoryEntry> stored = const [];
  int saves = 0;
  int deletes = 0;
  bool failSaves = false;

  @override
  Future<List<HistoryEntry>> load() async => stored;

  @override
  Future<void> save(List<HistoryEntry> entries) async {
    if (failSaves) throw const FileSystemException('sin espacio');
    saves++;
    stored = entries;
  }

  @override
  Future<void> delete() async {
    deletes++;
    stored = const [];
  }
}

/// Conjunto de dependencias falsas: una sesión (por defecto ya iniciada) y el
/// controlador de documentos, listos para probar.
class TestHarness {
  TestHarness({
    int imageWidth = 1200,
    int imageHeight = 1600,
    DateTime? now,
    bool signedIn = true,
    ImageDimensionsReader? readDimensions,
  }) : _readImageDimensions =
           readDimensions ?? fixedDimensions(imageWidth, imageHeight),
       _now = now ?? DateTime(2026, 10, 26, 15, 30) {
    if (signedIn) {
      sessions.stored = const StoredSession(
        token: 'token-guardado',
        user: testUser,
      );
    }
    auth = AuthController(api: authApi, sessions: sessions);
    imageSource.galleryResult = pickedFile(fakePngBytes());
    imageSource.cameraResult = pickedFile(fakeJpegBytes());
  }

  final ImageDimensionsReader _readImageDimensions;
  final DateTime _now;

  final imageSource = FakeImageSource();
  final cameraPermission = FakeCameraPermission();
  final workingCopies = FakeWorkingCopyStore();
  final api = FakeApi();
  final fileSaver = FakeFileSaver();
  final drafts = InMemoryDraftStore();
  final imageEditor = FakeImageEditor();
  final sharer = FakeDocumentSharer();
  final scanner = FakeDocumentScanner();
  final authApi = FakeAuthApi();
  final sessions = InMemorySessionStore();
  final settingsStore = InMemorySettingsStore();
  final historyStore = InMemoryHistoryStore();
  late final settings = SettingsController(store: settingsStore);

  /// Spec 011: verificación falsa y reloj que las pruebas adelantan.
  final authenticator = FakeDeviceAuthenticator();
  DateTime clock = DateTime(2026, 11, 5, 10);

  /// Se crea después de leer los ajustes (pumpHandTextApp), como en main.dart.
  late final lock = AppLockController(
    settings: settings,
    auth: auth,
    authenticator: authenticator,
    now: () => clock,
  );
  late final AuthController auth;

  /// Veces que el controlador de documentos avisó «sesión vencida».
  int sessionExpiredCalls = 0;

  DocumentFlowController? _controller;

  /// Controlador de documentos (se crea la primera vez que se pide).
  DocumentFlowController get controller =>
      _controller ?? buildController(testUser, () => sessionExpiredCalls++);

  /// Fábrica que usa la app de prueba (HandTextApp) para cada sesión.
  DocumentFlowController buildController(
    UserAccount user,
    VoidCallback onSessionExpired,
  ) {
    return _controller = DocumentFlowController(
      imageSource: imageSource,
      cameraPermission: cameraPermission,
      readImageDimensions: _readImageDimensions,
      workingCopies: workingCopies,
      api: api,
      fileSaver: fileSaver,
      drafts: drafts,
      imageEditor: imageEditor,
      sharer: sharer,
      scanner: scanner,
      history: DocumentHistory(store: historyStore),
      onSessionExpired: onSessionExpired,
      now: () => _now,
      draftSaveDelay: Duration.zero,
    );
  }

  /// Lleva el flujo hasta el editor con [text] reconocido y, si se indican, sus
  /// palabras dudosas (spec 003).
  Future<void> reachEditor({
    String text = 'Texto reconocido',
    List<TextRange> uncertain = const [],
  }) async {
    api.recognitionResult = RecognitionResult(
      hasText: true,
      text: text,
      uncertainRanges: uncertain,
    );
    await controller.initialize();
    await controller.pickFromGallery();
    await controller.recognize(consentGranted: true);
  }
}
