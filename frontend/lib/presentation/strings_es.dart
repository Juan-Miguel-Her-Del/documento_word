// Textos en español (spec 008, tarea T701): el idioma inicial de la app
// (constitución §4). Empezó con los textos de 001 a 007, que antes estaban en
// strings.dart; hoy tiene los de toda la app.
//
// Constitución §5 y spec 001, módulo 5: cada mensaje de error dice qué pasó y qué puede
// hacer el usuario, sin trazas, rutas internas ni credenciales.

import '../models/app_failure.dart';
import '../models/export_format.dart';
import '../models/history_entry.dart';
import '../models/operation_status.dart';
import '../models/picked_image.dart';
import 'strings.dart';

/// Todos los textos de la app en español, el idioma con el que empieza
/// (constitución §4).
class AppStringsEs extends AppStrings {
  const AppStringsEs();

  @override
  String get appName => 'HandText AI';

  // --- Bienvenida (spec 002, módulo 1) ------------------------------------------
  @override
  String get welcomeTagline =>
      'Sus apuntes a mano, convertidos en texto editable en segundos.';
  @override
  String get welcomeStep1 => 'Fotografíe o elija la hoja';
  @override
  String get welcomeStep2 => 'La inteligencia artificial reconoce su letra';
  @override
  String get welcomeStep3 => 'Revise y guarde en Word o PDF';
  @override
  String get createAccount => 'Crear cuenta';
  @override
  String get haveAccount => 'Ya tengo cuenta';
  @override
  String get welcomePrivacyNote =>
      'Sus imágenes solo se envían con su autorización y no se guardan en el '
      'servidor.';
  @override
  String get back => 'Volver';

  // --- Ingreso y registro (spec 002, módulos 1 y 2) -----------------------------
  @override
  String get loginTitle => 'Bienvenido de nuevo';
  @override
  String get loginSubtitle =>
      'Inicie sesión para seguir digitalizando sus apuntes.';
  @override
  String get registerTitle => 'Cree su cuenta';
  @override
  String get registerSubtitle =>
      'Solo necesita su nombre, su correo y una contraseña.';
  @override
  String get nameLabel => 'Nombre';
  @override
  String get emailLabel => 'Correo electrónico';
  @override
  String get passwordLabel => 'Contraseña';
  @override
  String get confirmPasswordLabel => 'Confirmar contraseña';
  @override
  String get passwordHint => 'Mínimo 8 caracteres';
  @override
  String get showPassword => 'Mostrar contraseña';
  @override
  String get hidePassword => 'Ocultar contraseña';
  @override
  String get signIn => 'Iniciar sesión';
  @override
  String get noAccountQuestion => '¿No tiene cuenta?';
  @override
  String get createAccountLink => 'Crear una';
  @override
  String get haveAccountQuestion => '¿Ya tiene cuenta?';
  @override
  String get dataPolicyConsent =>
      'Autorizo a HandText AI a tratar mi nombre y mi correo para crear y usar mi '
      'cuenta.';

  /// Nivel de seguridad de la contraseña (0 débil, 1 aceptable, 2 fuerte).
  @override
  String passwordStrength(int level) =>
      'Seguridad: ${const ['débil', 'aceptable', 'fuerte'][level]}';

  // --- Ajustes y Acerca de (spec 005) ------------------------------------------
  @override
  String get settingsTitle => 'Ajustes';
  @override
  String get aboutTitle => 'Acerca de';
  @override
  String get privacyTitle => 'Privacidad';
  @override
  String get licensesTitle => 'Licencias';
  @override
  String get privacyAndAbout => 'Privacidad y acerca de';
  @override
  String get themeSection => 'Tema';
  @override
  String get themeSystem => 'Automático';
  @override
  String get themeLight => 'Claro';
  @override
  String get themeDark => 'Oscuro';
  @override
  String get themeHint =>
      'Cambia el editor, los diálogos y las hojas. Las pantallas azules, como esta, '
      'son parte del diseño de la app y no cambian.';
  @override
  String get textSizeSection => 'Letra del editor';
  @override
  String get textSizeNormal => 'Normal';
  @override
  String get textSizeLarge => 'Grande';
  @override
  String get textSizeExtraLarge => 'Muy grande';
  @override
  String get textSizePreview =>
      'Así se verá el texto de sus apuntes en el editor.';
  @override
  String get settingsSavedHint =>
      'Los ajustes se guardan en este teléfono y se conservan al cambiar de cuenta.';

