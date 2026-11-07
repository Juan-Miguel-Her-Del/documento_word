// Fallos que la app sabe explicar al usuario (tarea T015).
//
// Constitución §5 (UI): cada fallo tiene un mensaje (failureText, en
// presentation/strings_es.dart y strings_en.dart) que dice qué pasó y qué puede hacer
// el usuario. Nunca se muestran trazas, rutas internas ni respuestas técnicas del
// servidor.

/// Tipos de fallo, agrupados por la etapa del flujo en la que ocurren.
enum FailureKind {
  // Selección de la imagen (spec, módulo 1; Historia 1, escenario 1).
  /// El archivo no es JPEG ni PNG (se mira su contenido, no la extensión).
  unsupportedImageType,
  /// La imagen pesa más de 10 MB.
  imageTooLarge,
  /// La imagen mide menos de 600 o más de 10 000 píxeles por lado.
  imageDimensionsOutOfRange,
  /// La imagen no se pudo abrir: puede estar dañada.
  imageUnreadable,
  // Cámara (Historia 2).
  /// La persona negó el permiso de cámara; se puede volver a pedir.
  cameraPermissionDenied,
  /// El permiso de cámara quedó negado del todo: solo se activa en los ajustes
  /// del teléfono.
  cameraPermissionPermanentlyDenied,
  /// La cámara no se pudo abrir.
  cameraUnavailable,
  // Conexión y reconocimiento (spec, módulos 2 y 5; Historia 1, escenario 8).
  /// No hay conexión con el servidor (sin internet o la API apagada).
  noConnection,
  /// El reconocimiento tardó más de 60 segundos y se canceló.
  recognitionTimeout,
  /// El servicio de reconocimiento de Google no está disponible ahora.
  serviceUnavailable,
  /// El servicio de reconocimiento no pudo procesar la imagen.
  recognitionFailed,
  /// El servidor respondió algo que la app no esperaba.
  invalidServerResponse,
  // Exportación y guardado (spec, módulo 4; Historia 1, escenarios 10 y 12).
  /// Se intentó exportar un texto vacío o que solo tiene espacios.
  emptyText,
  /// El texto supera el máximo que la API acepta para exportar.
  textTooLarge,
  /// El texto tiene caracteres que no caben en el archivo; [AppFailure.detail]
  /// dice cuáles.
  unsupportedCharacters,
  /// La API no pudo generar el archivo Word o PDF.
  exportFailed,
  /// Generar el archivo tardó demasiado.
  exportTimeout,
  /// No se pudo guardar el archivo en el teléfono.
  saveFailed,
  // Cuentas de usuario (spec 002).
  /// Al ingresar, faltan el correo o la contraseña.
  missingCredentials,
  /// El nombre está vacío o pasa de 60 caracteres.
  invalidDisplayName,
  /// El correo no tiene la forma nombre@dominio.
  invalidEmail,
  /// La contraseña tiene menos de 8 o más de 128 caracteres.
  weakPassword,
  /// La contraseña y su confirmación no coinciden.
  passwordMismatch,
  /// Al crear la cuenta, no se autorizó el tratamiento de los datos.
  dataPolicyNotAccepted,
  /// Ya existe una cuenta con ese correo.
  emailAlreadyRegistered,
  /// Correo o contraseña incorrectos. No se dice cuál de los dos falló, para no
  /// revelar qué correos tienen cuenta.
  invalidCredentials,
  /// Demasiados intentos fallidos: la cuenta se bloquea 15 minutos.
  tooManyAttempts,
  /// La sesión venció; hay que ingresar de nuevo.
  sessionExpired,
  /// El servicio de cuentas (la API o su base de datos) no responde.
  accountsUnavailable,
  // Recorte y compartir (spec 003).
  /// El recorte o el giro falló; se conserva la imagen anterior.
  imageEditFailed,
  /// No se pudo abrir el menú de Android para compartir.
  shareFailed,
  // Varias páginas (spec 004).
  /// El documento ya tiene 10 páginas, el máximo.
  tooManyPages,

  /// Spec 009: el escáner de documentos no se puede abrir en este teléfono (sin
  /// servicios de Google Play) [ED-H2-E1].
  scannerUnavailable,

  /// Spec 009: el escáner falló [ED-H2-E2].
  scannerFailed,
  /// Cualquier otra situación imprevista: se pide volver a intentarlo.
  unexpected,
}

/// Fallo con su tipo y, si aplica, un detalle seguro de mostrar.
class AppFailure implements Exception {
  const AppFailure(this.kind, {this.detail});

  /// Qué falló. Define el mensaje que ve la persona (failureText).
  final FailureKind kind;

  /// Detalle redactado por la API (por ejemplo, qué caracteres no se pueden
  /// exportar). Nunca contiene rutas, trazas ni credenciales.
  final String? detail;

  /// Indica si tiene sentido ofrecer «Reintentar» la misma operación.
  bool get isRetryable => switch (kind) {
    FailureKind.noConnection ||
    FailureKind.recognitionTimeout ||
    FailureKind.serviceUnavailable ||
    FailureKind.recognitionFailed ||
    FailureKind.invalidServerResponse ||
    FailureKind.exportFailed ||
    FailureKind.exportTimeout ||
    FailureKind.saveFailed ||
    FailureKind.shareFailed ||
    FailureKind.unexpected => true,
    _ => false,
  };

  @override
  String toString() => 'AppFailure($kind)';
}
