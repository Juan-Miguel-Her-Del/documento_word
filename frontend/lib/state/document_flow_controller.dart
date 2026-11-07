// Controlador del flujo completo de HandText AI (tareas T041 y T047).
//
// Es el «cerebro» de la app: decide qué pantalla se ve (inicio, vista previa o editor),
// llama a los servicios y publica un estado (OperationStatus) que las pantallas
// muestran. No contiene widgets: la lógica está separada de la interfaz
// (constitución §2 y §4).
//
// Las reglas del spec se marcan con etiquetas para encontrarlas rápido:
// [H1-E9] = Historia 1, escenario 9; [SC-007] = criterio de éxito 7.
// - Autorización antes de cada envío; sin ella no se envía nada (H1-E3, H1-E4, SC-004).
// - Una sola operación a la vez: los toques repetidos no duplican nada (H1-E5, SC-008).
// - Un fallo nunca borra las correcciones (H1-E8, H1-E12, H1-E13, SC-003).
// - Se exporta el texto actual del editor (H1-E9), nunca uno vacío (H1-E10, SC-007).
// - El borrador se guarda, se recupera y se elimina según el spec (H1-E15 a H1-E17).
// - Cámara con permiso y opción de repetir la captura (Historia 2).
// - Spec 002: si la API rechaza la sesión, guarda el borrador y avisa (CU-H2-E5); al
//   cerrar sesión o eliminar la cuenta, borra los datos locales (CU-H2-E2, CU-H2-E3).
// - Spec 003 (tareas T209, T212 y T215):
//   - marca las palabras dudosas y ajusta las marcas al editar (EX-H1);
//   - recorta y gira la imagen sobre una copia y permite volver a la original (EX-H2);
//   - ofrece «Compartir» después de guardar (EX-H3).
// - Spec 004 (tareas T306, T308 y T310): la vista previa tiene de 1 a 10 páginas, que se
//   ordenan, se recortan y se reconocen una por una, sin reenviar las ya leídas (VP).
// - Spec 009 (tarea T803): el escáner de documentos es otro origen de imágenes, por el
//   mismo camino que la galería y la cámara (ED).
// - Spec 010 (tarea T902): el nombre propuesto al guardar es el título del documento
//   (OR).
// - Spec 007 (tareas T605, T609 y T611): cada guardado correcto queda en el historial de
//   la cuenta, sin duplicar el mismo documento; un documento del historial se abre en
//   el editor; eliminar la cuenta borra el historial (HD).

import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';

import '../config/app_config.dart';
import '../models/app_failure.dart';
import '../models/document_draft.dart';
import '../models/document_page.dart';
import '../models/export_format.dart';
import '../models/exported_document.dart';
import '../models/history_entry.dart';
import '../models/operation_status.dart';
import '../models/picked_image.dart';
import '../services/camera_permission_service.dart';
import '../services/document_scanner_service.dart';
import '../services/draft_storage.dart';
import '../services/file_save_service.dart';
import '../services/handtext_api_client.dart';
import '../services/image_editor_service.dart';
import '../services/image_rules.dart';
import '../services/image_source_service.dart';
import '../services/page_join.dart';
import '../services/share_service.dart';
import '../services/uncertain_ranges.dart';
import '../services/working_copy_service.dart';
import 'document_history.dart';

/// Pantallas del flujo (data-model.md, «Estados del flujo en la app»).
enum FlowStep { start, preview, editor }

/// Qué hacer con las imágenes elegidas (spec 004).
enum _AddMode { newDocument, append, replaceSelected }

/// Nombre que se propone al guardar: «HandText_20261026_1530.docx» (research.md, R6).
///
/// Spec 010 (research.md de 010, R1): con [title], se propone el título limpio
/// («Apuntes de biología.docx») [OR-H1-E1]; si no queda nada útil, el nombre de
/// siempre [OR-H1-E3].
String suggestedFileName(
  ExportFormat format,
  DateTime moment, {
  String? title,
}) {
  final name = _cleanFileName(title ?? '');
  if (name.isNotEmpty) return '$name.${format.extension}';
  String twoDigits(int value) => value.toString().padLeft(2, '0');
  final date =
      '${moment.year}${twoDigits(moment.month)}${twoDigits(moment.day)}';
  final time = '${twoDigits(moment.hour)}${twoDigits(moment.minute)}';
  return 'HandText_${date}_$time.${format.extension}';
}