  /// «Versión 1.0.0 (1)».
  @override
  String version(String name, int build) => 'Versión $name ($build)';
  @override
  String get aboutDescription =>
      'Convierte sus apuntes escritos a mano en documentos Word o PDF editables, con '
      'la ayuda de la inteligencia artificial y su revisión.';
  @override
  String get aboutPrivacyHint => 'Qué datos usa la app y cuándo se borran';
  @override
  String get aboutLicensesHint => 'Librerías y tipografía que usa la app';

  /// Privacidad (R6 de 005): resumen de las reglas de 001 a 011, sección por sección.
  @override
  List<(String, String)> get privacySections => const <(String, String)>[
    (
      'Imágenes',
      'Las fotos solo se envían si usted lo autoriza: van al servidor de HandText AI '
          'y a Google Cloud Vision, que reconoce la escritura. Ninguno de los dos las '
          'guarda. En el teléfono, la app trabaja con copias que borra al terminar, al '
          'cancelar o al cerrar sesión; la foto original nunca se modifica. El '
          'escáner de documentos trabaja en el teléfono y no envía nada.',
    ),
    (
      'Texto',
      'El texto que usted revisa se guarda solo en este teléfono, como borrador, '
          'hasta que lo exporta o lo descarta. No se guarda en el servidor. Si lo '
          'copia, queda en el portapapeles del teléfono, donde otras apps '
          'pueden leerlo.',
    ),
    (
      'Documentos',
      'Los archivos Word y PDF se guardan donde usted elija. Al compartir, la app '
          'prepara una copia temporal que borra después; la app que usted elige '
          'recibe el archivo.',
    ),
    (
      'Cuenta',
      'El servidor guarda su nombre, su correo y su contraseña cifrada (nunca la '
          'contraseña en sí). La sesión se guarda cifrada en el teléfono. Puede '
          'eliminar su cuenta desde el menú de la cuenta: se borran sus datos, sus '
          'sesiones, su borrador y su historial.',
    ),
    (
      'Historial',
      'Mis documentos guarda el título, el texto, la fecha y el formato de cada '
          'documento que usted guarda, solo en este teléfono y solo para su cuenta. '
          'No se envía al servidor. Puede eliminar cada documento o todo el '
          'historial, y se borra al eliminar su cuenta. Al cerrar sesión se conserva.',
    ),
    (
      'Ajustes',
      'El tema, el tamaño de letra, el idioma, el bloqueo con huella y si ya vio '
          'los consejos para una buena foto se guardan solo en este teléfono. La '
          'huella y el rostro los verifica Android: nunca llegan a la app.',
    ),
  ];

  // --- Idioma (spec 008) ----------------------------------------------------------
  @override
  String get languageSection => 'Idioma';
  @override
  String get languageSystem => 'Automático (idioma del teléfono)';
  @override
  String get languageHint =>
      'Cambia los textos de la app. El texto de sus documentos nunca se traduce.';
  @override
  String get languageTooltip => 'Cambiar el idioma';

  // --- Consejos para una buena foto (spec 006, módulo 1) ------------------------
  @override
  String get tipsLink => 'Consejos para una buena foto';
  @override
  String get tipsLinkHint =>
      'Cómo fotografiar la hoja para que la IA lea mejor';
  @override
  String get tipsSkip => 'Saltar';
  @override
  String get tipsNext => 'Siguiente';
  @override
  String get tipsStart => 'Empezar';

