// Textos de la interfaz (tarea T014; spec 008, tarea T701; research.md de 008, R1 y
// R2).
//
// Esta clase abstracta declara TODOS los textos y mensajes de la app. Cada idioma tiene
// su archivo de traducción:
// - strings_es.dart: español, el idioma inicial (constitución §4);
// - strings_en.dart: inglés (spec 008).
// Si a un idioma le falta un texto, la app no compila [SC-801].
//
// Las pantallas los leen con context.strings (o AppStrings.of(context)). Al cambiar el
// idioma en Ajustes, Flutter vuelve a dibujar lo que los usa, sin reiniciar la app
// [IE-H1-E2].
// Constitución §5 y spec 001, módulo 5: cada mensaje de error dice qué pasó y qué puede
// hacer el usuario, sin trazas, rutas internas ni credenciales.
// Si la profesora pregunta «¿dónde están los mensajes?», están en esos dos archivos.

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

import '../models/app_failure.dart';
import '../models/history_entry.dart';
import '../models/operation_status.dart';
import '../models/picked_image.dart';
import 'strings_en.dart';
import 'strings_es.dart';

abstract class AppStrings {
  const AppStrings();

  /// Idiomas de la interfaz: español (el inicial) e inglés.
  static const supportedLocales = [Locale('es'), Locale('en')];

  /// [IE-H1-E3] Textos de [locale]: inglés si el idioma es inglés; español en cualquier
  /// otro caso.
  static AppStrings forLocale(Locale locale) =>
      locale.languageCode == 'en' ? const AppStringsEn() : const AppStringsEs();

  /// Textos del idioma actual, para los servicios que no tienen pantalla (el diálogo
  /// para guardar y el editor de recorte; research.md de 008, R3). Lo actualiza el
  /// delegado cada vez que carga un idioma.
  static AppStrings current = const AppStringsEs();

  /// Textos del idioma de la pantalla. Quien los pide se vuelve a dibujar si el idioma
  /// cambia.
  static AppStrings of(BuildContext context) =>
      Localizations.of<AppStrings>(context, AppStrings)!;

  /// Nombres de los idiomas: siempre en su propio idioma, para que se reconozcan
  /// aunque no se entienda la app (research.md de 008, R9).
  static const spanishName = 'Español';
  static const englishName = 'English';

  /// Entrega los textos a MaterialApp, como los textos propios de Flutter.
  static const LocalizationsDelegate<AppStrings> delegate =
      _AppStringsDelegate();

  String get appName;

  // --- Bienvenida (spec 002, módulo 1) ------------------------------------------
  String get welcomeTagline;
  String get welcomeStep1;
  String get welcomeStep2;
  String get welcomeStep3;
  String get createAccount;
  String get haveAccount;
  String get welcomePrivacyNote;
  String get back;

  // --- Ingreso y registro (spec 002, módulos 1 y 2) -----------------------------
  String get loginTitle;
  String get loginSubtitle;
  String get registerTitle;
  String get registerSubtitle;
  String get nameLabel;
  String get emailLabel;
  String get passwordLabel;
  String get confirmPasswordLabel;
  String get passwordHint;
  String get showPassword;
  String get hidePassword;
  String get signIn;
  String get noAccountQuestion;
  String get createAccountLink;
  String get haveAccountQuestion;
  String get dataPolicyConsent;

  /// Nivel de seguridad de la contraseña (0 débil, 1 aceptable, 2 fuerte).
  String passwordStrength(int level);

  // --- Ajustes y Acerca de (spec 005) ------------------------------------------
  String get settingsTitle;
  String get aboutTitle;
  String get privacyTitle;
  String get licensesTitle;
  String get privacyAndAbout;
  String get themeSection;
  String get themeSystem;
  String get themeLight;
  String get themeDark;
  String get themeHint;
  String get textSizeSection;
  String get textSizeNormal;
  String get textSizeLarge;
  String get textSizeExtraLarge;
  String get textSizePreview;
  String get settingsSavedHint;

