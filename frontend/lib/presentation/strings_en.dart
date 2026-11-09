// English texts (spec 008, tarea T707; research.md de 008, R1).
//
// Traducción de strings_es.dart, texto por texto. Las fechas y los tamaños usan el
// formato inglés (R6). Si falta un texto, la app no compila [SC-801].
//
// Constitución §5: cada mensaje de error dice qué pasó y qué puede hacer el usuario.

import '../models/app_failure.dart';
import '../models/export_format.dart';
import '../models/history_entry.dart';
import '../models/operation_status.dart';
import '../models/picked_image.dart';
import 'strings.dart';

/// Todos los textos de la app en inglés (spec 008), traducidos uno por uno de
/// [AppStringsEs].
class AppStringsEn extends AppStrings {
  const AppStringsEn();

  @override
  String get appName => 'HandText AI';

  // --- Bienvenida (spec 002, módulo 1) ------------------------------------------
  @override
  String get welcomeTagline =>
      'Your handwritten notes, turned into editable text in seconds.';
  @override
  String get welcomeStep1 => 'Take a photo of the page or choose one';
  @override
  String get welcomeStep2 => 'Artificial intelligence reads your handwriting';
  @override
  String get welcomeStep3 => 'Review it and save it as Word or PDF';
  @override
  String get createAccount => 'Create account';
  @override
  String get haveAccount => 'I already have an account';
  @override
  String get welcomePrivacyNote =>
      'Your images are only sent to the recognition API with your permission and '
      'are not stored on the server. Recognition and Word/PDF generation require '
      'a backend connection. OCR uses Google Vision.';
  @override
  String get back => 'Back';

  // --- Ingreso y registro (spec 002, módulos 1 y 2) -----------------------------
  @override
  String get loginTitle => 'Welcome back';
  @override
  String get loginSubtitle => 'Sign in to keep digitizing your notes.';
  @override
  String get registerTitle => 'Create your account';
  @override
  String get registerSubtitle =>
      'Your account is stored securely on this phone. It is not synced or '
      'recoverable from another device. Recognition and export require a backend '
      'connection. OCR uses Google Vision.';
  @override
  String get nameLabel => 'Name';
  @override
  String get emailLabel => 'Email';
  @override
  String get passwordLabel => 'Password';
  @override
  String get confirmPasswordLabel => 'Confirm password';
  @override
  String get passwordHint => 'At least 8 characters';
  @override
  String get showPassword => 'Show password';
  @override
  String get hidePassword => 'Hide password';
  @override
  String get signIn => 'Sign in';
  @override
  String get noAccountQuestion => "Don't have an account?";
  @override
  String get createAccountLink => 'Create one';
  @override
  String get haveAccountQuestion => 'Already have an account?';
  @override
  String get dataPolicyConsent =>
      'I agree to store my name and email encrypted on this phone to create and '
      'use my local account.';

  /// Nivel de seguridad de la contraseña (0 débil, 1 aceptable, 2 fuerte).
  @override
  String passwordStrength(int level) =>
      'Strength: ${const ['weak', 'fair', 'strong'][level]}';

  // --- Ajustes y Acerca de (spec 005) ------------------------------------------
  @override
  String get settingsTitle => 'Settings';
  @override
  String get aboutTitle => 'About';
  @override
  String get privacyTitle => 'Privacy';
  @override
  String get licensesTitle => 'Licenses';
  @override
  String get privacyAndAbout => 'Privacy and about';
  @override
  String get themeSection => 'Theme';
  @override
  String get themeSystem => 'Automatic';
  @override
  String get themeLight => 'Light';
  @override
  String get themeDark => 'Dark';
  @override
  String get themeHint =>
      'Changes the editor, dialogs and sheets. Blue screens like this one are part '
      'of the app design and do not change.';
  @override
  String get textSizeSection => 'Editor text size';
  @override
  String get textSizeNormal => 'Normal';
  @override
  String get textSizeLarge => 'Large';
  @override
  String get textSizeExtraLarge => 'Extra large';
  @override
  String get textSizePreview =>
      'This is how your notes will look in the editor.';
  @override
  String get settingsSavedHint =>
      'Settings are saved on this phone and kept when you switch accounts.';

  /// «Version 1.0.0 (1)».
  @override
  String version(String name, int build) => 'Version $name ($build)';
  @override
  String get aboutDescription =>
      'Turns your handwritten notes into editable Word or PDF documents, with the '
      'help of artificial intelligence and your review.';
  @override
  String get aboutPrivacyHint =>
      'What data the app uses and when it is deleted';
  @override
  String get aboutLicensesHint => 'Libraries and font used by the app';