  /// «Consejo 2 de 4» [PA-H2-E4].
  @override
  String tipOf(int tip, int count) => 'Consejo $tip de $count';

  /// Los cuatro consejos (título y texto), en orden.
  @override
  List<(String, String)> get tips => const <(String, String)>[
    (
      'Busque buena luz',
      'Fotografíe con luz pareja, de día o bajo una lámpara. Evite las sombras de '
          'su mano o del teléfono y los reflejos del flash sobre la hoja.',
    ),
    (
      'Toda la hoja, de frente',
      'Encuadre la hoja completa y sostenga el teléfono paralelo al papel. Si '
          'quedan bordes o la hoja salió torcida, use «Recortar o girar» antes de '
          'enviarla.',
    ),
    (
      'Una hoja por foto',
      '¿Son varias hojas? Agréguelas como páginas, hasta 10, y obtendrá un solo '
          'documento en el orden que elija.',
    ),
    (
      'Revise lo resaltado',
      'La IA puede equivocarse. Las palabras resaltadas en amarillo son las que '
          'leyó con dudas: en el editor, toque «Siguiente» para revisarlas una por '
          'una.',
    ),
  ];

  // --- Mis documentos (spec 007) ---------------------------------------------------
  @override
  String get historyTitle => 'Mis documentos';

  /// Subtítulo del acceso en el inicio.
  @override
  String historyCount(int count) => switch (count) {
    0 => 'Aquí aparecerán los documentos que guarde',
    1 => '1 documento guardado',
    _ => '$count documentos guardados',
  };
  @override
  String get historyEmptyTitle => 'Todavía no hay documentos guardados';
  @override
  String get historyEmptyMessage =>
      'Cuando guarde un texto como Word o PDF, aparecerá aquí para volver a abrirlo, '
      'corregirlo o compartirlo.';
  @override
  String get historyClearAll => 'Borrar todo';

  /// Nombre del botón de cada documento para TalkBack: «Eliminar Apuntes».
  @override
  String historyDelete(String title) => 'Eliminar $title';
  @override
  String get historyOpenTitle => '¿Abrir este documento?';
  @override
  String get historyOpenMessage =>
      'Tiene un texto con cambios sin exportar. Si abre este documento, ese texto se '
      'reemplazará y no se podrá recuperar.';
  @override
  String get historyOpenConfirm => 'Abrir';
  @override
  String get historyDeleteTitle => '¿Eliminar del historial?';
  @override
  String historyDeleteMessage(String title) =>
      '«$title» saldrá de Mis documentos. El archivo Word o PDF que guardó en el '
      'teléfono no se borra.';
  @override
  String get historyDeleteConfirm => 'Eliminar';
  @override
  String get historyClearTitle => '¿Borrar todo el historial?';
  @override
  String historyClearMessage(int count) =>
      'Se quitará${count == 1 ? ' el documento' : 'n los $count documentos'} de Mis '
      'documentos. Los archivos Word y PDF guardados en el teléfono no se borran.';
  @override
  String get historyClearConfirm => 'Borrar todo';

  /// Detalles de un documento: «29 oct 2026, 15:30 · Word y PDF · 120 palabras».
  @override
  String historyDetails(HistoryEntry entry) {
    final formats = [
      for (final format in ExportFormat.values)
        if (entry.formats.contains(format)) format.label,
    ].join(' y ');
    final words = entry.wordCount == 1
        ? '1 palabra'
        : '${entry.wordCount} palabras';
    return '${shortDate(entry.savedAt)} · $formats · $words';
  }

  /// Fecha corta en español, sin paquetes (research.md de 007, R6):
  /// «29 oct 2026, 15:30».
  @override
  String shortDate(DateTime moment) {
    const months = [
      'ene', 'feb', 'mar', 'abr', 'may', 'jun', //
      'jul', 'ago', 'sep', 'oct', 'nov', 'dic',
    ];
    String twoDigits(int value) => value.toString().padLeft(2, '0');
    return '${moment.day} ${months[moment.month - 1]} ${moment.year}, '
        '${twoDigits(moment.hour)}:${twoDigits(moment.minute)}';
  }

