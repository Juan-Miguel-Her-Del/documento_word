# Quickstart: pruebas de punta a punta

**Plan**: [plan.md](plan.md) | **Decisiones**: [research.md](research.md)

## Qué hace

Un robot instala la app en el emulador (o en un teléfono) y la recorre sola, con la API y
la base de datos reales:
1. crea una cuenta;
2. elige una hoja (sintética), autoriza el envío y llega al editor;
3. corrige el texto y lo guarda como Word (generado por la API);
4. lo encuentra en Mis documentos;
5. cierra sesión, vuelve a entrar y lo encuentra otra vez.

Solo se simulan el reconocimiento (falta la clave de Google) y las pantallas de Android
(selector de fotos y diálogo para guardar).

## Cómo se ejecuta

1. Encender la API local (README, «Cómo ejecutarlo»).
2. Abrir el emulador.
3. En `frontend`:

```powershell
flutter test integration_test -d emulator-5554 --dart-define=API_BASE_URL=http://10.0.2.2:8000/
```

Al terminar, la consola muestra cuánto tardó cada paso (`PASO …`) y el total. Cada
ejecución crea una cuenta con un correo distinto (`e2e<hora>@correo.com`), así se puede
repetir. Al final cierra la sesión y borra sus carpetas.

## En un teléfono por USB

Gasta menos memoria del computador que el emulador.

1. En el teléfono: Ajustes > Acerca del teléfono, tocar 7 veces «Número de compilación».
   Luego, en Opciones de desarrollador, activar **Depuración por USB**.
2. Conectarlo por cable y aceptar el aviso «¿Permitir la depuración por USB?».
   `flutter devices` debe mostrarlo.
3. Encender la API local (README, «Cómo ejecutarlo»).
4. Hacer que el teléfono llegue a la API por el cable, sin Wi-Fi ni firewall:

```powershell
adb reverse tcp:8000 tcp:8000
```

5. En `frontend`, con el identificador que muestra `flutter devices`:

```powershell
flutter test integration_test -d <identificador> --dart-define=API_BASE_URL=http://127.0.0.1:8000/
```

El mismo teléfono sirve para probar el escáner (009) y el bloqueo con huella (011), que
el emulador no pudo mostrar: ver sus quickstart.
