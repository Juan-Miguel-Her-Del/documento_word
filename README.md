# HandText AI

Aplicación Android que convierte documentos escritos a mano en texto digital. La persona
crea su cuenta, fotografía o elige la imagen, autoriza su envío, revisa y corrige el texto
reconocido y lo guarda como Word (.docx) o PDF (.pdf). Todas las pantallas usan el
estilo visual «Aurora», con la paleta «azul corporativo»: fondo azul marino, botones
azul sólido y tarjetas con borde fino. Los colores están en
[aurora.dart](frontend/lib/theme/aurora.dart).

El proyecto sigue *Spec-Driven Development* con Spec Kit: la
[constitución](.specify/memory/constitution.md) fija las reglas, los specs definen qué se
construye y el código implementa sus tareas.

| Funcionalidad | Spec | Tareas |
|---------------|------|--------|
| 001 — MVP: captura, reconocimiento, edición y exportación | [spec](specs/001-handtext-mvp/spec.md) | [tasks](specs/001-handtext-mvp/tasks.md) |
| 002 — Cuentas de usuario e identidad visual Aurora | [spec](specs/002-cuentas-de-usuario/spec.md) | [tasks](specs/002-cuentas-de-usuario/tasks.md) |
| 003 — Palabras dudosas, recorte y giro, y compartir | [spec](specs/003-revision-recorte-compartir/spec.md) | [tasks](specs/003-revision-recorte-compartir/tasks.md) |
| 004 — Varias páginas por documento (hasta 10) | [spec](specs/004-varias-paginas/spec.md) | [tasks](specs/004-varias-paginas/tasks.md) |
| 005 — Ajustes, «Acerca de» y versión final firmada | [spec](specs/005-ajustes-y-version-final/spec.md) | [tasks](specs/005-ajustes-y-version-final/tasks.md) |
| 006 — Consejos para una buena foto y accesibilidad (TalkBack y letra grande) | [spec](specs/006-primer-uso-y-accesibilidad/spec.md) | [tasks](specs/006-primer-uso-y-accesibilidad/tasks.md) |
| 007 — Historial «Mis documentos» (solo en el teléfono) | [spec](specs/007-historial-de-documentos/spec.md) | [tasks](specs/007-historial-de-documentos/tasks.md) |
| 008 — App en inglés (textos en archivos de traducción) | [spec](specs/008-idioma-ingles/spec.md) | [tasks](specs/008-idioma-ingles/tasks.md) |
| 009 — Escáner de documentos (bordes, enderezado y filtros) | [spec](specs/009-escaner-de-documentos/spec.md) | [tasks](specs/009-escaner-de-documentos/tasks.md) |
| 010 — Nombre del archivo, copiar el texto, y buscar y renombrar en Mis documentos | [spec](specs/010-organizar-documentos/spec.md) | [tasks](specs/010-organizar-documentos/tasks.md) |
| 011 — Bloqueo con huella o rostro | [spec](specs/011-bloqueo-con-huella/spec.md) | [tasks](specs/011-bloqueo-con-huella/tasks.md) |
| 012 — Pruebas de punta a punta en el emulador | [spec](specs/012-pruebas-de-punta-a-punta/spec.md) | [tasks](specs/012-pruebas-de-punta-a-punta/tasks.md) |

## Estructura

| Carpeta | Contenido |
|---------|-----------|
| [frontend/](frontend/) | App Flutter (Dart) para Android. En `tool/`, el generador del ícono |
| [backend/](backend/) | API REST en Python con FastAPI: cuentas, validación, reconocimiento con Google Cloud Vision y generación de Word y PDF. En `tools/`, la medición de la calidad del reconocimiento (SC-010) |
| [db/](db/) | Migraciones SQL de PostgreSQL y preparación de la base local |
| [specs/](specs/) | Specs, planes, investigación, modelos de datos, contratos, guías y tareas |
| [MAPA_DEL_CODIGO.md](MAPA_DEL_CODIGO.md) | Dónde está el código de cada requisito y qué prueba lo verifica |

## Cómo ejecutarlo

### Prueba local con cuentas guardadas en el teléfono

No hace falta desplegar ni iniciar PostgreSQL. Las cuentas se crean en el teléfono y la
API local solo recibe las solicitudes de reconocimiento y exportación. Para autorizar
esas dos rutas durante el desarrollo, tanto la API como la app usan el mismo secreto
temporal. La opción está desactivada por defecto; no la habilite en un servidor público
ni comparta el secreto.

