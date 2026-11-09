// Configuración de la app (tarea T012).
//
// Reúne en un solo lugar:
// - La URL de la API, que se elige al compilar con `--dart-define` (research.md, R12).
// - Los tiempos de espera: 60 segundos (spec, módulo 2 y SC-009).
// - Los límites de imagen acordados en el spec (módulo 1). Son los mismos que valida
//   el backend en backend/app/config.py.

abstract final class AppConfig {
  /// Spec 005 (R4): versión que muestra «Acerca de». Debe ser igual a `version:` de
  /// pubspec.yaml (1.0.0+1); una prueba lo comprueba [SC-502].
  static const String appVersion = '1.0.0';
  static const int appBuild = 1;

  /// URL base de la API. Ejemplos:
  /// - Emulador de Android: `http://10.0.2.2:8000/` (valor por defecto; 10.0.2.2 es
  ///   el computador visto desde el emulador).
  /// - Teléfono real en la misma red Wi-Fi: `http://192.168.1.50:8000/`.
  ///
  /// Se cambia al ejecutar:
  /// `flutter run --dart-define=API_BASE_URL=http://192.168.1.50:8000/`
  static final Uri apiBaseUrl = _withTrailingSlash(
    const String.fromEnvironment(
      'API_BASE_URL',
      defaultValue: 'http://10.0.2.2:8000/',
    ),
  );

  /// Secreto de uso exclusivo para desarrollo local; vacío por defecto.
  static const String localDevApiToken = String.fromEnvironment(
    'LOCAL_DEV_API_TOKEN',
  );

  /// Tiempo máximo de espera del reconocimiento (SC-009).
  static const Duration recognitionTimeout = Duration(seconds: 60);

  /// Tiempo máximo de espera de la generación del archivo Word o PDF.
  static const Duration exportTimeout = Duration(seconds: 60);

  /// Tiempo máximo de espera de las operaciones de cuenta (spec 002). Es igual al
  /// del reconocimiento porque, en el plan gratuito de Render, la API se apaga tras
  /// 15 minutos sin uso y tarda cerca de un minuto en despertar: con 20 segundos, el
  /// primer registro o ingreso fallaba con «sin conexión».
  static const Duration authTimeout = Duration(seconds: 60);

  /// Límites de imagen del spec (módulo 1, Clarifications 2026-10-26).
  static const int maxImageBytes = 10 * 1024 * 1024; // 10 MB
  static const int minImageSidePx = 600;
  static const int maxImageSidePx = 10000;

  /// Spec 004 (supuesto 1): máximo de páginas por documento.
  static const int maxPages = 10;

  /// Spec 007 (supuesto 2): máximo de documentos en el historial de una cuenta.
  static const int maxHistoryEntries = 50;

  /// Pausa tras la última tecla antes de guardar el borrador (research.md, R7).
  static const Duration draftSaveDelay = Duration(milliseconds: 400);

  /// `Uri.resolve` necesita la barra final para conservar la ruta base.
  static Uri _withTrailingSlash(String url) =>
      Uri.parse(url.endsWith('/') ? url : '$url/');
}