/// [OR-H1-E2] [SC-1001] Quita lo que Android no acepta en un nombre de archivo
/// (`/ \ : * ? " < > |` y caracteres de control), junta los espacios, corta en 60
/// caracteres y quita los puntos y espacios del final.
String _cleanFileName(String title) {
  var name = title
      .replaceAll(RegExp(r'[\\/:*?"<>|]'), '')
      .replaceAll(RegExp(r'[\x00-\x1F\x7F]'), ' ')
      .replaceAll(RegExp(r'\s+'), ' ')
      .trim();
  final characters = name.runes.toList();
  if (characters.length > 60) {
    name = String.fromCharCodes(characters.take(60));
  }
  return name.replaceAll(RegExp(r'[.\s]+$'), '');
}

class DocumentFlowController extends ChangeNotifier {
  DocumentFlowController({
    required ImageSourceService imageSource,
    required CameraPermissionService cameraPermission,
    required ImageDimensionsReader readImageDimensions,
    required WorkingCopyStore workingCopies,
    required HandTextApi api,
    required FileSaver fileSaver,
    required DraftStore drafts,
    required ImageEditor imageEditor,
    required DocumentSharer sharer,
    required DocumentScannerService scanner,
    required DocumentHistory history,
    VoidCallback? onSessionExpired,
    DateTime Function() now = DateTime.now,
    Duration draftSaveDelay = AppConfig.draftSaveDelay,
  }) : _imageSource = imageSource,
       _cameraPermission = cameraPermission,
       _readImageDimensions = readImageDimensions,
       _workingCopies = workingCopies,
       _api = api,
       _fileSaver = fileSaver,
       _drafts = drafts,
       _imageEditor = imageEditor,
       _sharer = sharer,
       _scanner = scanner,
       _history = history,
       _onSessionExpired = onSessionExpired,
       _now = now,
       _draftSaveDelay = draftSaveDelay;

  // Servicios que se reciben desde main.dart (o versiones falsas en las pruebas).
  final ImageSourceService _imageSource;
  final CameraPermissionService _cameraPermission;
  final ImageDimensionsReader _readImageDimensions;
  final WorkingCopyStore _workingCopies;
  final HandTextApi _api;
  final FileSaver _fileSaver;
  final DraftStore _drafts;
  final ImageEditor _imageEditor;
  final DocumentSharer _sharer;

  /// Spec 009: escáner de documentos de Google ML Kit.
  final DocumentScannerService _scanner;

  /// Spec 007: historial «Mis documentos» de esta cuenta.
  final DocumentHistory _history;

  /// Spec 002: avisa a AuthController que la API rechazó la sesión (401).
  final VoidCallback? _onSessionExpired;
  final DateTime Function() _now;
  final Duration _draftSaveDelay;

  FlowStep _step = FlowStep.start;

  /// Spec 004: páginas de la vista previa, en orden, y la que se ve en grande.
  List<DocumentPage> _pages = const [];
  int _selectedPage = 0;
  String? _documentText;
  List<TextRange> _uncertainRanges = const [];
  ExportedDocument? _lastExport;

  /// Spec 007: entrada del historial del documento en edición; null si todavía no se
  /// guardó (research.md de 007, R3).
  String? _historyId;
  bool _hasUnexportedChanges = false;
  bool _isBusy = false;
  bool _isReady = false;
  OperationStatus? _status;
  Timer? _draftTimer;
  Future<void> _draftQueue = Future<void>.value();
  bool _isDisposed = false;

  /// Pantalla que se debe mostrar.
  FlowStep get step => _step;

  /// Spec 004: páginas de la vista previa, en el orden del documento.
  List<DocumentPage> get pages => _pages;

  /// Spec 004: página que se ve en grande (desde 0).
  int get selectedPageIndex => _selectedPage;

  /// Imagen de la página que se ve en grande (null si no hay ninguna). Con una sola
  /// página es la imagen de 001.
  PickedImage? get pendingImage =>
      _pages.isEmpty ? null : _pages[_selectedPage].image;

  /// [VP-H1-E6] Todavía caben páginas (máximo 10).
  bool get canAddPages => _pages.length < AppConfig.maxPages;

  /// [VP-H1-E3] [SC-402] Páginas que se enviarán al reconocer: las que todavía no
  /// tienen resultado.
  int get pagesToSend => _pages.where((page) => page.result == null).length;

  /// Texto del documento en edición: la «versión confirmada» que se exporta
  /// (supuesto 1 del spec). Es null si no hay documento.
  String? get documentText => _documentText;

  /// Indica si hay un documento en edición (aunque se esté eligiendo otra imagen).
  bool get hasDocument => _documentText != null;

  /// Spec 003: palabras dudosas que quedan por revisar, en posiciones de
  /// [documentText]. Nunca cambian el texto ni se exportan.
  List<TextRange> get uncertainRanges => _uncertainRanges;

