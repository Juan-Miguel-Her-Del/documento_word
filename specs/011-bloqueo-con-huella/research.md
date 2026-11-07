# Research: Bloqueo con huella o rostro

Decisiones técnicas de la funcionalidad 011. Cada una indica la alternativa descartada.

## R1. Biblioteca

**Decisión**: `local_auth` 3.0.1, el paquete oficial de Flutter, que usa el
`BiometricPrompt` de Android:
- con `biometricOnly: false` acepta huella, rostro o el bloqueo de pantalla del teléfono
  (supuesto 3);
- `isDeviceSupported()` dice si el teléfono tiene alguno configurado [BL-H1-E4];
- la app solo recibe «sí» o «no»; la huella nunca le llega.

`local_auth` en Android exige que `MainActivity` herede de `FlutterFragmentActivity`. El
escáner (009), la cámara y los demás complementos funcionan igual con ella.

**Alternativa**: un PIN propio. Habría que guardarlo y protegerlo; el del teléfono ya
existe y está protegido por Android.

## R2. Dónde se guarda el ajuste

**Decisión**: un campo `appLock` en `settings.json` (spec 005), `false` por omisión
[SC-1104].

## R3. Cuándo se bloquea

**Decisión**: un controlador del bloqueo observa el ciclo de vida de la app:
- al abrir con sesión y el bloqueo activo, empieza bloqueada [BL-H2-E1];
- al pasar a segundo plano anota la hora y, al volver, se bloquea si pasó más de 1 minuto
  (supuesto 2) [BL-H2-E4].

La hora se inyecta para probar sin esperar.

## R4. Qué se ve bloqueado

**Decisión**: `AppLockGate`, en `MaterialApp.builder` (`app.dart`), pone la pantalla de
bloqueo encima de **todas** las pantallas y oculta la app con `Offstage`. Así también
quedan tapados el editor, Mis documentos, Ajustes y los diálogos abiertos, que son rutas
encima de la zona con sesión. La app oculta no se destruye: al desbloquear, todo sigue
donde estaba [SC-1103]. Sin sesión no se bloquea, así que la bienvenida se ve [BL-H2-E5].

**Alternativa descartada**: mostrar el bloqueo dentro de la zona con sesión
(`SignedInScope`, la primera idea del plan). Las pantallas abiertas encima, como el
editor, seguirían a la vista.

## R5. Pruebas

**Decisión**: una interfaz `DeviceAuthenticator` con la versión de `local_auth` y una
falsa para las pruebas. En el emulador: PIN con `adb shell locksettings set-pin`, huella
registrada desde Ajustes y toques de huella con `adb emu finger touch`.
