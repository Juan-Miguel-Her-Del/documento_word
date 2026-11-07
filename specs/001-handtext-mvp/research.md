# Research: HandText AI — MVP

**Fecha**: 2026-10-26 | **Plan**: [plan.md](plan.md) | **Spec**: [spec.md](spec.md)

Cada decisión sigue el formato Decisión / Razón / Alternativas. Las decisiones de producto
(límites de imagen, idiomas, espera y conservación) están en la sección `Clarifications`
del spec; aquí se documentan las decisiones técnicas que las implementan.

## R1. Proveedor de reconocimiento (constitución §2, IA / OCR)

- **Decisión**: Google Cloud Vision, función `DOCUMENT_TEXT_DETECTION` del endpoint REST
  `https://vision.googleapis.com/v1/images:annotate`, encapsulado en un adaptador del backend
  (`backend/app/services/ocr/google_vision.py`). El texto se toma de
  `responses[0].fullTextAnnotation.text` sin modificarlo.
- **Evidencia exigida por la constitución**:
  - *Manuscrito*: la guía oficial de detección de escritura a mano usa
    `DOCUMENT_TEXT_DETECTION` y devuelve el texto completo en `fullTextAnnotation.text`.
  - *Privacidad*: en solicitudes en línea, «the image data is processed in memory and not
    persisted to disk»; «Google does not use the content you send to train and improve our
    Cloud Vision features»; «We won't share the content with any third party». Google sí
    registra temporalmente metadatos de la solicitud (hora, tamaño).
  - *Costo*: las primeras 1 000 unidades de cada mes son gratuitas; luego USD 1,50 por cada
    1 000 unidades hasta 5 millones. Se necesita un proyecto de Google Cloud con facturación.
  - *Límites*: archivo de 20 MB, solicitud JSON de 10 MB (una imagen en base64 ocupa cerca
    de un 37 % más) y 1 800 solicitudes por minuto.
- **Idiomas**: se envía `imageContext.languageHints = ["es", "en"]`, según la decisión del
  2026-10-26. Google advierte que dejar la lista vacía suele funcionar mejor y que una pista
  equivocada perjudica el resultado; si la evaluación de calidad (SC-010) lo confirma, basta
  con cambiar `OCR_LANGUAGE_HINTS` en `backend/app/config.py`.
- **Credencial**: la clave viaja en la cabecera `x-goog-api-key`, que Google recomienda
  frente al parámetro `?key=` porque así la clave no aparece en URL ni en registros. Se lee
  de la variable de entorno `HANDTEXT_GOOGLE_VISION_API_KEY`.
- **Evidencia pendiente**: medir la calidad con muestras sintéticas del proyecto (SC-010,
  CHK012). Hasta entonces el proveedor se considera adoptado provisionalmente.
- **Alternativas consideradas**: Azure AI Vision Read (también reconoce manuscrito en
  español, pero su flujo asíncrono de enviar y consultar añade código); un modelo
  generativo como Claude (muy capaz, pero con más riesgo de completar o corregir texto,
  contrario a la regla de fidelidad); ML Kit en el teléfono (no está pensado para
  manuscrito y la constitución exige que la IA viva en el backend).