  /// Spec 003: la página elegida se recortó y se puede volver a la original
  /// [EX-H2-E5].
  bool get canRestoreOriginalImage =>
      _pages.isNotEmpty && _pages[_selectedPage].original != null;

  /// Hay texto que todavía no se exportó (spec 002: se avisa antes de cerrar sesión).
  bool get hasUnexportedChanges => hasDocument && _hasUnexportedChanges;

  /// [SC-008] Hay una operación en curso; mientras tanto, las acciones se ignoran.
  bool get isBusy => _isBusy;

  /// La limpieza inicial y la lectura del borrador ya terminaron.
  bool get isReady => _isReady;

  /// Aviso visible (en curso, éxito, información o fallo).
  OperationStatus? get status => _status;

  /// Spec 007: historial «Mis documentos» de esta cuenta.
  DocumentHistory get history => _history;

  // ---------------------------------------------------------------------------
  // Arranque
  // ---------------------------------------------------------------------------

  /// Prepara la app al abrirla:
  /// 1. Borra las copias de trabajo que quedaron de una sesión anterior (retención).
  /// 2. [H1-E15] Si hay un borrador con cambios no exportados, abre el editor con él.
  Future<void> initialize() async {
    try {
      await _workingCopies.purgeAll();
      await _sharer.purge(); // [EX-H3-E5] copias para compartir de otra sesión
    } on Exception catch (error) {
      debugPrint('No se limpiaron los temporales: ${error.runtimeType}');
    }

    await _history.load(); // [HD-H1-E5]

    DocumentDraft? draft;
    try {
      draft = await _drafts.load();
    } on Exception {
      draft = null;
    }
    if (draft != null && draft.text.trim().isNotEmpty) {
      _documentText = draft.text;
      // [EX-H1-E7] Las marcas que quedaban vuelven con el borrador.
      _uncertainRanges = validRanges(draft.text, draft.uncertainRanges);
      // [HD-H2-E4] Un borrador abierto desde el historial sigue unido a su entrada.
      _historyId = draft.historyId;
      _step = FlowStep.editor;
      _status = const OperationStatus.info(StatusEvent.draftRestored);
    }
    _isReady = true;
    _notify();
  }

  // ---------------------------------------------------------------------------
  // Selección de la imagen (spec, módulo 1)
  // ---------------------------------------------------------------------------

  /// Historia 1 (y spec 004): elegir una o varias imágenes guardadas en el teléfono.
  /// Empieza un documento nuevo.
  Future<void> pickFromGallery() =>
      _addImages(ImageOrigin.gallery, _AddMode.newDocument);

  /// Historia 2: tomar una fotografía (pide el permiso de cámara si hace falta).
  /// Empieza un documento nuevo.
  Future<void> takePhoto() =>
      _addImages(ImageOrigin.camera, _AddMode.newDocument);

  /// [ED-H1-E2] [ED-H1-E3] Spec 009: escanear una o varias hojas. Empieza un documento
  /// nuevo.
  Future<void> scanDocument() =>
      _addImages(ImageOrigin.scanner, _AddMode.newDocument);

  /// [VP-H1-E2] Agrega páginas al final, desde la galería o la cámara.
  Future<void> addPages(ImageOrigin origin) =>
      _addImages(origin, _AddMode.append);

  /// Reemplaza la página que se ve en grande: elige otra o repite la captura [H2-E3],
  /// según de dónde vino [VP-H2-E4].
  Future<void> replaceImage() => _addImages(
    pendingImage?.origin ?? ImageOrigin.gallery,
    _pages.isEmpty ? _AddMode.newDocument : _AddMode.replaceSelected,
  );

