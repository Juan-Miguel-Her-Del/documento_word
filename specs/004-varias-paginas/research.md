# Research: Varias páginas por documento

## R1. Elegir varias imágenes

- **Decisión**: `ImagePicker.pickMultiImage(limit: n)`, de image_picker (ya es una
  dependencia de 001).
  - `n` son las páginas que todavía caben, hasta 10.
  - En Android, el selector exige un límite de 2 o más. Si cabe una sola página, se usa
    `pickImage`.
  - La cámara toma una foto por vez.
- **Por qué**: no agrega dependencias. El selector de fotos del sistema no necesita
  permisos de almacenamiento, igual que en 001.

## R2. Modelo de las páginas

- **Decisión**: el controlador guarda una lista de `DocumentPage` y el índice de la página
  elegida. Cada página tiene:
  - su imagen (la copia de trabajo de 001);
  - la imagen original, si se recortó (003);
  - el resultado de su reconocimiento, si ya se reconoció.

  Recortar o reemplazar una página borra su resultado, porque cambió su imagen. Moverla
  no, porque el texto se une en el orden nuevo.
- **Compatibilidad**: `pendingImage` sigue devolviendo la página elegida, así las
  pantallas y pruebas de 001 y 003 siguen igual.

## R3. Reconocimiento página por página

- **Decisión**: las páginas se envían una por una, en orden, con el mismo endpoint de 001
  (una imagen por solicitud). La API no cambia.
  - **Sin reenvíos**: una página que ya tiene resultado no se vuelve a enviar (SC-402).
  - **Si una falla**: se detiene ahí, se informa su número y se conservan las demás.
  - **Por qué una por una**: cada página respeta los 60 s de SC-009 (SC-405) y el avance
    se puede mostrar.
- **Alternativas descartadas**:
  - *Enviar todas en paralelo*: más carga para el servidor y para la cuota de Google, y
    los fallos parciales son más difíciles de explicar.
  - *Un endpoint nuevo que reciba varias imágenes*: el cuerpo podría llegar a 100 MB.

## R4. Unión del texto

- **Decisión**: función pura `joinPages`.
  - Con una sola página, el texto queda exactamente como lo devolvió el servicio (igual
    que en 001).
  - Con varias, se quitan los espacios y saltos de línea del final de cada página y se
    unen con una línea en blanco (`\n\n`).
  - Las marcas de palabras dudosas (003) se desplazan según dónde empieza cada página
    (SC-404).
  - Las páginas sin texto se omiten y se informan.

## R5. Avisos

- **Decisión**: `OperationStatus` agrega el número de página, el total y la lista de
  páginas sin texto. strings.dart arma los mensajes:
  - «Reconociendo la página 2 de 3…»;
  - «Página 2 de 3: …» delante del motivo del fallo;
  - «Texto reconocido. La página 2 no tenía texto.».
- La autorización dice cuántas imágenes se enviarán.

## R6. Vista previa

- **Decisión**: debajo de la imagen grande, una tira horizontal de miniaturas numeradas
  y, al final, una tarjeta «Agregar página».
  - La página elegida tiene borde azul.
  - Con dos páginas o más aparecen tres botones con ícono y descripción para lectores de
    pantalla: mover antes, mover después y quitar.
  - **Memoria**: las miniaturas se decodifican a 160 px de ancho (`cacheWidth`).

## R7. Retención

- **Decisión**: se aplican las reglas de 001 a cada página. Las copias de todas las
  páginas, y de sus originales recortados, se borran:
  - al reconocer;
  - al cancelar;
  - al quitar la página;
  - al cerrar sesión;
  - al abrir la app (purga de 001).