  // --- Cuenta (spec 002, módulos 2 y 4) -----------------------------------------
  @override
  String get accountTooltip => 'Cuenta';
  @override
  String get signOut => 'Cerrar sesión';
  @override
  String get signOutTitle => '¿Cerrar sesión?';
  @override
  String get signOutUnexportedMessage =>
      'Tiene un texto sin exportar. Si cierra la sesión, se descartará y no se '
      'podrá recuperar.';
  @override
  String get deleteAccount => 'Eliminar cuenta';
  @override
  String get deleteAccountTitle => '¿Eliminar su cuenta?';
  @override
  String get deleteAccountMessage =>
      'Se borrarán su cuenta, sus sesiones y el texto que tenga en edición en este '
      'teléfono. Escriba su contraseña para confirmar.';
  @override
  String get deleteAccountConfirm => 'Eliminar definitivamente';

  /// Saludo del inicio: «Hola, Ana».
  @override
  String greeting(String firstName) => 'Hola, $firstName';

  // --- Pantalla de inicio -------------------------------------------------------
  @override
  String get startTitle => 'Digitalice sus documentos escritos a mano';
  @override
  String get startDescription =>
      'Tome una fotografía o elija una imagen. HandText AI reconocerá el texto '
      'para que lo revise, lo corrija y lo guarde como Word o PDF.';
  @override
  String get takePhoto => 'Tomar fotografía';
  @override
  String get pickFromGallery => 'Elegir imagen guardada';
  @override
  String get imageRequirements =>
      'Imágenes JPEG o PNG de hasta 10 MB y de 600 a 10 000 píxeles por lado.';
  @override
  String get startHeadline => '¿Qué vamos a digitalizar hoy?';
  @override
  String get takePhotoSubtitle => 'Use la cámara para capturar la hoja';
  @override
  String get pickFromGallerySubtitle =>
      'Elija una o varias fotos JPEG o PNG del teléfono';
  @override
  String get documentInProgress => 'Tiene un texto en edición';
  @override
  String get keepCurrentTextNotice =>
      'Su texto actual se conservará hasta que el nuevo reconocimiento termine '
      'correctamente.';
  @override
  String get backToCurrentText => 'Volver al texto actual';

  // --- Vista previa ---------------------------------------------------------------
  @override
  String get previewTitle => 'Vista previa';
  @override
  String get acceptAndRecognize => 'Aceptar y reconocer texto';
  @override
  String get chooseAnotherImage => 'Elegir otra imagen';
  @override
  String get retakePhoto => 'Repetir captura';
  @override
  String get cancel => 'Cancelar';
  @override
  String get cancelSelectionTooltip => 'Cancelar la selección';
  @override
  String get recognizingHint =>
      'Reconociendo el texto… Puede tardar hasta 60 segundos.';
  @override
  String get imagePreviewUnavailable =>
      'No se puede mostrar la vista previa de esta imagen.';

  // --- Varias páginas (spec 004) -------------------------------------------------
  /// «Página 2 de 3».
  @override
  String pageOf(int page, int count) => 'Página $page de $count';

  /// Botón principal con varias páginas: «Reconocer 3 páginas».
  @override
  String recognizePages(int count) => 'Reconocer $count páginas';
  @override
  String get addPage => 'Agregar página';
  @override
  String get addPageFromCamera => 'Tomar fotografía';
  @override
  String get addPageFromGallery => 'Elegir de la galería';
  @override
  String get movePageBefore => 'Mover la página antes';
  @override
  String get movePageAfter => 'Mover la página después';
  @override
  String get removePage => 'Quitar la página';

  /// Descripción de una miniatura para los lectores de pantalla.
  @override
  String pageThumbnail(int page, bool selected) =>
      'Página $page${selected ? ', elegida' : ''}';
  @override
  String get readingHandwriting => 'Leyendo su escritura…';