  Future<void> _addImages(ImageOrigin origin, _AddMode mode) async {
    if (_isBusy) return; // [SC-008]
    // Cuántas páginas caben en esta selección [VP-H1-E6].
    final room = switch (mode) {
      _AddMode.newDocument => AppConfig.maxPages,
      _AddMode.replaceSelected => 1,
      _AddMode.append => AppConfig.maxPages - _pages.length,
    };
    if (room <= 0) {
      _status = const OperationStatus.failure(
        AppFailure(FailureKind.tooManyPages),
      );
      _notify();
      return;
    }
    _isBusy = true;
    _notify();
    try {
      if (origin == ImageOrigin.camera) {
        // [H2-E1] [H2-E2] Sin permiso no se abre la cámara y se explica el motivo.
        final permission = await _cameraPermission.request();
        if (permission != CameraPermission.granted) {
          _status = OperationStatus.failure(
            AppFailure(
              permission == CameraPermission.permanentlyDenied
                  ? FailureKind.cameraPermissionPermanentlyDenied
                  : FailureKind.cameraPermissionDenied,
            ),
          );
          return;
        }
      }

      final List<XFile> picked;
      if (origin == ImageOrigin.camera) {
        final photo = await _imageSource.takePhoto();
        picked = [?photo];
      } else if (origin == ImageOrigin.scanner) {
        // [ED-H1-E3] Spec 009: solo las hojas que caben; cancelar no cambia nada
        // [ED-H1-E5] [SC-903].
        picked = await _scanner.scan(pageLimit: room) ?? const [];
      } else if (mode == _AddMode.replaceSelected) {
        final image = await _imageSource.pickFromGallery();
        picked = [?image];
      } else {
        // [VP-H1-E1] Varias imágenes a la vez, solo las que caben.
        picked = await _imageSource.pickMultipleFromGallery(limit: room);
      }
      if (picked.isEmpty) return; // el usuario cerró el selector: nada cambia

      // Constitución §3: desde aquí solo se trabaja con copias de trabajo.
      final added = <DocumentPage>[];
      AppFailure? firstFailure;
      for (final (index, file) in picked.indexed) {
        if (index >= room) {
          // Caso límite: el selector devolvió de más. La copia se crea y se borra
          // para no dejar en la caché el archivo intermedio del selector.
          await _deleteQuietly(await _workingCopies.createFrom(file));
          firstFailure ??= const AppFailure(FailureKind.tooManyPages);
          continue;
        }
        try {
          added.add(DocumentPage(await _createImage(file, origin)));
        } on AppFailure catch (failure) {
          firstFailure ??=
              failure; // [VP-H1-E7] esta no se agrega; las demás sí
        }
      }
      if (added.isEmpty) {
        throw firstFailure ?? const AppFailure(FailureKind.imageUnreadable);
      }

      switch (mode) {
        case _AddMode.newDocument:
          await _discardImages();
          _pages = added;
          _selectedPage = 0;
        case _AddMode.append:
          _selectedPage = _pages.length; // se ve la primera página nueva
          _pages = [..._pages, ...added];
        case _AddMode.replaceSelected:
          final replaced = _pages[_selectedPage];
          _pages = [..._pages]..[_selectedPage] = added.single;
          await _deletePage(replaced);
      }
      _step = FlowStep.preview;
      _status = firstFailure == null
          ? null
          : OperationStatus.failure(firstFailure);
    } on AppFailure catch (failure) {
      // [ED-H2-E1] [SC-904] Sin escáner, el aviso ofrece tomar una fotografía.
      _status = OperationStatus.failure(
        failure,
        action: failure.kind == FailureKind.scannerUnavailable
            ? StatusAction.takePhoto
            : null,
      );
    } on Exception {
      _status = const OperationStatus.failure(
        AppFailure(FailureKind.imageUnreadable),
      );
    } finally {
      _isBusy = false;
      _notify();
    }
  }

  /// Crea la copia de trabajo de [file] y la valida. Si no cumple las reglas, borra
  /// la copia y lanza el motivo.
  Future<PickedImage> _createImage(XFile file, ImageOrigin origin) async {
    final copy = await _workingCopies.createFrom(file);
    final ImageCheck check;
    try {
      // [H1-E1] Formato por contenido, tamaño y dimensiones del spec.
      check = await validateSelectedImage(
        copy.bytes,
        readDimensions: _readImageDimensions,
      );
    } on AppFailure {
      await _deleteQuietly(copy);
      rethrow;
    }
    return PickedImage(
      workingCopy: copy,
      format: check.format,
      width: check.width,
      height: check.height,
      origin: origin,
    );
  }

  /// [VP-H2-E1] Muestra en grande la página [index].
  void selectPage(int index) {
    if (_isBusy || index < 0 || index >= _pages.length) return;
    _selectedPage = index;
    _notify();
  }

  /// [VP-H2-E2] Mueve la página elegida [offset] lugares: −1 antes, +1 después. Su
  /// resultado se conserva: el texto se une en el orden nuevo.
  void moveSelectedPage(int offset) {
    final target = _selectedPage + offset;
    if (_isBusy || target < 0 || target >= _pages.length) return;
    final pages = [..._pages];
    pages.insert(target, pages.removeAt(_selectedPage));
    _pages = pages;
    _selectedPage = target;
    _notify();
  }

