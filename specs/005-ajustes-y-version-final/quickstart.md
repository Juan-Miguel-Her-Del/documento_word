# Quickstart: ajustes, «Acerca de» y versión final

**Plan**: [plan.md](plan.md) | **Decisiones**: [research.md](research.md)

## 1. Pruebas

```powershell
cd frontend
flutter test test/state/settings_test.dart test/presentation/settings_screens_test.dart
```

## 2. La clave de firma (una sola vez)

La versión final se firma con la clave del proyecto:
- `%USERPROFILE%\.handtext\handtext-release.jks`: la clave, fuera del repositorio;
- `frontend\android\key.properties`: las contraseñas. Git no lo sube (`android/.gitignore`).

**Guarde una copia de los dos archivos** en un lugar seguro (por ejemplo, un USB o un
gestor de contraseñas). Sin ellos no se puede firmar una actualización con la misma
clave.

Si se trabaja en otro computador, se copian los dos archivos. `storeFile` es la ruta de
la clave dentro de `key.properties`; se ajusta si cambia. Sin `key.properties`, la versión
release se firma con la clave de depuración y Gradle muestra una advertencia: ese APK no
se entrega.

## 3. Compilar la versión final

| Para qué | Comando (en `frontend`) | Resultado |
|----------|-------------------------|-----------|
| Entrega con la API publicada por HTTPS | `flutter build apk --release --split-per-abi --dart-define=API_BASE_URL=https://<servidor>/` | Solo permite HTTPS |
| Demostración con la API en el computador | `flutter build apk --release --split-per-abi -P permitirHttpLocal=true --dart-define=API_BASE_URL=http://<IP del computador>:8000/` | Permite HTTP (petición explícita) |

Los APK quedan en `frontend\build\app\outputs\flutter-apk\`:
- `app-arm64-v8a-release.apk`: casi todos los teléfonos actuales;
- `app-armeabi-v7a-release.apk`: teléfonos antiguos;
- `app-x86_64-release.apk`: emuladores.

Para instalar en un teléfono por USB:

```powershell
adb install frontend\build\app\outputs\flutter-apk\app-arm64-v8a-release.apk
```

Si antes estaba instalada la versión de depuración, primero hay que desinstalarla:
las firmas son distintas.

## 4. Validación manual

| Escenario | Pasos | Resultado esperado |
|-----------|-------|--------------------|
| AV-H1-E2 | Menú de cuenta → Ajustes → Oscuro; abrir el editor | El editor se ve oscuro aunque el teléfono esté en modo claro |
| AV-H1-E5 | Cerrar la app y abrirla | Los ajustes se conservan |
| AV-H2-E1 | Cerrar sesión → «Privacidad y acerca de» | Se abre sin iniciar sesión, con la versión 1.0.0 (1) |
| AV-H3-E1 | `apksigner verify --print-certs <apk>` | Firmante `CN=HandText AI` |
| SC-506 | `aapt2 dump xmltree --file AndroidManifest.xml <apk>` en el APK normal | `usesCleartextTraffic=false` |