  /// «Versión 1.0.0 (1)».
  String version(String name, int build);
  String get aboutDescription;
  String get aboutPrivacyHint;
  String get aboutLicensesHint;

  /// Privacidad (R6 de 005): resumen de las reglas de 001 a 011, sección por sección.
  List<(String, String)> get privacySections;

  // --- Idioma (spec 008) ----------------------------------------------------------
  String get languageSection;
  String get languageSystem;
  String get languageHint;
  String get languageTooltip;

  // --- Consejos para una buena foto (spec 006, módulo 1) ------------------------
  String get tipsLink;
  String get tipsLinkHint;
  String get tipsSkip;
  String get tipsNext;
  String get tipsStart;

  /// «Consejo 2 de 4» [PA-H2-E4].
  String tipOf(int tip, int count);

  /// Los cuatro consejos (título y texto), en orden.
  List<(String, String)> get tips;

  // --- Mis documentos (spec 007) ---------------------------------------------------
  String get historyTitle;

  /// Subtítulo del acceso en el inicio.
  String historyCount(int count);
  String get historyEmptyTitle;
  String get historyEmptyMessage;
  String get historyClearAll;

  /// Nombre del botón de cada documento para TalkBack: «Eliminar Apuntes».
  String historyDelete(String title);
  String get historyOpenTitle;
  String get historyOpenMessage;
  String get historyOpenConfirm;
  String get historyDeleteTitle;
  String historyDeleteMessage(String title);
  String get historyDeleteConfirm;
  String get historyClearTitle;
  String historyClearMessage(int count);
  String get historyClearConfirm;

  /// Detalles de un documento: «29 oct 2026, 15:30 · Word y PDF · 120 palabras».
  String historyDetails(HistoryEntry entry);

  /// Fecha corta en español, sin paquetes (research.md de 007, R6):
  /// «29 oct 2026, 15:30».
  String shortDate(DateTime moment);

  // --- Cuenta (spec 002, módulos 2 y 4) -----------------------------------------
  String get accountTooltip;
  String get signOut;
  String get signOutTitle;
  String get signOutUnexportedMessage;
  String get deleteAccount;
  String get deleteAccountTitle;
  String get deleteAccountMessage;
  String get deleteAccountConfirm;

  /// Saludo del inicio: «Hola, Ana».
  String greeting(String firstName);

  // --- Pantalla de inicio -------------------------------------------------------
  String get startTitle;
  String get startDescription;
  String get takePhoto;
  String get pickFromGallery;
  String get imageRequirements;
  String get startHeadline;
  String get takePhotoSubtitle;
  String get pickFromGallerySubtitle;
  String get documentInProgress;
  String get keepCurrentTextNotice;
  String get backToCurrentText;

  // --- Vista previa ---------------------------------------------------------------
  String get previewTitle;
  String get acceptAndRecognize;
  String get chooseAnotherImage;
  String get retakePhoto;
  String get cancel;
  String get cancelSelectionTooltip;
  String get recognizingHint;
  String get imagePreviewUnavailable;

  // --- Varias páginas (spec 004) -------------------------------------------------
  /// «Página 2 de 3».
  String pageOf(int page, int count);

  /// Botón principal con varias páginas: «Reconocer 3 páginas».
  String recognizePages(int count);
  String get addPage;
  String get addPageFromCamera;
  String get addPageFromGallery;
  String get movePageBefore;
  String get movePageAfter;
  String get removePage;

  /// Descripción de una miniatura para los lectores de pantalla.
  String pageThumbnail(int page, bool selected);
  String get readingHandwriting;

  /// Datos de la imagen bajo la vista previa: «JPEG · 3024 × 4032 px · 2,4 MB».
  String imageDetails(PickedImage image);

  /// Tamaño legible con coma decimal: «850 KB», «2,4 MB».
  String formatBytes(int bytes);

  /// Texto del botón que reemplaza la imagen, según su origen.
  String replaceImageLabel(ImageOrigin origin);

