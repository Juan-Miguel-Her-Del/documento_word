# Quickstart: ejecutar y validar HandText AI

**Plan**: [plan.md](plan.md) | **Contrato**: [contracts/api.md](contracts/api.md)

Los comandos son para PowerShell en Windows y se ejecutan desde la raíz del repositorio
(`documento_word`).

## 1. Requisitos previos

- Python 3.12 y Flutter 3.35 con el SDK de Android (`flutter doctor` sin errores de Android).
- Un emulador de Android o un teléfono con la depuración USB activada.
- Para reconocer texto real: un proyecto de Google Cloud con facturación activa, la
  **Cloud Vision API** habilitada y una **clave de API** restringida a esa API. Sin clave
  funcionan todas las pantallas y la exportación, pero el reconocimiento responde
  «servicio no disponible».

## 2. Backend (API)

> **Desde la funcionalidad 002** el reconocimiento y la exportación exigen una sesión
> iniciada, y la API necesita PostgreSQL. Antes de este paso, prepare la base y defina
> `HANDTEXT_DATABASE_URL` como indica el
> [quickstart de 002](../002-cuentas-de-usuario/quickstart.md).

```powershell
cd backend
python -m venv .venv
.venv\Scripts\python -m pip install -r requirements-dev.txt
$env:HANDTEXT_DATABASE_URL = "postgresql://handtext:<su clave>@localhost:5432/handtext"
$env:HANDTEXT_GOOGLE_VISION_API_KEY = "<su clave>"   # opcional; nunca la suba al repositorio
.venv\Scripts\python -m app.persistence.migrations
.venv\Scripts\python -m uvicorn app.main:app --host 0.0.0.0 --port 8000
```

- Abra `http://127.0.0.1:8000/docs` para ver y probar los endpoints.
- `--host 0.0.0.0` permite que un teléfono real de la misma red Wi-Fi llegue al
  computador; Windows puede pedir permiso en el firewall.

**Pruebas y estilo** (en otra terminal, dentro de `backend`):

```powershell
.venv\Scripts\python -m pytest
.venv\Scripts\python -m ruff format --check .
.venv\Scripts\python -m ruff check .
```

## 3. App Flutter

```powershell
cd frontend
flutter pub get
flutter analyze
flutter test
```

**Ejecutar en el emulador** (10.0.2.2 es el computador visto desde el emulador):

```powershell
flutter run --dart-define=API_BASE_URL=http://10.0.2.2:8000/
```

**Ejecutar en un teléfono real**: use la IP del computador en la red Wi-Fi
(`ipconfig`), por ejemplo `--dart-define=API_BASE_URL=http://192.168.1.50:8000/`.

**Compilar el APK de depuración**: `flutter build apk --debug`. El archivo queda en
`frontend\build\app\outputs\flutter-apk\app-debug.apk`.

## 4. Prueba de contrato entre la app y la API real

Con el backend en marcha:

```powershell
cd frontend
$env:HANDTEXT_API_URL = "http://127.0.0.1:8000/"
flutter test test/integration
```

Resultado esperado: 9 pruebas superadas (desde 002 la prueba crea una cuenta temporal y
la elimina al final). Sin la variable `HANDTEXT_API_URL`, estas pruebas se omiten.

## 5. Validación manual por historia

Estos escenarios dependen del sistema Android y se comprueban a mano en el emulador o en
el teléfono. Los demás tienen pruebas automatizadas (ver [MAPA_DEL_CODIGO.md](../../MAPA_DEL_CODIGO.md)).
Desde 002, primero se crea una cuenta o se inicia sesión.