  /// [VP-H2-E3] Quita la página elegida y borra su copia. Con una sola página no se
  /// ofrece: se usa «Cancelar» [VP-H2-E5].
  Future<void> removeSelectedPage() async {
    if (_isBusy || _pages.length < 2) return;
    final removed = _pages[_selectedPage];
    _pages = [..._pages]..removeAt(_selectedPage);
    _selectedPage = math.min(_selectedPage, _pages.length - 1);
    _status = null;
    _notify();
    await _deletePage(removed);
  }

  /// Cancela la selección: borra las copias de trabajo y vuelve al inicio.
  Future<void> cancelPreview() async {
    if (_isBusy) return;
    _step = FlowStep.start;
    _status = null;
    _notify();
    await _discardImages();
  }

  // ---------------------------------------------------------------------------
  // Recorte y giro (spec 003, módulo 2)
  // ---------------------------------------------------------------------------

  /// [EX-H2-E1] Abre el editor de recorte con la página que se ve en grande.
  Future<void> editImage() async {
    if (_pages.isEmpty || _isBusy) return; // [SC-008]
    final index = _selectedPage;
    final page = _pages[index];
    final image = page.image;
    _isBusy = true;
    _notify();
    try {
      final edited = await _imageEditor.cropAndRotate(
        image.workingCopy,
        image.format,
      );
      if (edited == null) return; // [EX-H2-E3] canceló: nada cambia

      // [EX-H2-E4] Las mismas reglas de 001: si no las cumple, se conserva la imagen
      // anterior y se explica el motivo. WorkingCopyService borra el archivo de uCrop.
      final croppedImage = await _createImage(edited, image.origin);

      // La primera vez se guarda la imagen tal como se eligió [EX-H2-E5]; un recorte
      // intermedio ya no se necesita. El resultado se borra: la imagen cambió
      // [VP-H3-E3].
      final original = page.original ?? image;
      if (page.original != null) await _deleteQuietly(image.workingCopy);
      _pages = [..._pages]
        ..[index] = DocumentPage(croppedImage, original: original);
      _status = null;
    } on AppFailure catch (failure) {
      _status = OperationStatus.failure(failure);
    } on Exception {
      _status = const OperationStatus.failure(
        AppFailure(FailureKind.imageEditFailed),
      );
    } finally {
      _isBusy = false;
      _notify();
    }
  }

  /// [EX-H2-E5] Vuelve a la imagen tal como se eligió y borra el recorte.
  Future<void> restoreOriginalImage() async {
    if (_pages.isEmpty || _isBusy) return;
    final page = _pages[_selectedPage];
    final original = page.original;
    if (original == null) return;
    _pages = [..._pages]..[_selectedPage] = DocumentPage(original);
    _status = null;
    _notify();
    await _deleteQuietly(page.image.workingCopy);
  }

  // ---------------------------------------------------------------------------
  // Reconocimiento (spec, módulo 2)
  // ---------------------------------------------------------------------------

  /// Envía la imagen a reconocer. La pantalla pregunta antes al usuario y pasa su
  /// respuesta en [consentGranted].
  Future<void> recognize({required bool consentGranted}) async {
    if (_pages.isEmpty || _isBusy) return; // [H1-E5] [SC-008]

    if (!consentGranted) {
      // [H1-E4] [SC-004] Sin autorización no se llama a la API.
      _status = const OperationStatus.info(StatusEvent.consentDeclined);
      _notify();
      return;
    }

    _isBusy = true;
    final total = _pages.length;
    try {
      // Spec 004: una página por vez, en orden [VP-H1-E4] [SC-405].
      for (var i = 0; i < _pages.length; i++) {
        final page = _pages[i];
        // [SC-402] Ya reconocida: no se reenvía.
        if (page.result != null) continue;
        _selectedPage = i; // la animación de escaneo se ve sobre esta página
        _status = OperationStatus.inProgress(
          StatusEvent.recognizing,
          page: i + 1,
          pageCount: total,
        );
        _notify();
        final result = await _api.recognize(
          page.image.bytes,
          page.image.format,
        );
        _pages = [..._pages]..[i] = page.withResult(result);
      }

      // [VP-H1-E5] [SC-401] El texto de las páginas se une en orden.
      final joined = joinPages([for (final page in _pages) page.result!]);
      if (!joined.hasText) {
        // [H1-E7] [H2-E5] [VP-H3-E5] Sin texto: aviso y opción de otra imagen.
        _status = const OperationStatus.noTextFound();
        return;
      }
      // [H1-E13] El nuevo texto reemplaza al anterior solo ahora, cuando el
      // reconocimiento terminó bien (la confirmación se pidió en el editor).
      _documentText = joined.text;
      // [EX-H1-E1] [SC-404] Las marcas del texto anterior se reemplazan por las
      // nuevas, ya ubicadas en el texto unido.
      _uncertainRanges = joined.uncertainRanges;
      _lastExport = null;
      _historyId = null; // spec 007: es un documento nuevo
      _hasUnexportedChanges = true;
      _step = FlowStep.editor;
      // [H1-E6] El editor muestra además la advertencia de posibles errores;
      // [VP-H3-E4] el aviso dice qué páginas no tenían texto.
      _status = OperationStatus.success(
        StatusEvent.recognized,
        emptyPages: joined.emptyPages,
      );
      await _discardImages(); // retención: ya no se necesitan [SC-304] [SC-403]
      await _saveDraftNow();
    } on AppFailure catch (failure) {
      await _handleSessionExpiry(failure);
      // [H1-E8] El fallo se explica y se ofrece reintentar; si había un texto en
      // edición, no se toca [H1-E13]. [VP-H3-E1] Con varias páginas, dice cuál falló;
      // las ya reconocidas conservan su resultado.
      _status = OperationStatus.failure(
        failure,
        action: failure.isRetryable
            ? StatusAction.retryRecognition
            : StatusAction.replaceImage,
        page: total > 1 ? _selectedPage + 1 : null,
        pageCount: total > 1 ? total : null,
      );
    } on Exception {
      _status = const OperationStatus.failure(
        AppFailure(FailureKind.unexpected),
        action: StatusAction.retryRecognition,
      );
    } finally {
      _isBusy = false;
      _notify();
    }
  }