  // --- Bloqueo con huella o rostro (spec 011) ------------------------------------
  String get appLockTitle;
  String get appLockHint;
  String get appLockUnavailable;
  String get enableLockReason;
  String get unlockReason;
  String get lockedTitle;
  String get lockedMessage;
  String get unlock;

  // --- Organizar documentos (spec 010) ------------------------------------------
  String get copyAllText;
  String get textCopied;
  String get historySearchHint;
  String historyNoResults(String query);
  String historyRename(String title);
  String get historyRenameTitle;
  String get historyRenameLabel;
  String get historyRenameConfirm;

  // --- Escáner de documentos (spec 009) -----------------------------------------
  String get scanDocument;
  String get scanDocumentSubtitle;
  String get addPageFromScanner;
  String get rescanImage;

  // --- Recorte y giro (spec 003, módulo 2) ---------------------------------------
  String get editImage;
  String get imageEditorTitle;
  String get restoreOriginalImage;

  // --- Autorización de envío (spec, módulo 6; supuesto 5) --------------------------
  String get consentTitle;
  String get consentMessage;

  /// Spec 004: la autorización dice cuántas imágenes se enviarán.
  String consentTitleFor(int images);
  String consentMessageFor(int images);
  String get consentAccept;
  String get consentDecline;

  // --- Editor ---------------------------------------------------------------------
  String get editorTitle;
  String get recognitionWarning;
  String get editorSubtitle;
  String get editorLabel;

  /// Contador del editor: «12 palabras · 80 caracteres».
  String textStats(int words, int characters);
  String get editorHint;

  // --- Palabras dudosas (spec 003, módulo 1) -------------------------------------
  /// Barra de revisión: «3 palabras para revisar».
  String uncertainWordsCount(int count);

  /// Guía cuando no hay ninguna palabra dudosa seleccionada.
  String get uncertainWordsHint;

  /// Guía cuando hay una palabra dudosa seleccionada.
  String get acceptUncertainWordHint;
  String get nextUncertainWord;

  /// Spec 006: lo que TalkBack lee al ir a una palabra dudosa [PA-H2-E3].
  String uncertainWordAnnouncement(String word);
  String get acceptUncertainWord;
  String get export;
  String get moreActionsTooltip;
  String get processAnotherImage;
  String get discardText;

  // --- Confirmaciones (spec, módulo 3) ------------------------------------------
  String get replaceTextTitle;
  String get replaceTextMessage;
  String get replaceTextConfirm;
  String get discardTitle;
  String get discardMessage;
  String get discardConfirm;

  // --- Exportación ----------------------------------------------------------------
  String get chooseFormatTitle;
  String get wordOption;
  String get wordOptionHint;
  String get pdfOption;
  String get pdfOptionHint;
  String get saveDialogTitle;
  String get retry;

  // --- Compartir (spec 003, módulo 3) --------------------------------------------
  String get share;

  // --- Mensajes de estado (spec, módulo 5) -------------------------------------
  /// Texto de un aviso de estado.
  String statusText(OperationStatus status);

  /// Spec 004: « La página 2 no tenía texto.» o « Las páginas 2 y 4 no tenían texto.».
  String emptyPagesText(List<int> pages);

  /// Mensaje de cada fallo: qué pasó y qué puede hacer el usuario.
  String failureText(AppFailure failure);
}

class _AppStringsDelegate extends LocalizationsDelegate<AppStrings> {
  const _AppStringsDelegate();

  /// Cualquier idioma se puede cargar: los que no son inglés usan el español.
  @override
  bool isSupported(Locale locale) => true;

  @override
  Future<AppStrings> load(Locale locale) {
    final strings = AppStrings.forLocale(locale);
    AppStrings.current = strings;
    return SynchronousFuture(strings);
  }

  @override
  bool shouldReload(_AppStringsDelegate old) => false;
}

/// `context.strings.takePhoto`: los textos del idioma actual de la app.
extension AppStringsContext on BuildContext {
  AppStrings get strings => AppStrings.of(this);
}