  /// Datos de la imagen bajo la vista previa: «JPEG · 3024 × 4032 px · 2,4 MB».
  @override
  String imageDetails(PickedImage image) =>
      '${image.format.label} · ${image.width} × ${image.height} px · '
      '${formatBytes(image.sizeBytes)}';

  /// Tamaño legible con coma decimal: «850 KB», «2,4 MB».
  @override
  String formatBytes(int bytes) {
    if (bytes >= 1024 * 1024) {
      final megabytes = bytes / (1024 * 1024);
      return '${megabytes.toStringAsFixed(1).replaceAll('.', ',')} MB';
    }
    return '${(bytes / 1024).ceil()} KB';
  }

  /// Texto del botón que reemplaza la imagen, según su origen.
  @override
  String replaceImageLabel(ImageOrigin origin) => switch (origin) {
    ImageOrigin.camera => retakePhoto,
    ImageOrigin.scanner => rescanImage, // spec 009 [ED-H3-E3]
    ImageOrigin.gallery => chooseAnotherImage,
  };

  // --- Bloqueo con huella o rostro (spec 011) ------------------------------------
  @override
  String get appLockTitle => 'Bloquear con huella o rostro';
  @override
  String get appLockHint =>
      'Al abrir la app y al volver después de 1 minuto, pide su huella, su rostro o '
      'el bloqueo de pantalla del teléfono.';
  @override
  String get appLockUnavailable =>
      'Para usar esta opción, configure una huella, el rostro o un bloqueo de '
      'pantalla en los ajustes del teléfono.';
  @override
  String get enableLockReason =>
      'Confirme que es usted para activar el bloqueo';
  @override
  String get unlockReason => 'Desbloquear HandText AI';
  @override
  String get lockedTitle => 'HandText AI está bloqueada';
  @override
  String get lockedMessage =>
      'Para ver sus documentos, use su huella, su rostro o el bloqueo de pantalla '
      'del teléfono.';
  @override
  String get unlock => 'Desbloquear';

  // --- Organizar documentos (spec 010) ------------------------------------------
  @override
  String get copyAllText => 'Copiar todo el texto';
  @override
  String get textCopied => 'Se copió el texto. Ya puede pegarlo en otra app.';
  @override
  String get historySearchHint => 'Buscar en sus documentos';
  @override
  String historyNoResults(String query) =>
      'Ningún documento contiene «$query».';
  @override
  String historyRename(String title) => 'Renombrar $title';
  @override
  String get historyRenameTitle => 'Renombrar documento';
  @override
  String get historyRenameLabel => 'Nombre';
  @override
  String get historyRenameConfirm => 'Guardar';

  // --- Escáner de documentos (spec 009) -----------------------------------------
  @override
  String get scanDocument => 'Escanear hoja';
  @override
  String get scanDocumentSubtitle =>
      'Detecta los bordes y endereza la hoja (recomendado)';
  @override
  String get addPageFromScanner => 'Escanear';
  @override
  String get rescanImage => 'Escanear de nuevo';

  // --- Recorte y giro (spec 003, módulo 2) ---------------------------------------
  @override
  String get editImage => 'Recortar o girar';
  @override
  String get imageEditorTitle => 'Recortar y girar';
  @override
  String get restoreOriginalImage => 'Usar la imagen original';

  // --- Autorización de envío (spec, módulo 6; supuesto 5) --------------------------
  @override
  String get consentTitle => '¿Autoriza el envío de la imagen?';
  @override
  String get consentMessage =>
      'Para reconocer el texto, la imagen se enviará al servidor de HandText AI y '
      'a Google Cloud Vision, un servicio externo de reconocimiento. Solo se usa '
      'para obtener el texto y ninguno de los dos la guarda. Sin su autorización, '
      'la imagen no se envía.';

