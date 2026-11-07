# Research: Revisión asistida, recorte y compartir

Decisiones técnicas de la funcionalidad 003. Cada una indica qué se eligió, por qué y qué
alternativas se descartaron.

## R1. De dónde sale la seguridad de cada palabra

- **Decisión**: usar el campo `confidence` (de 0 a 1) de cada palabra de la respuesta de
  Google Cloud Vision. Las palabras están en `fullTextAnnotation.pages[].blocks[]
  .paragraphs[].words[]`, y el texto de cada una es la unión de sus `symbols[].text`.
- **Umbral**: menos de 0,80 (`UNCERTAIN_WORD_CONFIDENCE` en `config.py`, supuesto 1 del
  spec).
- **Qué se marca**: solo las palabras con al menos una letra o un número
  (`str.isalnum`). Vision trata cada signo de puntuación como una «palabra», y marcarlos
  solo agregaría ruido.
- **Si falta la información**: si la respuesta no trae `pages` o tiene otra forma, el
  texto se devuelve igual y sin marcas. Se registra solo el evento, sin contenido.

  Las marcas son una ayuda opcional. El texto, que es lo que exige la constitución §5,
  sigue validándose como antes: una respuesta sin `text` válido sigue siendo un error.
- **Alternativas descartadas**:
  - *Confianza por bloque o párrafo*: demasiado gruesa; marcaría líneas enteras.
  - *Confianza por letra*: demasiado fina y difícil de leer (Non-Goals).

## R2. Posición de cada palabra dentro del texto

- **Decisión**: el servidor recorre las palabras en orden y busca cada una en
  `fullTextAnnotation.text` desde donde terminó la anterior. Así obtiene las posiciones
  de inicio y fin.
  - Vision arma ese texto con los mismos símbolos y los separa con espacios o saltos de
    línea, así que las palabras aparecen en el mismo orden.
  - Si una palabra no se encuentra, se omite esa marca y la búsqueda sigue; nunca se
    falla el reconocimiento por esto.
- **Unidad de las posiciones**: puntos de código Unicode (los índices de `str` en Python).
  La app los convierte a las unidades UTF-16 que usa Dart. Así, una marca queda bien
  colocada aunque antes haya emojis o símbolos fuera del plano básico (caso límite del
  spec).
- **Alternativa descartada**: devolver solo la lista de palabras dudosas. La app no
  podría distinguir dos apariciones de la misma palabra.

## R3. Ajuste de las marcas al editar

- **Decisión**: con cada cambio, la app compara el texto anterior y el nuevo:
  1. Busca el prefijo y el sufijo comunes. Lo que queda en medio es la zona editada.
  2. Ajusta cada marca según dónde está respecto de esa zona:
     - si está antes, no cambia;
     - si está después, se desplaza tantos caracteres como cambió el largo del texto;
     - si se superpone con lo editado, o si se escribió dentro de la palabra, se elimina.
  3. Si una marca quedó pegada a la zona editada y el carácter vecino es una letra o un
     número, también se elimina, porque se «le pegaron letras» a la palabra.

  Es una función pura (`adjustRanges`) que se prueba sin pantallas, incluido SC-302.
- **Alternativas descartadas**:
  - *Volver a buscar cada palabra en el texto*: se confunde con palabras repetidas.
  - *Un algoritmo de diferencias completo (Myers)*: el editor cambia una zona por vez, y
    prefijo + sufijo resuelve ese caso en tiempo lineal.

## R4. Marcas en el editor

- **Decisión**: un `TextEditingController` propio (`ReviewTextController`) sobreescribe
  `buildTextSpan` y pinta las marcas con:
  - fondo ámbar al 35 %;
  - subrayado ondulado ámbar oscuro, para no depender solo del color (SC-306).

  El texto sigue siendo editable y del mismo tamaño.
- **Barra de revisión**: muestra «N palabras para revisar» con dos botones:
  - «Siguiente» selecciona la próxima marca después del cursor y, tras la última, vuelve
    a la primera;
  - «Está bien» quita la marca de la palabra seleccionada.