  /// Privacidad (R6 de 005): resumen de las reglas de 001 a 011, sección por sección.
  @override
  List<(String, String)> get privacySections => const <(String, String)>[
    (
      'Images',
      'Photos are only sent if you allow it: they go to the HandText AI server and '
          'to Google Cloud Vision, which reads the handwriting. Neither of them '
          'stores them. On the phone, the app works with copies that it deletes when '
          'it finishes, when you cancel or when you sign out; the original photo is '
          'never changed. The document scanner works on the phone and sends '
          'nothing.',
    ),
    (
      'Text',
      'The text you review is saved only on this phone, as a draft, until you '
          'export it or discard it. It is not stored on the server. If you copy '
          'it, it stays on the phone clipboard, where other apps can read it.',
    ),
    (
      'Documents',
      'Word and PDF files are saved wherever you choose. When you share, the app '
          'makes a temporary copy that it deletes afterwards; the app you choose '
          'receives the file.',
    ),
    (
      'Account',
      'The server stores your name, your email and your encrypted password (never '
          'the password itself). The session is stored encrypted on the phone. You '
          'can delete your account from the account menu: your data, your sessions, '
          'your draft and your history are deleted.',
    ),
    (
      'History',
      'My documents keeps the title, text, date and format of each document you '
          'save, only on this phone and only for your account. It is not sent to the '
          'server. You can delete each document or the whole history, and it is '
          'deleted when you delete your account. It is kept when you sign out.',
    ),
    (
      'Settings',
      'The theme, the text size, the language, the fingerprint lock and whether '
          'you have seen the tips for a good photo are saved only on this phone. '
          'Android checks your fingerprint and face: they never reach the app.',
    ),
  ];

  // --- Idioma (spec 008) ----------------------------------------------------------
  @override
  String get languageSection => 'Language';
  @override
  String get languageSystem => 'Automatic (phone language)';
  @override
  String get languageHint =>
      'Changes the app texts. The text of your documents is never translated.';
  @override
  String get languageTooltip => 'Change language';

  // --- Consejos para una buena foto (spec 006, módulo 1) ------------------------
  @override
  String get tipsLink => 'Tips for a good photo';
  @override
  String get tipsLinkHint =>
      'How to photograph the page so the AI reads it better';
  @override
  String get tipsSkip => 'Skip';
  @override
  String get tipsNext => 'Next';
  @override
  String get tipsStart => 'Get started';

  /// «Tip 2 of 4» [PA-H2-E4].
  @override
  String tipOf(int tip, int count) => 'Tip $tip of $count';

  /// Los cuatro consejos (título y texto), en orden.
  @override
  List<(String, String)> get tips => const <(String, String)>[
    (
      'Find good light',
      'Take the photo in even light, during the day or under a lamp. Avoid shadows '
          'from your hand or the phone and flash glare on the page.',
    ),
    (
      'The whole page, straight on',
      'Frame the whole page and hold the phone parallel to the paper. If there are '
          'edges left or the page came out crooked, use “Crop or rotate” before '
          'sending it.',
    ),
    (
      'One page per photo',
      'Several pages? Add them as pages, up to 10, and you will get a single '
          'document in the order you choose.',
    ),
    (
      'Check the highlights',
      'The AI can make mistakes. The words highlighted in yellow are the ones it was '
          'unsure about: in the editor, tap “Next” to check them one by one.',
    ),
  ];

  // --- Mis documentos (spec 007) ---------------------------------------------------
  @override
  String get historyTitle => 'My documents';

  /// Subtítulo del acceso en el inicio.
  @override
  String historyCount(int count) => switch (count) {
    0 => 'The documents you save will appear here',
    1 => '1 saved document',
    _ => '$count saved documents',
  };
  @override
  String get historyEmptyTitle => 'No saved documents yet';
  @override
  String get historyEmptyMessage =>
      'When you save a text as Word or PDF, it will appear here so you can open, '
      'correct or share it again.';
  @override
  String get historyClearAll => 'Delete all';

