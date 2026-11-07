// Estado visible de una operación (tarea T015; spec, módulo 5).
//
// El spec exige distinguir una operación en curso, una terminada y una fallida.
// Este modelo solo dice QUÉ pasó; el texto lo elige statusText, en el idioma de la app
// (presentation/strings_es.dart y strings_en.dart). Así la lógica no depende de la
// interfaz.

import 'app_failure.dart';
import 'export_format.dart';

/// Tipo de mensaje; define el color y el ícono del aviso en pantalla.
enum StatusKind { info, inProgress, success, failure }

/// Qué ocurrió.
enum StatusEvent {
  /// Se está reconociendo el texto (con varias páginas, dice cuál va).
  recognizing,
  /// El texto se reconoció; avisa si alguna página no tenía texto.
  recognized,
  /// La imagen no tenía texto reconocible.
  noTextFound,
  /// La persona no autorizó enviar la imagen: no se envió nada.
  consentDeclined,
  /// Se está generando el archivo Word o PDF.
  exporting,
  /// El archivo se guardó en el teléfono.
  saved,
  /// Se cerró el diálogo para guardar sin elegir dónde; el texto sigue.
  saveCancelled,
  /// Al abrir la app se recuperó el texto que se estaba editando.
  draftRestored,
  /// La persona descartó el texto.
  discarded,
  /// Algo falló; el motivo está en [OperationStatus.failure].
  failed,
  // Avisos de la sesión (spec 002).
  /// La sesión venció; el texto en edición se conserva.
  sessionExpired,
  /// La persona cerró la sesión.
  signedOut,
  /// La cuenta y sus datos se eliminaron.
  accountDeleted,
  /// Spec 007: se abrió un documento de Mis documentos para seguir editándolo.
  historyOpened,
}

/// Acción que el usuario puede tomar desde el aviso. `shareExport` es «Compartir» el
/// documento recién guardado (spec 003, Historia 3).
///
/// Spec 009: `takePhoto` ofrece «Tomar fotografía» cuando el escáner no está
/// disponible [ED-H2-E1].
enum StatusAction { retryRecognition, replaceImage, shareExport, takePhoto }

/// Aviso de estado que muestran las pantallas (StatusBanner): qué pasó, de qué tipo
/// es y, si aplica, un botón para seguir.
///
/// Se crea con el constructor que corresponde: [OperationStatus.inProgress],
/// [OperationStatus.success], [OperationStatus.info], [OperationStatus.failure] o
/// [OperationStatus.noTextFound].
class OperationStatus {
  const OperationStatus._(
    this.kind,
    this.event, {
    this.failure,
    this.format,
    this.action,
    this.page,
    this.pageCount,
    this.emptyPages = const [],
  });

  /// Operación en curso (por ejemplo, «Reconociendo la página 2 de 3…»).
  const OperationStatus.inProgress(
    StatusEvent event, {
    ExportFormat? format,
    int? page,
    int? pageCount,
  }) : this._(
         StatusKind.inProgress,
         event,
         format: format,
         page: page,
         pageCount: pageCount,
       );

  /// Operación terminada correctamente, con una acción opcional para seguir y, en
  /// varias páginas (spec 004), las que no tenían texto.
  const OperationStatus.success(
    StatusEvent event, {
    ExportFormat? format,
    StatusAction? action,
    List<int> emptyPages = const [],
  }) : this._(
         StatusKind.success,
         event,
         format: format,
         action: action,
         emptyPages: emptyPages,
       );

  /// Información neutral: no es un éxito ni un error (por ejemplo, guardado cancelado).
  const OperationStatus.info(StatusEvent event)
    : this._(StatusKind.info, event);

  /// Operación fallida, con el motivo y, si aplica, una acción para seguir y la
  /// página que falló (spec 004).
  const OperationStatus.failure(
    AppFailure failure, {
    StatusAction? action,
    int? page,
    int? pageCount,
  }) : this._(
         StatusKind.failure,
         StatusEvent.failed,
         failure: failure,
         action: action,
         page: page,
         pageCount: pageCount,
       );

  /// El reconocimiento terminó sin texto (Historia 1, escenario 7): se ofrece otra
  /// imagen o repetir la captura.
  const OperationStatus.noTextFound()
    : this._(
        StatusKind.failure,
        StatusEvent.noTextFound,
        action: StatusAction.replaceImage,
      );

  /// Tipo de aviso: define su color y su ícono.
  final StatusKind kind;
  /// Qué pasó: define el texto del aviso (statusText).
  final StatusEvent event;
  /// Motivo del fallo; solo en los avisos de fallo.
  final AppFailure? failure;
  /// Formato del archivo, en los avisos de exportar y guardar.
  final ExportFormat? format;
  /// Botón que ofrece el aviso; null si no tiene.
  final StatusAction? action;

  /// Spec 004: página en curso o con fallo (la primera es 1).
  final int? page;

  /// Spec 004: total de páginas del envío.
  final int? pageCount;

  /// Spec 004: páginas (desde 1) que no tenían texto.
  final List<int> emptyPages;
}