| Historia / escenario | Pasos | Resultado esperado |
|----------------------|-------|--------------------|
| H1 (flujo completo) | Elegir imagen guardada → Aceptar y reconocer → Autorizar → corregir → Exportar → Word | El diálogo de Android guarda el .docx y Word lo abre con el texto corregido |
| H1-E3 / H1-E4 | Tocar «No autorizar» en el diálogo de autorización | No se envía nada y aparece «No se envió la imagen…» |
| H1-E8 | Detener el backend y reconocer | Aviso de falta de conexión con «Reintentar» |
| H1-E11 | Exportar dos veces con el mismo nombre en la misma carpeta | Android crea otro nombre o pide confirmación; no se reemplaza en silencio |
| H1-E15 | Editar el texto, pulsar Inicio y ejecutar `adb shell am kill com.handtextai.handtext_ai`; abrir la app | El editor muestra el texto con «Se recuperó el texto…» |
| H1-E16 | Exportar correctamente, cerrar y volver a abrir la app | La app empieza en el inicio: no queda borrador |
| H2-E1 / H2-E2 | Tomar fotografía la primera vez y denegar el permiso | Se explica para qué se necesita y se puede volver a intentar |
| H3-E2 | Exportar a PDF un texto con tildes, ñ, ¿ y ¡ y más de una página | El PDF se abre completo y con los caracteres correctos |
| SC-009 | Reconocer una foto de hasta 10 MB con Wi-Fi o 4G | El texto o el aviso de fallo aparece en 60 s como máximo |

## 6. Medir la calidad del reconocimiento (SC-010)

### 6.1 Crear la clave de Google Cloud Vision (una sola vez)

1. Entre a <https://console.cloud.google.com> con una cuenta de Google y cree un proyecto
   (por ejemplo, `handtext-ai`).
2. **Facturación**: active una cuenta de facturación para el proyecto (pide una tarjeta).
   - Los primeros 1000 reconocimientos de cada mes son gratuitos; después cuestan
     alrededor de US$1,50 por cada 1000.
   - Revise los precios vigentes en <https://cloud.google.com/vision/pricing>.
   - Una medición de 10 hojas usa 10.
3. **API**: en *APIs y servicios → Biblioteca*, busque **Cloud Vision API** y pulse
   *Habilitar*.
4. **Clave**: en *APIs y servicios → Credenciales*, elija *Crear credenciales → Clave de
   API*.
5. **Restricción**: abra la clave nueva y, en *Restricciones de API*, elija *Restringir
   clave* y marque solo **Cloud Vision API**. Así, si alguien la obtiene, no podrá usarla
   para otros servicios.
6. **Seguridad**: la clave es un secreto (constitución §2). Nunca la escriba en el código,
   en un archivo del repositorio ni en un mensaje. Se entrega solo por la variable de
   entorno:

   ```powershell
   $env:HANDTEXT_GOOGLE_VISION_API_KEY = "<su clave>"
   ```

   Con la clave definida antes de iniciar Uvicorn (§2), la app reconoce texto de verdad.

### 6.2 Preparar las hojas

- Al menos **10 hojas** manuscritas en español: letra legible, buena luz y la hoja
  completa en la foto.
- Ponga las fotos en una carpeta, por ejemplo `C:\HandText\hojas`.
- Para cada foto, cree un `.txt` con el **mismo nombre** (`hoja1.jpg` → `hoja1.txt`).
  Escriba en él exactamente lo que dice la hoja: mayúsculas, tildes y signos incluidos.
  En el Bloc de notas, guárdelo con la codificación UTF-8.
- Use hojas propias o de personas que lo autoricen (constitución §6: muestras
  sintéticas, públicas o anonimizadas).

### 6.3 Medir

```powershell
cd backend
$env:HANDTEXT_GOOGLE_VISION_API_KEY = "<su clave>"
.venv\Scripts\python -m tools.measure_ocr_quality C:\HandText\hojas --acepto-enviar
```

- Sin `--acepto-enviar`, la herramienta no envía nada.
- El informe muestra, para cada hoja:
  - **CER**: porcentaje de caracteres con error;
  - **WER**: porcentaje de palabras con error.
- Al final indica el **CER global** y si cumple la meta de SC-010 (10 %). Para probar
  otra meta, use `--meta 0.15`.
- Las líneas de **marcas de palabras dudosas** dicen si el umbral del 80 % (spec 003)
  señala bien los errores:
  - si la *cobertura* es baja (muchos errores sin marcar), conviene subir el umbral;
  - si la *precisión* es baja (muchas marcas en palabras correctas), conviene bajarlo.

  El umbral está en `backend/app/config.py` (`UNCERTAIN_WORD_CONFIDENCE`).
- **Registro**: anote el resultado en el registro de verificación de
  [tasks.md](tasks.md) (T061) y lleve la meta al responsable del proyecto (CHK012).