  /// Spec 004: la autorización dice cuántas imágenes se enviarán.
  @override
  String consentTitleFor(int images) =>
      images == 1 ? consentTitle : '¿Autoriza el envío de $images imágenes?';
  @override
  String consentMessageFor(int images) => images == 1
      ? consentMessage
      : 'Para reconocer el texto, las $images imágenes se enviarán una por una al '
            'servidor de HandText AI y a Google Cloud Vision, un servicio externo de '
            'reconocimiento. Solo se usan para obtener el texto y ninguno de los dos '
            'las guarda. Sin su autorización, no se envía ninguna.';
  @override
  String get consentAccept => 'Autorizar y enviar';
  @override
  String get consentDecline => 'No autorizar';

  // --- Editor ---------------------------------------------------------------------
  @override
  String get editorTitle => 'Revisar texto';
  @override
  String get recognitionWarning =>
      'El reconocimiento puede contener errores. Revise y corrija el texto antes '
      'de exportarlo.';
  @override
  String get editorSubtitle => 'Corrija lo que la IA no haya leído bien.';
  @override
  String get editorLabel => 'Texto del documento';

  /// Contador del editor: «12 palabras · 80 caracteres».
  @override
  String textStats(int words, int characters) =>
      '$words ${words == 1 ? 'palabra' : 'palabras'} · '
      '$characters ${characters == 1 ? 'carácter' : 'caracteres'}';
  @override
  String get editorHint => 'Escriba o corrija el texto aquí';

  // --- Palabras dudosas (spec 003, módulo 1) -------------------------------------
  /// Barra de revisión: «3 palabras para revisar».
  @override
  String uncertainWordsCount(int count) =>
      count == 1 ? '1 palabra para revisar' : '$count palabras para revisar';

  /// Guía cuando no hay ninguna palabra dudosa seleccionada.
  @override
  String get uncertainWordsHint =>
      'La IA leyó con dudas las palabras resaltadas. Toque «Siguiente» para ir a '
      'cada una.';

  /// Guía cuando hay una palabra dudosa seleccionada.
  @override
  String get acceptUncertainWordHint =>
      'Corríjala o toque «Está bien» si ya está correcta.';
  @override
  String get nextUncertainWord => 'Siguiente';

  /// Spec 006: lo que TalkBack lee al ir a una palabra dudosa [PA-H2-E3].
  @override
  String uncertainWordAnnouncement(String word) =>
      'Palabra para revisar: $word';
  @override
  String get acceptUncertainWord => 'Está bien';
  @override
  String get export => 'Exportar';
  @override
  String get moreActionsTooltip => 'Más opciones';
  @override
  String get processAnotherImage => 'Procesar otra imagen';
  @override
  String get discardText => 'Descartar texto';

  // --- Confirmaciones (spec, módulo 3) ------------------------------------------
  @override
  String get replaceTextTitle => '¿Procesar otra imagen?';
  @override
  String get replaceTextMessage =>
      'Si el nuevo reconocimiento termina correctamente, su texto actual y sus '
      'correcciones se reemplazarán por el nuevo resultado. Si cancela o el '
      'reconocimiento falla, su texto se conserva.';
  @override
  String get replaceTextConfirm => 'Continuar';
  @override
  String get discardTitle => '¿Descartar el texto?';
  @override
  String get discardMessage =>
      'Se eliminarán el texto y sus correcciones, incluido el borrador guardado en '
      'este teléfono. Esta acción no se puede deshacer.';
  @override
  String get discardConfirm => 'Descartar';

  // --- Exportación ----------------------------------------------------------------
  @override
  String get chooseFormatTitle => 'Exportar como';
  @override
  String get wordOption => 'Word (.docx)';
  @override
  String get wordOptionHint => 'Documento editable';
  @override
  String get pdfOption => 'PDF (.pdf)';
  @override
  String get pdfOptionHint => 'Documento listo para leer o imprimir';
  @override
  String get saveDialogTitle => 'Guardar documento';
  @override
  String get retry => 'Reintentar';