  /// Nombre del botón de cada documento para TalkBack: «Delete Notes».
  @override
  String historyDelete(String title) => 'Delete $title';
  @override
  String get historyOpenTitle => 'Open this document?';
  @override
  String get historyOpenMessage =>
      'You have text with unexported changes. If you open this document, that text '
      'will be replaced and cannot be recovered.';
  @override
  String get historyOpenConfirm => 'Open';
  @override
  String get historyDeleteTitle => 'Remove from history?';
  @override
  String historyDeleteMessage(String title) =>
      '“$title” will be removed from My documents. The Word or PDF file you saved on '
      'the phone is not deleted.';
  @override
  String get historyDeleteConfirm => 'Remove';
  @override
  String get historyClearTitle => 'Delete the whole history?';
  @override
  String historyClearMessage(int count) =>
      '${count == 1 ? 'The document' : 'The $count documents'} will be removed from '
      'My documents. The Word and PDF files saved on the phone are not deleted.';
  @override
  String get historyClearConfirm => 'Delete all';

  /// Detalles de un documento: «Oct 29, 2026, 15:30 · Word and PDF · 120 words».
  @override
  String historyDetails(HistoryEntry entry) {
    final formats = [
      for (final format in ExportFormat.values)
        if (entry.formats.contains(format)) format.label,
    ].join(' and ');
    final words = entry.wordCount == 1 ? '1 word' : '${entry.wordCount} words';
    return '${shortDate(entry.savedAt)} · $formats · $words';
  }