El OCR actual usa Google Cloud Vision. Gemini Plus no proporciona una clave de API para
este proyecto: se necesita una clave de Google Cloud con Vision API habilitada y la
facturación/configuración correspondiente. La imagen se envía desde la API local a
Google Vision para reconocerla; el modo local no significa OCR sin internet.

1. En Google Cloud Console, crea un proyecto, habilita **Cloud Vision API** y crea una
   API key restringida a esa API. No compartas la clave ni la incluyas en el código.
2. En la primera terminal de PowerShell:

   ```powershell
   cd D:\Flutter2\documento_word\backend
   $rng = [Security.Cryptography.RandomNumberGenerator]::Create()
   $bytes = New-Object byte[] 32
   $rng.GetBytes($bytes)
   $env:HANDTEXT_LOCAL_DEV_TOKEN = [Convert]::ToBase64String($bytes)
   $rng.Dispose()
   $env:HANDTEXT_GOOGLE_VISION_API_KEY = "<tu clave de Cloud Vision>"
   $env:HANDTEXT_LOCAL_DEV_TOKEN
   .venv\Scripts\python -m uvicorn app.main:app --host 0.0.0.0 --port 8000
   ```

   Copia el secreto que imprimió el tercer comando. Si aún no instalaste las dependencias,
   sigue primero el paso de instalación de la sección siguiente. Permite el puerto 8000
   solo en la red privada de confianza; no publiques la API en internet.
3. En otra terminal, desde `frontend`, ejecuta en el emulador:

   ```powershell
   cd D:\Flutter2\documento_word\frontend
   flutter pub get
   flutter run --dart-define="API_BASE_URL=http://10.0.2.2:8000/" --dart-define="LOCAL_DEV_API_TOKEN=<pega aquí el secreto>"
   ```

   En un teléfono físico, cambia `10.0.2.2` por la IP local del computador y conecta
   ambos dispositivos a la misma Wi-Fi. El cortafuegos de Windows debe permitir el puerto
   8000 en la red privada.

El secreto solo habilita reconocimiento y exportación; no habilita registro, ingreso ni
otras rutas de cuentas. Mantén ambas terminales locales y no uses este modo al compilar
una versión para distribuir.

Los pasos completos están en los quickstart de
[001](specs/001-handtext-mvp/quickstart.md),
[002](specs/002-cuentas-de-usuario/quickstart.md),
[003](specs/003-revision-recorte-compartir/quickstart.md),
[004](specs/004-varias-paginas/quickstart.md) y
[005](specs/005-ajustes-y-version-final/quickstart.md). Resumen en PowerShell:

```powershell
# 1. Base de datos (una sola vez, en el PostgreSQL 17 instalado)
& "C:\Program Files\PostgreSQL\17\bin\psql.exe" -U postgres -v clave="una-clave-segura" -f db/setup_local_database.sql

# 2. API
cd backend
python -m venv .venv
.venv\Scripts\python -m pip install -r requirements-dev.txt
$env:HANDTEXT_DATABASE_URL = "postgresql://handtext:una-clave-segura@localhost:5432/handtext"
$env:HANDTEXT_GOOGLE_VISION_API_KEY = "<su clave>"   # sin clave, el reconocimiento responde 503
$env:HANDTEXT_LOCAL_DEV_TOKEN = "<el mismo secreto aleatorio de la sección anterior>"
.venv\Scripts\python -m app.persistence.migrations
.venv\Scripts\python -m uvicorn app.main:app --host 0.0.0.0 --port 8000

# 3. App (en otra terminal, con el emulador abierto)
cd frontend
flutter pub get
flutter run --dart-define=API_BASE_URL=http://10.0.2.2:8000/ `
  --dart-define="LOCAL_DEV_API_TOKEN=<el mismo secreto>"
```

**Versión final firmada** (detalles en el
[quickstart de 005](specs/005-ajustes-y-version-final/quickstart.md)):

```powershell
cd frontend
flutter build apk --release --split-per-abi `
  --dart-define=API_BASE_URL=https://<dirección de la API>/                   # solo HTTPS
flutter build apk --release --split-per-abi -P permitirHttpLocal=true `
  --dart-define=API_BASE_URL=http://<IP del computador>:8000/                # demostración local
```

`API_BASE_URL` es obligatoria en la versión final. Sin ella, o con una dirección HTTP sin
`permitirHttpLocal`, la compilación se detiene con un mensaje: ese APK no podría conectarse
a la API (`http://10.0.2.2:8000/`, el valor por defecto, solo existe dentro del emulador).

