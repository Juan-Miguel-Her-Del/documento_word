// Punto de entrada de HandText AI (tareas T044 y T127).
//
// Aquí se «arma» la app con los servicios reales:
// - Cuentas y sesión: autenticación local y almacenamiento cifrado en el teléfono.
// - Documentos (spec 001): galería, cámara, permisos, red, guardado y borrador. Cada
//   cuenta recibe su propio controlador y su propio archivo de borrador [SC-206].
// - Spec 003: editor de recorte (uCrop) y compartir (selector de Android).
// - Spec 005: ajustes guardados en el teléfono (se leen antes de mostrar la app) y la
//   licencia de Poppins en «Licencias».
// - Spec 007: historial «Mis documentos» de cada cuenta, en su propio archivo.
// - Spec 009: escáner de documentos de Google ML Kit.
// - Spec 011: bloqueo con huella, rostro o el bloqueo de pantalla del teléfono.
// - Reconocimiento y exportación usan la API; las cuentas locales no requieren API.
// - Spec 008: los títulos del diálogo para guardar y del editor de recorte se leen en
//   el idioma actual (AppStrings.current) cada vez que se abren.
// Las pruebas arman lo mismo con versiones falsas de cada servicio, sin tocar el
// teléfono ni la red.
//
// Mapa rápido de lib/:
// - config/       URL de la API, tiempos y límites del spec.
// - models/       datos (imagen, fallos, formatos, cuenta, estados), sin interfaz.
// - services/     cuentas, imagen, cámara, red, guardado, sesión y borrador.
// - state/        AuthController (sesión) y DocumentFlowController (documentos).
// - presentation/ textos (español e inglés), pantallas y widgets del estilo Aurora.
// - theme/        colores Aurora y temas centralizados.

import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';

import 'app.dart';
import 'config/app_config.dart';
import 'presentation/strings.dart';
import 'services/camera_permission_service.dart';
import 'services/device_authenticator.dart';
import 'services/document_scanner_service.dart';
import 'services/draft_storage.dart';
import 'services/file_save_service.dart';
import 'services/handtext_api_client.dart';
import 'services/history_store.dart';
import 'services/image_editor_service.dart';
import 'services/image_rules.dart';
import 'services/image_source_service.dart';
import 'presentation/font_licenses.dart';
import 'services/local_auth_api.dart';
import 'services/session_store.dart';
import 'services/settings_store.dart';
import 'services/share_service.dart';
import 'services/working_copy_service.dart';
import 'state/app_lock_controller.dart';
import 'state/auth_controller.dart';
import 'state/document_flow_controller.dart';
import 'state/document_history.dart';
import 'state/settings_controller.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  registerFontLicenses(); // [SC-503]

  // Ajustes de este teléfono (spec 005): se leen antes de mostrar la app, para que el
  // tema elegido se vea desde la primera pantalla.
  final settings = SettingsController(
    store: FileSettingsStore(directory: getApplicationSupportDirectory),
  );
  await settings.load();

  // Cuentas de prueba locales (credenciales cifradas con Android Keystore).
  final auth = AuthController(
    api: LocalAuthApi(accounts: SecureLocalAccountStore()),
    sessions: SecureSessionStore(),
  );

  // El secreto local opt-in da acceso solo a OCR/export en el backend de desarrollo;
  // nunca se usa como sesión ni se envía a los endpoints de cuentas.
  final documentsApi = HandTextApiClient(baseUrl: AppConfig.apiBaseUrl);

  runApp(
    HandTextApp(
      auth: auth,
      settings: settings,
      // Spec 011 (research.md de 011, R1 y R3).
      lock: AppLockController(
        settings: settings,
        auth: auth,
        authenticator: LocalDeviceAuthenticator(),
      ),
      createDocumentController: (user, onSessionExpired) => DocumentFlowController(
        imageSource: PickerImageSourceService(),
        cameraPermission: const HandlerCameraPermissionService(),
        readImageDimensions: readImageDimensionsWithEngine,
        // Copias de trabajo en la caché privada de la app (research.md, R8).
        workingCopies: WorkingCopyService(
          cacheDirectory: getTemporaryDirectory,
        ),
        api: documentsApi,
        fileSaver: SystemFileSaver(
          dialogTitle: () => AppStrings.current.saveDialogTitle,
        ),
        // Borrador privado de ESTA cuenta (research.md de 002, R8).
        drafts: FileDraftStore(
          directory: getApplicationSupportDirectory,
          fileName: draftFileNameFor(user.id),
        ),
        // Spec 003: recorte y giro, y compartir (research.md de 003, R6 a R8).
        imageEditor: NativeImageEditor(
          title: () => AppStrings.current.imageEditorTitle,
        ),
        sharer: SystemDocumentSharer(cacheDirectory: getTemporaryDirectory),
        // Spec 009: escáner de documentos (research.md de 009, R1 y R2).
        scanner: const MlKitDocumentScanner(),
        // Spec 007: historial privado de ESTA cuenta (research.md de 007, R1).
        history: DocumentHistory(
          store: FileHistoryStore(
            directory: getApplicationSupportDirectory,
            fileName: historyFileNameFor(user.id),
          ),
        ),
        onSessionExpired: onSessionExpired,
      ),
    ),
  );
}