  // --- Compartir (spec 003, módulo 3) --------------------------------------------
  @override
  String get share => 'Compartir';

  // --- Mensajes de estado (spec, módulo 5) -------------------------------------
  /// Texto de un aviso de estado.
  @override
  String statusText(OperationStatus status) {
    final format = status.format?.label ?? '';
    final page = status.page;
    final pageCount = status.pageCount ?? 1;
    return switch (status.event) {
      // Spec 004: con varias páginas se dice cuál se está leyendo.
      StatusEvent.recognizing =>
        page != null && pageCount > 1
            ? 'Reconociendo la página $page de $pageCount…'
            : 'Reconociendo el texto…',
      StatusEvent.recognized =>
        'Texto reconocido. Revíselo y corríjalo antes de exportarlo.'
            '${emptyPagesText(status.emptyPages)}',
      StatusEvent.noTextFound =>
        'No se reconoció texto en la imagen. Pruebe con otra imagen o con una '
            'fotografía con mejor luz y enfoque.',
      StatusEvent.consentDeclined =>
        'No se envió la imagen. Puede autorizar el envío cuando quiera reconocer '
            'el texto.',
      StatusEvent.exporting => 'Generando el archivo $format…',
      StatusEvent.saved => 'El archivo $format se guardó correctamente.',
      StatusEvent.saveCancelled =>
        'No se guardó el archivo. Su texto se conserva.',
      StatusEvent.draftRestored => 'Se recuperó el texto que estaba editando.',
      StatusEvent.discarded => 'El texto se descartó.',
      // Spec 004: con varias páginas, el fallo dice en cuál ocurrió.
      StatusEvent.failed =>
        '${page != null && pageCount > 1 ? '${pageOf(page, pageCount)}: ' : ''}'
            '${failureText(status.failure ?? const AppFailure(FailureKind.unexpected))}',
      StatusEvent.sessionExpired =>
        'Su sesión venció. Inicie sesión de nuevo; su texto en edición se '
            'conserva.',
      StatusEvent.signedOut => 'Cerró la sesión. ¡Hasta pronto!',
      StatusEvent.accountDeleted => 'Su cuenta y sus datos se eliminaron.',
      StatusEvent.historyOpened =>
        'Se abrió el documento guardado. Puede corregirlo y exportarlo de nuevo.',
    };
  }

  /// Spec 004: « La página 2 no tenía texto.» o « Las páginas 2 y 4 no tenían texto.».
  @override
  String emptyPagesText(List<int> pages) {
    if (pages.isEmpty) return '';
    if (pages.length == 1) return ' La página ${pages.single} no tenía texto.';
    final list =
        '${pages.sublist(0, pages.length - 1).join(', ')} y ${pages.last}';
    return ' Las páginas $list no tenían texto.';
  }