  /// Fecha corta en inglés, sin paquetes (research.md de 008, R6): «Oct 29, 2026,
  /// 15:30».
  @override
  String shortDate(DateTime moment) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', //
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    String twoDigits(int value) => value.toString().padLeft(2, '0');
    return '${months[moment.month - 1]} ${moment.day}, ${moment.year}, '
        '${twoDigits(moment.hour)}:${twoDigits(moment.minute)}';
  }

  // --- Cuenta (spec 002, módulos 2 y 4) -----------------------------------------
  @override
  String get accountTooltip => 'Account';
  @override
  String get signOut => 'Sign out';
  @override
  String get signOutTitle => 'Sign out?';
  @override
  String get signOutUnexportedMessage =>
      'You have text that has not been exported. If you sign out, it will be '
      'discarded and cannot be recovered.';
  @override
  String get deleteAccount => 'Delete account';
  @override
  String get deleteAccountTitle => 'Delete your account?';
  @override
  String get deleteAccountMessage =>
      'Your account, your sessions and the text you are editing on this phone will '
      'be deleted. Enter your password to confirm.';
  @override
  String get deleteAccountConfirm => 'Delete permanently';

  /// Saludo del inicio: «Hi, Ana».
  @override
  String greeting(String firstName) => 'Hi, $firstName';

  // --- Pantalla de inicio -------------------------------------------------------
  @override
  String get startTitle => 'Digitize your handwritten documents';
  @override
  String get startDescription =>
      'Take a photo or choose an image. HandText AI will read the text so you can '
      'review it, correct it and save it as Word or PDF.';
  @override
  String get takePhoto => 'Take a photo';
  @override
  String get pickFromGallery => 'Choose a saved image';
  @override
  String get imageRequirements =>
      'JPEG or PNG images up to 10 MB and from 600 to 10,000 pixels per side.';
  @override
  String get startHeadline => 'What shall we digitize today?';
  @override
  String get takePhotoSubtitle => 'Use the camera to capture the page';
  @override
  String get pickFromGallerySubtitle =>
      'Choose one or more JPEG or PNG photos from your phone';
  @override
  String get documentInProgress => 'You have text in progress';
  @override
  String get keepCurrentTextNotice =>
      'Your current text will be kept until the new recognition finishes '
      'successfully.';
  @override
  String get backToCurrentText => 'Back to current text';

  // --- Vista previa ---------------------------------------------------------------
  @override
  String get previewTitle => 'Preview';
  @override
  String get acceptAndRecognize => 'Accept and read text';
  @override
  String get chooseAnotherImage => 'Choose another image';
  @override
  String get retakePhoto => 'Retake photo';
  @override
  String get cancel => 'Cancel';
  @override
  String get cancelSelectionTooltip => 'Cancel selection';
  @override
  String get recognizingHint =>
      'Reading the text… It can take up to 60 seconds.';
  @override
  String get imagePreviewUnavailable =>
      'The preview of this image cannot be shown.';

  // --- Varias páginas (spec 004) -------------------------------------------------
  /// «Page 2 of 3».
  @override
  String pageOf(int page, int count) => 'Page $page of $count';

  /// Botón principal con varias páginas: «Read 3 pages».
  @override
  String recognizePages(int count) => 'Read $count pages';
  @override
  String get addPage => 'Add page';
  @override
  String get addPageFromCamera => 'Take a photo';
  @override
  String get addPageFromGallery => 'Choose from gallery';
  @override
  String get movePageBefore => 'Move page back';
  @override
  String get movePageAfter => 'Move page forward';
  @override
  String get removePage => 'Remove page';

  /// Descripción de una miniatura para los lectores de pantalla.
  @override
  String pageThumbnail(int page, bool selected) =>
      'Page $page${selected ? ', selected' : ''}';
  @override
  String get readingHandwriting => 'Reading your handwriting…';

  /// Datos de la imagen bajo la vista previa: «JPEG · 3024 × 4032 px · 2.4 MB».
  @override
  String imageDetails(PickedImage image) =>
      '${image.format.label} · ${image.width} × ${image.height} px · '
      '${formatBytes(image.sizeBytes)}';

  /// Tamaño legible con punto decimal: «850 KB», «2.4 MB».
  @override
  String formatBytes(int bytes) {
    if (bytes >= 1024 * 1024) {
      final megabytes = bytes / (1024 * 1024);
      return '${megabytes.toStringAsFixed(1)} MB';
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
  String get appLockTitle => 'Lock with fingerprint or face';
  @override
  String get appLockHint =>
      'When the app opens, and when you come back after 1 minute, it asks for your '
      'fingerprint, your face or the phone screen lock.';
  @override
  String get appLockUnavailable =>
      'To use this option, set up a fingerprint, face or screen lock in the phone '
      'settings.';
  @override
  String get enableLockReason => 'Confirm it is you to turn on the lock';
  @override
  String get unlockReason => 'Unlock HandText AI';
  @override
  String get lockedTitle => 'HandText AI is locked';
  @override
  String get lockedMessage =>
      'To see your documents, use your fingerprint, your face or the phone screen '
      'lock.';
  @override
  String get unlock => 'Unlock';

  // --- Organizar documentos (spec 010) ------------------------------------------
  @override
  String get copyAllText => 'Copy all text';
  @override
  String get textCopied =>
      'The text was copied. You can paste it in another app.';
  @override
  String get historySearchHint => 'Search your documents';
  @override
  String historyNoResults(String query) => 'No document contains “$query”.';
  @override
  String historyRename(String title) => 'Rename $title';
  @override
  String get historyRenameTitle => 'Rename document';
  @override
  String get historyRenameLabel => 'Name';
  @override
  String get historyRenameConfirm => 'Save';

  // --- Escáner de documentos (spec 009) -----------------------------------------
  @override
  String get scanDocument => 'Scan page';
  @override
  String get scanDocumentSubtitle =>
      'Detects the edges and straightens the page (recommended)';
  @override
  String get addPageFromScanner => 'Scan';
  @override
  String get rescanImage => 'Scan again';

  // --- Recorte y giro (spec 003, módulo 2) ---------------------------------------
  @override
  String get editImage => 'Crop or rotate';
  @override
  String get imageEditorTitle => 'Crop and rotate';
  @override
  String get restoreOriginalImage => 'Use the original image';

  // --- Autorización de envío (spec, módulo 6; supuesto 5) --------------------------
  @override
  String get consentTitle => 'Allow sending the image?';
  @override
  String get consentMessage =>
      'To read the text, the image will be sent to the HandText AI server and to '
      'Google Cloud Vision, an external recognition service. It is only used to get '
      'the text and neither of them stores it. Without your permission, the image is '
      'not sent.';

  /// Spec 004: la autorización dice cuántas imágenes se enviarán.
  @override
  String consentTitleFor(int images) =>
      images == 1 ? consentTitle : 'Allow sending $images images?';
  @override
  String consentMessageFor(int images) => images == 1
      ? consentMessage
      : 'To read the text, the $images images will be sent one by one to the '
            'HandText AI server and to Google Cloud Vision, an external recognition '
            'service. They are only used to get the text and neither of them stores '
            'them. Without your permission, none is sent.';
  @override
  String get consentAccept => 'Allow and send';
  @override
  String get consentDecline => 'Do not allow';

  // --- Editor ---------------------------------------------------------------------
  @override
  String get editorTitle => 'Review text';
  @override
  String get recognitionWarning =>
      'The recognition may contain errors. Review and correct the text before '
      'exporting it.';
  @override
  String get editorSubtitle => 'Correct anything the AI did not read well.';
  @override
  String get editorLabel => 'Document text';

  /// Contador del editor: «12 words · 80 characters».
  @override
  String textStats(int words, int characters) =>
      '$words ${words == 1 ? 'word' : 'words'} · '
      '$characters ${characters == 1 ? 'character' : 'characters'}';
  @override
  String get editorHint => 'Type or correct the text here';

  // --- Palabras dudosas (spec 003, módulo 1) -------------------------------------
  /// Barra de revisión: «3 words to check».
  @override
  String uncertainWordsCount(int count) =>
      count == 1 ? '1 word to check' : '$count words to check';

  /// Guía cuando no hay ninguna palabra dudosa seleccionada.
  @override
  String get uncertainWordsHint =>
      'The AI was unsure about the highlighted words. Tap “Next” to go to each one.';

  /// Guía cuando hay una palabra dudosa seleccionada.
  @override
  String get acceptUncertainWordHint =>
      'Correct it, or tap “Looks right” if it is already correct.';
  @override
  String get nextUncertainWord => 'Next';

  /// Spec 006: lo que TalkBack lee al ir a una palabra dudosa [PA-H2-E3].
  @override
  String uncertainWordAnnouncement(String word) => 'Word to check: $word';
  @override
  String get acceptUncertainWord => 'Looks right';
  @override
  String get export => 'Export';
  @override
  String get moreActionsTooltip => 'More options';
  @override
  String get processAnotherImage => 'Process another image';
  @override
  String get discardText => 'Discard text';

  // --- Confirmaciones (spec, módulo 3) ------------------------------------------
  @override
  String get replaceTextTitle => 'Process another image?';
  @override
  String get replaceTextMessage =>
      'If the new recognition finishes successfully, your current text and your '
      'corrections will be replaced by the new result. If you cancel or the '
      'recognition fails, your text is kept.';
  @override
  String get replaceTextConfirm => 'Continue';
  @override
  String get discardTitle => 'Discard the text?';
  @override
  String get discardMessage =>
      'The text and your corrections will be deleted, including the draft saved on '
      'this phone. This cannot be undone.';
  @override
  String get discardConfirm => 'Discard';

  // --- Exportación ----------------------------------------------------------------
  @override
  String get chooseFormatTitle => 'Export as';
  @override
  String get wordOption => 'Word (.docx)';
  @override
  String get wordOptionHint => 'Editable document';
  @override
  String get pdfOption => 'PDF (.pdf)';
  @override
  String get pdfOptionHint => 'Document ready to read or print';
  @override
  String get saveDialogTitle => 'Save document';
  @override
  String get retry => 'Try again';

  // --- Compartir (spec 003, módulo 3) --------------------------------------------
  @override
  String get share => 'Share';

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
            ? 'Reading page $page of $pageCount…'
            : 'Reading the text…',
      StatusEvent.recognized =>
        'Text read. Review and correct it before exporting it.'
            '${emptyPagesText(status.emptyPages)}',
      StatusEvent.noTextFound =>
        'No text was found in the image. Try another image or a photo with better '
            'light and focus.',
      StatusEvent.consentDeclined =>
        'The image was not sent. You can allow sending it whenever you want to '
            'read the text.',
      StatusEvent.exporting => 'Creating the $format file…',
      StatusEvent.saved => 'The $format file was saved successfully.',
      StatusEvent.saveCancelled => 'The file was not saved. Your text is kept.',
      StatusEvent.draftRestored => 'The text you were editing was recovered.',
      StatusEvent.discarded => 'The text was discarded.',
      // Spec 004: con varias páginas, el fallo dice en cuál ocurrió.
      StatusEvent.failed =>
        '${page != null && pageCount > 1 ? '${pageOf(page, pageCount)}: ' : ''}'
            '${failureText(status.failure ?? const AppFailure(FailureKind.unexpected))}',
      StatusEvent.sessionExpired =>
        'Your session expired. Sign in again; the text you are editing is kept.',
      StatusEvent.signedOut => 'You signed out. See you soon!',
      StatusEvent.accountDeleted => 'Your account and your data were deleted.',
      StatusEvent.historyOpened =>
        'The saved document was opened. You can correct it and export it again.',
    };
  }

  /// Spec 004: « Page 2 had no text.» o « Pages 2 and 4 had no text.».
  @override
  String emptyPagesText(List<int> pages) {
    if (pages.isEmpty) return '';
    if (pages.length == 1) return ' Page ${pages.single} had no text.';
    final list =
        '${pages.sublist(0, pages.length - 1).join(', ')} and ${pages.last}';
    return ' Pages $list had no text.';
  }

  /// Mensaje de cada fallo: qué pasó y qué puede hacer el usuario.
  @override
  String failureText(AppFailure failure) => switch (failure.kind) {
    FailureKind.unsupportedImageType =>
      'The file is not a JPEG or PNG image. Choose another image.',
    FailureKind.imageTooLarge =>
      'The image is larger than the 10 MB limit. Choose another image.',
    FailureKind.imageDimensionsOutOfRange =>
      'The image must be between 600 and 10,000 pixels per side. Choose another '
          'image or retake the photo.',
    FailureKind.imageUnreadable =>
      'The image could not be opened; it may be damaged. Choose another image or '
          'retake the photo.',
    FailureKind.cameraPermissionDenied =>
      'Camera permission is needed to take the photo. You can grant it the next '
          'time you try, or choose a saved image.',
    FailureKind.cameraPermissionPermanentlyDenied =>
      'Camera permission is turned off. To take photos, turn it on in the phone '
          'settings (Apps > HandText AI > Permissions). Meanwhile, you can choose a '
          'saved image.',
    FailureKind.cameraUnavailable =>
      'The camera could not be opened. Try again or choose a saved image.',
    FailureKind.noConnection =>
      'There is no connection to the server. Check your internet connection and '
          'try again.',
    FailureKind.recognitionTimeout =>
      'Recognition took more than 60 seconds and was canceled. Try again.',
    FailureKind.serviceUnavailable =>
      'The recognition service is not available right now. Try again later.',
    FailureKind.recognitionFailed =>
      'The recognition service could not process the image. Try again or choose '
          'another image.',
    FailureKind.invalidServerResponse =>
      'The server responded unexpectedly. Try again.',
    FailureKind.emptyText =>
      'Empty text, or text with only spaces, cannot be exported. Type or review the '
          'text before exporting.',
    FailureKind.textTooLarge =>
      'The text is too long to export. Split it into smaller parts.',
    // R8: el detalle que manda la API está en español; aquí va el mensaje general.
    FailureKind.unsupportedCharacters =>
      'The text contains characters that cannot be included in the file. Remove '
          'them and try again.',
    FailureKind.exportFailed =>
      'The file could not be created. Your text is kept; try again.',
    FailureKind.exportTimeout =>
      'Creating the file took too long. Your text is kept; try again.',
    FailureKind.saveFailed =>
      'The file could not be saved. Your text is kept; try again.',
    FailureKind.missingCredentials => 'Enter your email and your password.',
    FailureKind.invalidDisplayName => 'Enter a name from 1 to 60 characters.',
    FailureKind.invalidEmail =>
      'Enter a valid email address, for example name@email.com.',
    FailureKind.weakPassword =>
      'The password must be between 8 and 128 characters.',
    FailureKind.passwordMismatch => 'The passwords do not match.',
    FailureKind.dataPolicyNotAccepted =>
      'To create the account you must authorize the processing of your data.',
    FailureKind.emailAlreadyRegistered =>
      'An account with that email already exists. Sign in or use another email.',
    FailureKind.invalidCredentials => 'Incorrect email or password.',
    FailureKind.tooManyAttempts =>
      'Too many failed attempts. For security, wait 15 minutes and try again.',
    FailureKind.sessionExpired => 'Your session expired. Sign in again.',
    FailureKind.accountsUnavailable =>
      'The account service is not available right now. Try again later.',
    FailureKind.backendAuthenticationRequired =>
      'The local API rejected the request. Check that it is running and that the '
          'test secret matches. Your local account is still active.',
    FailureKind.imageEditFailed =>
      'The image could not be cropped. The previous image is kept.',
    FailureKind.shareFailed => 'The share menu could not be opened. Try again.',
    FailureKind.scannerUnavailable =>
      'The document scanner is not available on this phone: it needs Google Play '
          'services. You can take a photo or choose a saved image.',
    FailureKind.scannerFailed =>
      'The page could not be scanned. Try again, take a photo or choose a saved '
          'image.',
    FailureKind.tooManyPages =>
      'A document can have up to 10 pages. Remove one to add another.',
    FailureKind.unexpected => 'An unexpected error occurred. Try again.',
  };
}
