# Research: Ajustes, «Acerca de» y versión final

## R1. Dónde se guardan los ajustes

- **Decisión**: un archivo `settings.json` en la carpeta privada de soporte de la app
  (la misma del borrador), con escritura atómica.
  - Se lee con path_provider, que ya es una dependencia.
  - Si el archivo falta o está dañado, se usan los valores por omisión
    ([AV-H1-E6]).
- **Alternativas descartadas**:
  - *shared_preferences*: sería una dependencia nueva para guardar dos valores.
  - *flutter_secure_storage*: los ajustes no son secretos.

## R2. Tema

- **Decisión**: `MaterialApp.themeMode` toma el ajuste: `system`, `light` o `dark`.
  - Las pantallas Aurora ya usan su propio tema oscuro (`AppTheme.onAurora`), así que no
    cambian (supuesto 3).
  - El cambio se aplica al instante, sin reiniciar la app.

## R3. Tamaño de letra del editor

- **Decisión**: un factor (1,0, 1,2 o 1,4) que multiplica el tamaño del estilo del
  editor. Flutter aplica además el tamaño de letra del sistema (`TextScaler`), así que
  ambos se suman.
- Se aplica solo al texto del documento: los botones y avisos siguen el sistema, para no
  romper la disposición de la pantalla.

## R4. Versión visible

- **Decisión**: constantes `AppConfig.appVersion` y `AppConfig.appBuild`.
  - Una prueba lee `pubspec.yaml` y comprueba que coinciden (SC-502).
  - Gradle toma la versión del paquete de ese mismo `pubspec.yaml`.
- **Alternativa descartada**: package_info_plus (dependencia nueva) para leer un dato
  que ya está en el proyecto.

## R5. Licencias

- **Decisión**:
  - `showLicensePage` de Flutter lista las licencias de Flutter y de todas las
    librerías.
  - La de Poppins (OFL) se registra al arrancar con `LicenseRegistry.addLicense`, desde
    `assets/fonts/OFL-Poppins.txt`, que pasa a incluirse en la app (SC-503).

## R6. Texto de privacidad

- **Decisión**: un resumen en lenguaje simple de las reglas ya especificadas:
  - autorización y no conservación de imágenes (001, módulo 6);
  - borrador local (001, Clarifications);
  - cuenta y su eliminación (002);
  - copias temporales de recorte y para compartir (003, R8);
  - páginas (004, R7).

  No agrega reglas nuevas.

## R7. Firma de la versión final

- **Decisión**:
  - **Clave**: un almacén PKCS12 creado con `keytool`, guardado fuera del proyecto en
    `%USERPROFILE%\.handtext\handtext-release.jks`.
  - **Contraseñas**: van en `frontend/android/key.properties`, que el `.gitignore` de
    Android ya excluye (junto con `*.jks`).
  - **Gradle**: `build.gradle.kts` lee ese archivo y firma la versión release.
  - **Sin el archivo**: firma con la clave de depuración y deja una advertencia (caso
    límite del spec).
- **Respaldo**: la persona responsable debe guardar una copia de la clave y de
  `key.properties`. Sin ellas no se puede publicar una actualización firmada igual.

## R8. HTTPS en la versión final

- **Decisión**:
  - **Valor por omisión**: el manifiesto principal usa
    `android:usesCleartextTraffic="${usesCleartextTraffic}"`. Gradle lo deja en `false`
    para release (SC-506) y en `true` para debug, como ya hacía `src/debug`.
  - **Demostración local**: se compila con
    `flutter build apk --release -P permitirHttpLocal=true` y la URL de la API del
    computador. Esa es la petición explícita del spec.

## R9. Tamaño y arranque

- **Decisión**:
  - **Compilación**: `flutter build apk --release --split-per-abi`, con el R8 de Flutter.
  - **Tamaño**: cada APK incluye solo el código de su procesador.
  - **Arranque**: se mide con `adb shell am start -W` en el emulador de referencia
    (SC-504).