  /// Mensaje de cada fallo: qué pasó y qué puede hacer el usuario.
  @override
  String failureText(AppFailure failure) => switch (failure.kind) {
    FailureKind.unsupportedImageType =>
      'El archivo no es una imagen JPEG o PNG. Elija otra imagen.',
    FailureKind.imageTooLarge =>
      'La imagen supera el tamaño máximo de 10 MB. Elija otra imagen.',
    FailureKind.imageDimensionsOutOfRange =>
      'La imagen debe medir entre 600 y 10 000 píxeles por lado. Elija otra '
          'imagen o repita la captura.',
    FailureKind.imageUnreadable =>
      'No se pudo abrir la imagen; puede estar dañada. Elija otra imagen o '
          'repita la captura.',
    FailureKind.cameraPermissionDenied =>
      'Se necesita el permiso de cámara para tomar la fotografía. Puede '
          'concederlo la próxima vez que lo intente o elegir una imagen guardada.',
    FailureKind.cameraPermissionPermanentlyDenied =>
      'El permiso de cámara está desactivado. Para tomar fotografías, actívelo en '
          'los ajustes del teléfono (Aplicaciones > HandText AI > Permisos). '
          'Mientras tanto, puede elegir una imagen guardada.',
    FailureKind.cameraUnavailable =>
      'No se pudo abrir la cámara. Inténtelo de nuevo o elija una imagen '
          'guardada.',
    FailureKind.noConnection =>
      'No hay conexión con el servidor. Revise su conexión a internet y vuelva '
          'a intentarlo.',
    FailureKind.recognitionTimeout =>
      'El reconocimiento tardó más de 60 segundos y se canceló. Vuelva a '
          'intentarlo.',
    FailureKind.serviceUnavailable =>
      'El servicio de reconocimiento no está disponible en este momento. '
          'Inténtelo más tarde.',
    FailureKind.recognitionFailed =>
      'El servicio de reconocimiento no pudo procesar la imagen. Vuelva a '
          'intentarlo o elija otra imagen.',
    FailureKind.invalidServerResponse =>
      'El servidor respondió de forma inesperada. Vuelva a intentarlo.',
    FailureKind.emptyText =>
      'No se puede exportar un texto vacío o que solo contiene espacios. Escriba '
          'o revise el texto antes de exportar.',
    FailureKind.textTooLarge =>
      'El texto es demasiado largo para exportarlo. Divídalo en partes más '
          'pequeñas.',
    FailureKind.unsupportedCharacters =>
      failure.detail ??
          'El texto contiene caracteres que no se pueden incluir en el archivo.',
    FailureKind.exportFailed =>
      'No se pudo generar el archivo. Su texto se conserva; vuelva a '
          'intentarlo.',
    FailureKind.exportTimeout =>
      'La generación del archivo tardó demasiado. Su texto se conserva; vuelva '
          'a intentarlo.',
    FailureKind.saveFailed =>
      'No se pudo guardar el archivo. Su texto se conserva; vuelva a '
          'intentarlo.',
    FailureKind.missingCredentials => 'Escriba su correo y su contraseña.',
    FailureKind.invalidDisplayName => 'Escriba un nombre de 1 a 60 caracteres.',
    FailureKind.invalidEmail =>
      'Escriba un correo electrónico válido, por ejemplo nombre@correo.com.',
    FailureKind.weakPassword =>
      'La contraseña debe tener entre 8 y 128 caracteres.',
    FailureKind.passwordMismatch => 'Las contraseñas no coinciden.',
    FailureKind.dataPolicyNotAccepted =>
      'Para crear la cuenta debe autorizar el tratamiento de sus datos.',
    FailureKind.emailAlreadyRegistered =>
      'Ya existe una cuenta con ese correo. Inicie sesión o use otro correo.',
    FailureKind.invalidCredentials => 'Correo o contraseña incorrectos.',
    FailureKind.tooManyAttempts =>
      'Demasiados intentos fallidos. Por seguridad, espere 15 minutos e '
          'intente de nuevo.',
    FailureKind.sessionExpired => 'Su sesión venció. Inicie sesión de nuevo.',
    FailureKind.accountsUnavailable =>
      'El servicio de cuentas no está disponible en este momento. Inténtelo '
          'más tarde.',
    FailureKind.imageEditFailed =>
      'No se pudo recortar la imagen. Se conserva la imagen anterior.',
    FailureKind.shareFailed =>
      'No se pudo abrir el menú para compartir. Vuelva a intentarlo.',
    FailureKind.scannerUnavailable =>
      'El escáner de documentos no está disponible en este teléfono: necesita los '
          'servicios de Google Play. Puede tomar una fotografía o elegir una imagen '
          'guardada.',
    FailureKind.scannerFailed =>
      'No se pudo escanear la hoja. Vuelva a intentarlo, tome una fotografía o '
          'elija una imagen guardada.',
    FailureKind.tooManyPages =>
      'Un documento puede tener hasta 10 páginas. Quite alguna para agregar otra.',
    FailureKind.unexpected =>
      'Ocurrió un error inesperado. Vuelva a intentarlo.',
  };
}