- **Fuentes**: [Detect handwriting](https://docs.cloud.google.com/vision/docs/handwriting),
  [Data usage](https://docs.cloud.google.com/vision/docs/data-usage),
  [Quotas and limits](https://docs.cloud.google.com/vision/quotas),
  [Pricing](https://cloud.google.com/vision/pricing),
  [Use API keys](https://docs.cloud.google.com/docs/authentication/api-keys-use).

## R2. Transporte de la imagen hacia el backend

- **Decisión**: `POST /api/v1/recognitions` con la imagen como cuerpo binario
  (`Content-Type: image/jpeg` o `image/png`). El backend lee el cuerpo en memoria por
  fragmentos y corta en cuanto supera 10 MB (`backend/app/api/request_body.py`).
- **Razón**: el analizador multipart de Starlette guarda en un archivo temporal en disco
  las partes de más de 1 MB (`spool_max_size = 1024 * 1024`). Eso contradiría la decisión de
  no almacenar imágenes en el servidor.
- **Alternativas**: `multipart/form-data` (archivos temporales y una dependencia más).

## R3. Preparación de la imagen para el OCR

- **Decisión**: el backend crea en memoria una copia JPEG (calidad 90) con la orientación
  EXIF aplicada, sin metadatos (incluida la ubicación GPS) y con el lado mayor reducido
  a 3 000 px como máximo (`backend/app/services/image_preparation.py`). Si la imagen tiene
  transparencia, se compone sobre fondo blanco. La imagen recibida no se modifica.
- **Razón**: una imagen de 10 MB codificada en base64 ocupa cerca de 13,7 MB y supera el
  límite JSON de 10 MB de Vision. Con 3 000 px la letra manuscrita sigue legible, y el modo
  `draft` de Pillow decodifica los JPEG grandes a escala reducida, lo que ahorra memoria.
- **Alternativas**: reducir la imagen en el teléfono (con Dart puro es lento; con un plugin
  nativo se añade otra dependencia); enviar el original (supera el límite del proveedor).

## R4. Validación de imágenes en dos capas (constitución §5, Validación)

- **Decisión**:
  - *App*: tamaño ≤ 10 MB, firma de bytes JPEG/PNG y dimensiones de 600 a 10 000 px,
    leídas del encabezado con el motor de Flutter (`ImageDescriptor`) sin decodificar los
    píxeles (`frontend/lib/services/image_rules.dart`).
  - *Backend* (autoridad): las mismas reglas, más la apertura y decodificación completa con
    Pillow (`backend/app/services/image_validation.py` e `image_preparation.py`).
- **Razón**: la UI orienta antes de enviar nada; el backend vuelve a validar porque no puede
  confiar en el cliente. El formato se decide por el contenido y nunca por la extensión.

## R5. Generación de Word y PDF (constitución §2: servicio independiente de las rutas)

- **Decisión**: el servicio `backend/app/services/documents/` genera los archivos.
  - *Word*: python-docx; cada línea del texto es un párrafo y las líneas vacías se
    conservan como párrafos vacíos, de modo que se respeta la separación.
  - *PDF*: fpdf2, A4, márgenes de 20 mm, salto de página automático, alineación izquierda y
    la fuente DejaVu Sans incrustada (Unicode: tildes, ñ, ¿, ¡ y comillas tipográficas).
    Las tabulaciones se dibujan como cuatro espacios.
  - *Caracteres*: Word rechaza los caracteres de control no permitidos en XML y PDF los que
    la fuente no puede dibujar (por ejemplo, emojis). En ambos casos se responde con un
    error que enumera esos caracteres, nunca con un archivo incompleto.
- **Razón**: la constitución ubica la generación de archivos en el backend. python-docx y
  fpdf2 son librerías Python puras y fáciles de probar sin la app.
- **Alternativas**: generar en el teléfono (contradice §2); reportlab (más pesado); las
  fuentes estándar de PDF (solo cubren un juego de 8 bits).
- **Licencia de la fuente**: DejaVu Sans permite redistribución; su licencia se incluye en
  `backend/app/assets/fonts/LICENSE-DejaVu.txt`.

## R6. Guardado del archivo en el teléfono

- **Decisión**: el diálogo del sistema Android para crear documentos (Storage Access
  Framework, `ACTION_CREATE_DOCUMENT`) mediante `FilePicker.saveFile` de file_picker 11.
  El usuario elige carpeta y nombre; la app propone `HandText_AAAAMMDD_HHMM.docx|pdf`.
- **Razón**: no requiere permisos de almacenamiento, y el sistema no reemplaza un archivo
  existente sin intervención del usuario: crea un nombre nuevo o pide confirmación según la
  versión de Android (H1-E11; se verifica manualmente en [quickstart.md](quickstart.md)).
  Cancelar el diálogo no es un error ni un éxito.
- **Alternativas**: escribir directamente en Descargas con MediaStore (más código y sin
  intervención del usuario); compartir el archivo (fuera de alcance, supuesto 7).

## R7. Borrador local del texto (Clarifications 2026-10-26)

- **Decisión**: archivo `draft.txt` (UTF-8) en `getApplicationSupportDirectory()`, el
  almacenamiento interno privado de la app (`frontend/lib/services/draft_storage.dart`).
  - Se escribe 400 ms después del último cambio, de inmediato tras un reconocimiento y
    cuando la app pasa a segundo plano.
  - La escritura es atómica: primero un archivo temporal y luego se renombra.
  - Se elimina al exportar correctamente sin cambios posteriores o al descartar el texto.
  - `android:allowBackup="false"` y `dataExtractionRules` lo excluyen de copias de
    seguridad y de transferencias entre dispositivos.
- **Alternativas**: shared_preferences (no adecuado para textos largos); una base de datos
  local (innecesaria para un único texto).

## R8. Copias de trabajo de la imagen

- **Decisión**: la imagen elegida se copia a la carpeta propia `handtext_work` dentro de la
  caché privada (`frontend/lib/services/working_copy_service.dart`).
  - La copia se borra al terminar el reconocimiento, al cancelar o al reemplazar la imagen,
    y la carpeta entera se purga al abrir la app.
  - El archivo intermedio que deja image_picker se borra solo si está dentro de la caché
    de la app.
- **Razón**: así se cumple la retención acordada, y la app nunca puede borrar el original
  del usuario porque solo toca archivos de su propia caché.

## R9. Estado de la app

- **Decisión**: un único `DocumentFlowController` (`ChangeNotifier`, incluido en Flutter)
  con los pasos inicio → vista previa → editor; los servicios se inyectan mediante
  interfaces para poder probarlos con versiones falsas.
- **Alternativas**: Provider, Riverpod o BLoC (dependencias y conceptos adicionales sin
  necesidad para tres pantallas).

## R10. Tiempos de espera

- **Decisión**: la app espera hasta 60 s el reconocimiento y la exportación (SC-009). El
  backend corta la llamada a Vision a los 45 s para responder antes `OCR_TIMEOUT`, en lugar
  de que la app agote su espera sin explicación.

## R11. Errores y registros (constitución §5)

- **Decisión**:
  - *Catálogo*: un único catálogo de códigos estables (`backend/app/errors.py`,
    documentado en [contracts/api.md](contracts/api.md)).
  - *Errores 422*: la ruta de exportación valida el JSON con Pydantic y responde
    `VALIDATION_ERROR` sin detalles; la respuesta 422 predeterminada de FastAPI incluiría
    el campo `input` con el contenido del usuario.
  - *Errores inesperados*: se registran solo con su tipo, archivo:línea y `request_id`.
  - *Registros generales*: guardan método, ruta, estado, duración y metadatos de la imagen,
    nunca imágenes, textos ni la clave.

## R12. Conexión con el backend durante el desarrollo

- **Decisión**:
  - *Compilación debug*: puede usar HTTP sin cifrar (manifiesto de `debug`) para hablar
    con el backend local.
  - *Compilación release*: requiere HTTPS.
  - *URL*: se define al compilar con `--dart-define=API_BASE_URL=...`; por defecto
    `http://10.0.2.2:8000/`, que es el computador visto desde el emulador.

## R13. Autorización de envío (supuesto 5)

- **Decisión**: diálogo antes de cada reconocimiento; el texto menciona el servidor de
  HandText AI y Google Cloud Vision. Si el usuario no acepta, no se llama a la API y vuelve
  a la vista previa (H1-E3, H1-E4, SC-004). Reintentar vuelve a pedir la autorización.

## R14. Límite técnico de exportación

- **Decisión**: hasta 200 000 caracteres de texto y 3 MB de cuerpo JSON; si se superan, la
  respuesta es `413 TEXT_TOO_LARGE`. Es una protección del servicio (una página manuscrita
  ronda unos pocos miles de caracteres), no una regla de producto, y el texto nunca se
  trunca.

## R15. Medición de la calidad del reconocimiento (SC-010, 2026-10-29)

- **Decisión**: herramienta de línea de comandos `backend/tools/measure_ocr_quality.py`.
  - **Entrada**: una carpeta con pares `hoja.jpg` + `hoja.txt`. El `.txt` es la
    transcripción correcta, escrita por una persona.
  - **Proceso**: cada imagen pasa por la misma validación, preparación y adaptador de
    Google Cloud Vision que usa la API. Así se mide exactamente lo que recibe la app.
  - **Métricas**:
    - *CER* (tasa de error de caracteres): distancia de Levenshtein entre el texto
      reconocido y la transcripción, dividida por los caracteres de la transcripción.
    - *WER*: lo mismo, contando palabras.
    - Antes de comparar se normalizan ambos textos: Unicode NFC y los espacios y saltos
      de línea seguidos cuentan como uno. Las mayúsculas, las tildes y los signos sí
      cuentan.
  - **Resultado global**: suma de errores ÷ suma de caracteres de todas las hojas
    (promedio ponderado). Así una hoja corta no pesa lo mismo que una larga.
  - **Marcas de palabras dudosas (spec 003)**: la herramienta también informa:
    - qué parte de las palabras marcadas tenía de verdad un error (precisión);
    - qué parte de las palabras con error quedó marcada (cobertura).

    Con eso se valida el umbral del 80 % (supuesto 1 de 003).
- **Privacidad (constitución §3)**:
  - Las imágenes se envían a Google solo si se pasa `--acepto-enviar`.
  - La herramienta muestra nombres de archivo y números, nunca el texto, y no guarda
    nada.
- **Alternativas descartadas**:
  - *Contar errores a mano*: lento y difícil de repetir.
  - *Métricas de traducción (BLEU)*: miden parecido de frases, no errores de
    transcripción.