  // ---------------------------------------------------------------------------
  // Edición (spec, módulo 3)
  // ---------------------------------------------------------------------------

  /// Recibe cada cambio del editor. Conserva todos los caracteres escritos por el
  /// usuario y programa el guardado del borrador [H1-E15].
  void updateText(String text) {
    final before = _documentText;
    if (before == null || before == text) return;
    _documentText = text;
    _hasUnexportedChanges = true;
    // [EX-H3-E6] El archivo guardado ya no coincide con el texto: no se comparte.
    _lastExport = null;
    // [EX-H1-E4] [SC-302] Las marcas siguen a sus palabras; si se editó una palabra
    // marcada, su marca desaparece.
    final ranges = adjustRanges(before, text, _uncertainRanges);
    final rangesChanged = !listEquals(ranges, _uncertainRanges);
    _uncertainRanges = ranges;
    _scheduleDraftSave();
    // Un aviso anterior (por ejemplo, «Texto reconocido») ya no aplica.
    final status = _status;
    final clearStatus = status != null && status.kind != StatusKind.inProgress;
    if (clearStatus) _status = null;
    if (clearStatus || rangesChanged) _notify();
  }

  /// [EX-H1-E5] «Está bien»: la persona revisó [range] y no necesita cambios. Quita
  /// la marca sin tocar el texto.
  void acceptUncertainWord(TextRange range) {
    if (!_uncertainRanges.contains(range)) return;
    _uncertainRanges = [
      for (final other in _uncertainRanges)
        if (other != range) other,
    ];
    _hasUnexportedChanges = true;
    _scheduleDraftSave();
    _notify();
  }

  /// «Procesar otra imagen»: la pantalla ya pidió confirmación. El texto actual se
  /// conserva hasta que un nuevo reconocimiento termine bien [H1-E13].
  void startAnotherImage() {
    if (_isBusy || !hasDocument) return;
    _step = FlowStep.start;
    _status = null;
    _lastExport = null;
    _notify();
  }

  /// Vuelve al editor con el texto que se estaba editando.
  void returnToDocument() {
    if (_isBusy || !hasDocument) return;
    _step = FlowStep.editor;
    _status = null;
    _notify();
  }

  /// [H1-E17] Descarta el texto y su borrador (la pantalla ya pidió confirmación).
  Future<void> discardDocument() async {
    if (_isBusy || !hasDocument) return;
    _draftTimer?.cancel();
    _documentText = null;
    _uncertainRanges = const [];
    _lastExport = null;
    _historyId = null;
    _hasUnexportedChanges = false;
    _step = FlowStep.start;
    _status = const OperationStatus.info(StatusEvent.discarded);
    _notify();
    await _enqueueDraftWork(_drafts.delete); // [SC-011]
  }

  // ---------------------------------------------------------------------------
  // Exportación y guardado (spec, módulo 4)
  // ---------------------------------------------------------------------------

