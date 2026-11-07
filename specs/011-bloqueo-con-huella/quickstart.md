# Quickstart: bloqueo con huella o rostro

**Plan**: [plan.md](plan.md) | **Decisiones**: [research.md](research.md)

## 1. Pruebas

```powershell
cd frontend
flutter test test/presentation/app_lock_test.dart
```

## 2. Probarlo en el teléfono

1. El teléfono necesita una huella, el rostro o un bloqueo de pantalla (PIN, patrón o
   contraseña) configurado.
2. Menú de la cuenta > **Ajustes** > **Bloquear con huella o rostro**. La app pide la
   huella para confirmar.
3. Al cerrar y abrir la app, o al volver después de más de 1 minuto, aparece la pantalla
   de bloqueo y pide la huella. Mientras está bloqueada, no se ve ningún documento.

## 3. En el emulador

```powershell
adb shell locksettings set-pin 1234       # bloqueo de pantalla (necesario para la huella)
```

Para agregar una huella: Ajustes de Android > Seguridad > Huella digital. Cuando pida tocar
el sensor, ejecutar varias veces:

```powershell
adb -e emu finger touch 1
```

El mismo comando hace de «dedo» cuando la app pide la huella.

## 4. Privacidad

La huella y el rostro los verifica Android: la app solo recibe «sí» o «no».