- **Alternativa descartada**: mostrar las palabras dudosas en una lista aparte. Obliga a
  buscar cada una en el texto.

## R5. Borrador con marcas

- **Decisión**: el borrador pasa a guardarse en JSON
  (`{"version": 2, "text": "…", "uncertain": [[inicio, fin], …]}`), con la misma escritura
  atómica de 001.
  - **Compatibilidad**: al leer, si el archivo no es un JSON con `version` 2, se toma
    todo su contenido como texto. Así se recuperan los borradores escritos por la
    versión anterior, que eran texto plano.
  - Las marcas que no caben en el texto se descartan al leer.
- **Alternativa descartada**: un archivo aparte para las marcas. Podría quedar
  desincronizado con el texto si la app se cierra entre las dos escrituras.

## R6. Editor de recorte y giro

- **Decisión**: image_cropper 12.2.1, que en Android abre uCrop 2.2.11, el editor nativo
  de recorte. Se le pasan los colores de la identidad Aurora:
  - barra azul marino;
  - controles activos en azul corporativo;
  - recorte libre (sin proporción fija);
  - giro de 90° y libre.
  - **Por qué nativo**: uCrop recorta el archivo en código nativo sin cargar la imagen
    completa en la memoria de Dart. Una foto de 10 000 × 10 000 px ocuparía 400 MB
    decodificada en Dart.
  - **Formato**: el resultado se pide en el mismo formato que la imagen de entrada; un
    JPEG se guarda con calidad 95.
  - **Versión**: image_cropper 13 exige Flutter 3.47, y el proyecto usa 3.35.4.
  - **Manifiesto**: requiere declarar `UCropActivity` en el `AndroidManifest.xml`.
- **Flujo**:
  1. La app pasa la ruta de la copia de trabajo.
  2. uCrop escribe el resultado en la caché.
  3. La app copia esos bytes a una nueva copia de trabajo, borra el archivo de uCrop y
     valida el resultado con las reglas de 001.
  4. La copia anterior se conserva como «original» hasta reconocer, cancelar o volver a
     la original.
- **Alternativas descartadas**:
  - *Paquetes de recorte en Dart puro (crop_your_image)*: decodifican la imagen
    completa en Dart; ver el problema de memoria de arriba.
  - *Recorte en el servidor*: enviaría la imagen antes de que la persona la prepare.

## R7. Compartir

- **Decisión**: share_plus 12.0.2, que abre el selector de Android (`ACTION_SEND`) con un
  `FileProvider` propio del paquete.
  - **Versión**: share_plus 13 exige Flutter 3.38 o superior.
  - **Flujo**:
    1. Al guardar con éxito, el controlador conserva en memoria los bytes, el nombre y
       el formato del archivo exportado.
    2. «Compartir» escribe esos bytes en `<caché>/handtext_share/<nombre>` y abre el
       selector.
- **Alternativa descartada**: compartir el archivo guardado con el diálogo de Android.
  file_picker devuelve una ruta de contenido que no siempre se puede volver a leer.

## R8. Retención de los archivos temporales nuevos

| Archivo | Ubicación | Se borra |
|---------|-----------|----------|
| Resultado de uCrop | caché de la app (carpeta de image_cropper) | en cuanto se copia a la copia de trabajo |
| Copia recortada y copia «original» | `<caché>/handtext_work/` (la de 001) | al reconocer, cancelar, volver a la original, cerrar sesión y al abrir la app (purga de 001) |
| Copia para compartir | `<caché>/handtext_share/` | en cuanto se cierra el selector de Android |
| Copia que hace share_plus para la app elegida | `<caché>/share_plus/` | al compartir otro documento, al cerrar sesión o eliminar la cuenta, y al abrir la app |

**Hallazgo de la verificación (2026-10-29)**: share_plus copia el archivo a
`<caché>/share_plus/` y lo deja ahí hasta el próximo envío, para que la app elegida pueda
leerlo después. Al principio la limpieza solo borraba `handtext_share/`. Ahora `purge`
borra las dos carpetas; la prueba de regresión está en `storage_test.dart`.

La caché no se incluye en las copias de seguridad (001, research R8).