  /// Genera el archivo en la API y lo guarda con el diálogo del sistema.
  Future<void> export(ExportFormat format) async {
    // [H1-E9] La versión confirmada es el texto del editor en este momento.
    final text = _documentText;
    if (text == null || _isBusy) return; // [SC-008]

    if (text.trim().isEmpty) {
      // [H1-E10] [SC-007] Ni siquiera se llama a la API.
      _status = const OperationStatus.failure(
        AppFailure(FailureKind.emptyText),
      );
      _notify();
      return;
    }

    _isBusy = true;
    _lastExport = null;
    _status = OperationStatus.inProgress(StatusEvent.exporting, format: format);
    _notify();
    try {
      // [SC-303] Se exporta solo el texto: las marcas nunca viajan a la API.
      final bytes = await _api.export(text, format);
      // Spec 010: el título del documento como nombre [OR-H1-E1] [OR-H1-E4].
      final fileName = suggestedFileName(
        format,
        _now(),
        title: _titleFor(text),
      );
      final outcome = await _fileSaver.save(bytes: bytes, fileName: fileName);
      switch (outcome) {
        case SaveCompleted():
          // [EX-H3-E1] El aviso de éxito ofrece «Compartir» este mismo archivo.
          _lastExport = ExportedDocument(
            bytes: bytes,
            fileName: fileName,
            format: format,
          );
          _status = OperationStatus.success(
            StatusEvent.saved,
            format: format,
            action: StatusAction.shareExport,
          );
          // [HD-H1-E1] [HD-H1-E2] [HD-H2-E3] [SC-701] Solo un guardado correcto llega
          // al historial; volver a guardar el mismo documento actualiza su entrada.
          _historyId = await _history.record(
            id: _historyId,
            text: text,
            format: format,
            savedAt: _now(),
          );
          if (_documentText == text) {
            // [H1-E16] [SC-011] Exportado y sin cambios posteriores: se borra el
            // borrador. Si el usuario vuelve a editar, se guarda de nuevo.
            _hasUnexportedChanges = false;
            _draftTimer?.cancel();
            await _enqueueDraftWork(_drafts.delete);
          }
        case SaveCancelled():
          // Cancelar el diálogo no es un éxito ni un error; el texto sigue igual.
          _status = const OperationStatus.info(StatusEvent.saveCancelled);
      }
    } on AppFailure catch (failure) {
      await _handleSessionExpiry(failure);
      // [H1-E12] [SC-003] Nunca se anuncia éxito y el texto se conserva.
      _status = OperationStatus.failure(failure);
    } on Exception {
      _status = const OperationStatus.failure(
        AppFailure(FailureKind.exportFailed),
      );
    } finally {
      _isBusy = false;
      _notify();
    }
  }

  // ---------------------------------------------------------------------------
  // Historial (spec 007, módulo 2)
  // ---------------------------------------------------------------------------

  /// Spec 010: el título del documento para el nombre del archivo: el que se le dio en
  /// Mis documentos o, si no, su primera línea con texto [OR-H1-E4].
  String _titleFor(String text) {
    final entry = _history.entries
        .where((entry) => entry.id == _historyId)
        .firstOrNull;
    return entry != null && entry.renamed ? entry.title : historyTitleFor(text);
  }

  /// [HD-H2-E1] Abre un documento del historial en el editor (la pantalla ya pidió
  /// confirmación si había cambios sin exportar [HD-H2-E2]). Queda como documento
  /// guardado, sin cambios por exportar y sin marcas: ya se revisó (R7).
  Future<void> openFromHistory(HistoryEntry entry) async {
    if (_isBusy) return; // [SC-008]
    _draftTimer?.cancel();
    _documentText = entry.text;
    _uncertainRanges = const [];
    _lastExport = null;
    _historyId = entry.id; // [HD-H2-E3] al guardarlo, se actualiza esta entrada
    _hasUnexportedChanges = false;
    _step = FlowStep.editor;
    _status = const OperationStatus.info(StatusEvent.historyOpened);
    _notify();
    await _discardImages(); // retención: como al empezar cualquier documento
    // El texto anterior ya se reemplazó: su borrador se borra.
    await _enqueueDraftWork(_drafts.delete);
  }

  // ---------------------------------------------------------------------------
  // Compartir (spec 003, módulo 3)
  // ---------------------------------------------------------------------------

  /// [EX-H3-E2] Abre el selector de Android con el archivo recién guardado.
  Future<void> shareLastExport() async {
    final document = _lastExport;
    if (document == null || _isBusy) return; // [SC-008]
    _isBusy = true;
    _notify();
    try {
      await _sharer.share(
        bytes: document.bytes,
        fileName: document.fileName,
        format: document.format,
      );
      // [EX-H3-E3] Haya elegido una app o cerrado el selector, el aviso sigue igual y
      // se puede volver a compartir.
    } on AppFailure catch (failure) {
      _status = OperationStatus.failure(
        failure,
        action: StatusAction.shareExport,
      );
    } finally {
      _isBusy = false;
      _notify();
    }
  }