Cada APK de `--split-per-abi` recibe su propio `versionCode` (1001, 2001, 4001). Si en un
teléfono ya hay uno de ellos, Android rechaza un APK universal o de depuración
(`INSTALL_FAILED_VERSION_DOWNGRADE`): hay que desinstalar la app antes.

La clave de firma (`%USERPROFILE%\.handtext\handtext-release.jks`) y
`frontend\android\key.properties` no se suben al repositorio. Guarde una copia de los
dos.

## Despliegue en Render

[render.yaml](render.yaml) crea la base PostgreSQL (`handtext-db`) y la API
(`handtext-api`) en Render. La API aplica las migraciones cada vez que arranca.

1. Suba el repositorio a GitHub con `render.yaml`, `backend/` y `db/`.
2. En Render: **New → Blueprint**, elija el repositorio y la rama, y escriba la clave
   de Google Cloud Vision cuando la pida (`HANDTEXT_GOOGLE_VISION_API_KEY`).
3. Cuando termine, copie la dirección de la API (por ejemplo
   `https://handtext-api.onrender.com`) y compile la app con ella. Como es HTTPS, no
   necesita `permitirHttpLocal`:

```powershell
cd frontend
flutter build apk --release --dart-define=API_BASE_URL=https://handtext-api.onrender.com/
```

En el plan gratuito, la API se apaga tras 15 minutos sin uso y la primera solicitud
puede tardar cerca de un minuto. Además, Render puede vencer la base gratuita después de
un tiempo. Revise las condiciones vigentes en su panel.

## Pruebas

```powershell
cd backend;  .venv\Scripts\python -m pytest     # incluye PostgreSQL real (pgserver)
cd frontend; flutter test
```

Las pruebas usan solo muestras sintéticas y servicios simulados; no llaman a Google. Las
de persistencia levantan solas un PostgreSQL temporal.

Prueba de punta a punta en el emulador, con la API local encendida (spec 012):

```powershell
cd frontend; flutter test integration_test -d emulator-5554 --dart-define=API_BASE_URL=http://10.0.2.2:8000/
```

En un teléfono por USB ([quickstart de 012](specs/012-pruebas-de-punta-a-punta/quickstart.md)):

```powershell
adb reverse tcp:8000 tcp:8000
cd frontend; flutter test integration_test -d <identificador> --dart-define=API_BASE_URL=http://127.0.0.1:8000/
```

## Estado

- Implementado: Historias de 001 a 012, el ícono propio y la versión final 1.0.0
  firmada.
- Pendientes:
  - SC-010 de 001: el método de medición y la herramienta están listos, pero falta medir
    con la clave de Google y 10 hojas reales (T061; guía en el
    [quickstart de 001](specs/001-handtext-mvp/quickstart.md), §6). Además, el responsable
    debe aprobar la meta del 10 % (CHK012).
  - Probar en un teléfono lo que el emulador no pudo mostrar por falta de memoria en el
    computador (registros de verificación de cada `tasks.md`):
    - escanear una hoja real (T809 de 009);
    - el nombre propuesto en el diálogo para guardar (T908 de 010);
    - el bloqueo con huella (T1008 de 011).
  - La prueba de punta a punta (T1104 de 012) ya pasa en el emulador; falta repetirla en
    un teléfono.
  - Validar los supuestos con el responsable del proyecto (CHK014 y CHK018 de 001; CHK208
    de 002).
  - Confirmar con la profesora los cambios de alcance:
    - 001 excluía el inicio de sesión (CHK209 de 002);
    - 001 dejaba fuera el recorte y compartir (CHK310 de 003);
    - 001 dejaba fuera las varias páginas (CHK409 de 004);
    - 001 dejaba fuera el historial (CHK709 de 007);
    - la interpretación de la constitución §4 con la app en inglés (CHK809 de 008);
    - buscar y renombrar en Mis documentos, que 007 dejaba fuera (CHK1009 de 010).
  - Validar los supuestos de 003 (CHK309), como el umbral del 80 % para las palabras
    dudosas, los de 004 (CHK408), como el límite de 10 páginas, los de 005 (CHK508) y
    los de 006 (CHK608), como los textos de los consejos, los de 007 (CHK708), como
    el límite de 50 documentos, los de 008 (CHK808), como revisar la traducción, y los
    de 009 a 012 (CHK908, CHK1008, CHK1108 y CHK1206).