  // ---------------------------------------------------------------------------
  // Borrador (Clarifications 2026-10-26; research.md, R7)
  // ---------------------------------------------------------------------------

  /// Guarda ya el borrador pendiente. La app lo llama al pasar a segundo plano,
  /// porque Android puede cerrarla en cualquier momento [H1-E15].
  Future<void> flushDraft() {
    _draftTimer?.cancel();
    return _persistDraft();
  }

  /// Espera unos milisegundos tras la última tecla para no escribir en cada letra.
  void _scheduleDraftSave() {
    _draftTimer?.cancel();
    _draftTimer = Timer(_draftSaveDelay, () => unawaited(_persistDraft()));
  }

  Future<void> _saveDraftNow() {
    _draftTimer?.cancel();
    return _persistDraft();
  }

  Future<void> _persistDraft() => _enqueueDraftWork(() async {
    final text = _documentText;
    if (text == null || !_hasUnexportedChanges) return;
    // [EX-H1-E7] Las marcas pendientes se guardan junto con el texto.
    await _drafts.save(
      DocumentDraft(
        text,
        uncertainRanges: _uncertainRanges,
        historyId: _historyId, // [HD-H2-E4]
      ),
    );
  });

  /// Ejecuta las operaciones del borrador una tras otra (nunca en paralelo).
  Future<void> _enqueueDraftWork(Future<void> Function() work) {
    final next = _draftQueue.then((_) => work()).catchError((Object error) {
      // Si falla (por ejemplo, sin espacio), la edición continúa: el texto
      // sigue en memoria. Solo se anota el tipo de error, nunca el contenido.
      debugPrint('No se pudo actualizar el borrador: ${error.runtimeType}');
    });
    _draftQueue = next;
    return next;
  }

  // ---------------------------------------------------------------------------
  // Sesión (spec 002)
  // ---------------------------------------------------------------------------

  /// [CU-H2-E2] [CU-H2-E3] Borra los datos locales de esta cuenta: borrador, copias de
  /// trabajo y, desde 003, la copia para compartir. Se llama al cerrar sesión con
  /// confirmación o al eliminar la cuenta.
  ///
  /// Spec 007: [deleteHistory] también borra el historial; solo al eliminar la cuenta
  /// [HD-H3-E4]. Al cerrar sesión se conserva [HD-H1-E5].
  Future<void> clearLocalData({bool deleteHistory = false}) async {
    _draftTimer?.cancel();
    _documentText = null;
    _uncertainRanges = const [];
    _lastExport = null;
    _historyId = null;
    _hasUnexportedChanges = false;
    _step = FlowStep.start;
    _status = null;
    _notify();
    await _enqueueDraftWork(_drafts.delete);
    await _discardImages();
    if (deleteHistory) await _history.clear(); // [SC-704]
    try {
      await _sharer.purge(); // [EX-H3-E5]
    } on Exception {
      // Se volverá a intentar al abrir la app.
    }
  }

  /// [CU-H2-E5] Si la API rechazó la sesión, primero se guarda el borrador (para que
  /// la misma persona lo recupere al volver a ingresar) y luego se avisa a la sesión.
  Future<void> _handleSessionExpiry(AppFailure failure) async {
    if (failure.kind != FailureKind.sessionExpired) return;
    await flushDraft();
    _onSessionExpired?.call();
  }

  // ---------------------------------------------------------------------------
  // Utilidades
  // ---------------------------------------------------------------------------

  /// Borra las copias de todas las páginas (y de sus originales recortadas)
  /// [SC-403].
  Future<void> _discardImages() async {
    final pages = _pages;
    _pages = const [];
    _selectedPage = 0;
    for (final page in pages) {
      await _deletePage(page);
    }
  }

  /// Borra la copia de una página y, si se recortó, también su original.
  Future<void> _deletePage(DocumentPage page) async {
    await _deleteQuietly(page.image.workingCopy);
    final original = page.original;
    if (original != null) await _deleteQuietly(original.workingCopy);
  }

  Future<void> _deleteQuietly(WorkingCopy copy) async {
    try {
      await _workingCopies.delete(copy);
    } on Exception {
      // Se volverá a intentar al abrir la app (purgeAll).
    }
  }

  /// Avisa a las pantallas que el estado cambió, salvo que el controlador ya no exista.
  void _notify() {
    if (!_isDisposed) notifyListeners();
  }

  @override
  void dispose() {
    _isDisposed = true;
    _history.dispose();
    _draftTimer?.cancel();
    super.dispose();
  }
}
