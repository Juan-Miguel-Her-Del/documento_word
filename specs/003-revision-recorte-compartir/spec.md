## Features principales

HandText AI suma tres mejoras al flujo existente:

- marca las palabras que la IA leyó con poca seguridad, para revisarlas primero;
- permite recortar y girar la imagen antes de reconocerla;
- permite compartir el documento recién guardado.

Esta funcionalidad amplía [001-handtext-mvp](../001-handtext-mvp/spec.md) y
[002-cuentas-de-usuario](../002-cuentas-de-usuario/spec.md). Reemplaza los supuestos 4
(«el usuario no recorta ni rota la imagen») y 7 («compartir no forma parte de esta
iteración») de 001 y conserva todas las demás reglas.

### 1. Palabras dudosas

- El reconocimiento informa, junto con el texto, qué palabras se leyeron con una
  seguridad menor al 80 %.
- **Solo se marcan palabras con al menos una letra o un número; los signos sueltos no se
  marcan.**
- El editor resalta esas palabras con fondo ámbar y subrayado, para que no dependan solo
  del color.
- El editor indica cuántas palabras quedan por revisar y permite ir a la siguiente.
- **Al modificar una palabra marcada (escribir dentro, borrar una parte o pegarle letras),
  su marca desaparece; las demás siguen sobre sus palabras.**
- Permite dar por buena una palabra marcada sin cambiarla.
- **Las marcas son solo una ayuda: no cambian el texto, no corrigen nada por su cuenta y
  no se exportan (constitución §3, Fidelidad).**
- Las marcas se guardan con el borrador y se recuperan con él.
- **Si el servicio no informa la seguridad de las palabras, el texto se muestra igual,
  sin marcas.**

### 2. Recortar y girar la imagen

- En la vista previa, permitir recortar la imagen y girarla antes de reconocerla.
- **El recorte se hace en el teléfono, sobre la copia de trabajo; el archivo original de
  la galería o la cámara no se modifica (constitución §3).**
- La imagen resultante conserva su formato (JPEG o PNG) y se valida otra vez con las
  reglas de 001: hasta 10 MB y de 600 a 10 000 píxeles por lado.
- **Si el resultado no cumple esas reglas, se informa el motivo y se conserva la imagen
  anterior.**
- Cancelar el recorte no cambia nada.
- Permitir volver a la imagen original de la selección mientras no se haya reconocido.

### 3. Compartir el documento

- Tras guardar el documento, ofrecer «Compartir» para enviarlo a otra app del teléfono
  (correo, mensajería o almacenamiento) con el selector de Android.
- **Se comparte exactamente el archivo exportado: mismo contenido, nombre y formato.**
- **La copia temporal para compartir vive en la caché privada de la app y se borra al
  compartir otro documento, al abrir la app y al cerrar sesión o eliminar la cuenta.**
- Compartir es siempre una acción de la persona: la app no envía el documento a ningún
  servicio por su cuenta.

## Lo que NO se va a construir en esta iteración (Non-Goals)

- Corrección automática o sugerencias de palabras (siguen fuera, como en 001).
- Mostrar el porcentaje de seguridad de cada palabra o marcar letras sueltas.
- Filtros de imagen (brillo, contraste, blanco y negro) o detección automática de los
  bordes de la hoja.
- ~~Recortar varias páginas o unir imágenes (siguen fuera, como en 001).~~ *(Varias
  páginas se incorporan en [004](../004-varias-paginas/spec.md); cada página se recorta
  por separado.)*
- Compartir sin guardar antes, o compartir el texto sin formato.
- Historial de documentos compartidos.

## Clarifications

### Session 2026-10-28

- Q: ¿Qué mejoras se incorporan? → A: Palabras dudosas, recorte y giro de la imagen y
  compartir el documento. Las eligió el responsable del proyecto entre varias
  propuestas; el ícono propio de la app no se eligió.
- Q: ¿Cómo se resuelven los supuestos 4 y 7 de 001? → A: Esta funcionalidad los
  reemplaza:
  - el recorte y el giro son manuales y se hacen en el teléfono;
  - compartir se ofrece después de guardar.

  001 queda anotado.

## Historias de usuario y escenarios de aceptación

Las etiquetas del código usan el prefijo `EX` (extras): `[EX-H1-E4]` es la Historia 1,
escenario 4, de esta funcionalidad.

### Historia 1 - Revisar las palabras dudosas (Prioridad: P1)

Una estudiante reconoce sus apuntes. La app le señala las 4 palabras que la IA leyó con
dudas; las revisa una por una y corrige dos.

**Por qué esta prioridad**: la revisión es obligatoria (constitución §3) y es la parte
más lenta del flujo. Señalar dónde mirar ahorra tiempo y evita que se escapen errores.

**Prueba independiente**: reconocer con un servicio simulado que informa la seguridad de
cada palabra y comprobar las marcas, la navegación, las correcciones y el borrador.
Requiere pruebas automatizadas del cálculo de posiciones en el servidor y de su ajuste
al editar.

**Escenarios de aceptación**:

1. **Dado** un reconocimiento con palabras de seguridad menor al 80 %, **Cuando** se abre
   el editor, **Entonces** esas palabras aparecen resaltadas y se indica cuántas son.
2. **Dado** palabras con seguridad del 80 % o más, o signos sueltos, **Cuando** se abre el
   editor, **Entonces** no se marcan.
3. **Dado** varias palabras marcadas, **Cuando** se toca «Siguiente», **Entonces** se
   selecciona la siguiente palabra marcada; después de la última vuelve a la primera.
4. **Dado** una palabra marcada, **Cuando** se escribe dentro de ella, se borra una parte o
   se le pegan letras, **Entonces** su marca desaparece y las demás siguen sobre sus
   palabras.
5. **Dado** una palabra marcada seleccionada, **Cuando** se toca «Está bien», **Entonces**
   su marca desaparece y el texto no cambia.
6. **Dado** un texto con marcas, **Cuando** se exporta, **Entonces** el archivo contiene
   solo el texto, sin marcas ni resaltados.
7. **Dado** un texto con marcas sin exportar, **Cuando** la app se cierra y se vuelve a
   abrir, **Entonces** el borrador se recupera con las marcas que quedaban.
8. **Dado** que el servicio no informa la seguridad de las palabras, **Cuando** termina el
   reconocimiento, **Entonces** el texto se muestra igual, sin marcas.
9. **Dado** que no quedan palabras marcadas, **Cuando** se mira el editor, **Entonces** no
   se muestra la barra de revisión.

### Historia 2 - Recortar y girar la imagen (Prioridad: P2)

Un docente fotografía una hoja sobre su escritorio y, antes de enviarla, recorta los
bordes y la endereza.

**Por qué esta prioridad**: quitar el fondo y orientar la hoja mejora el reconocimiento,
pero el flujo funciona sin este paso.

**Prueba independiente**: en la vista previa, recortar, girar, cancelar y volver a la
original; probar un recorte que deja la imagen por debajo de 600 px. Requiere pruebas
automatizadas del reemplazo y del borrado de las copias de trabajo.

**Escenarios de aceptación**:

1. **Dado** una imagen en la vista previa, **Cuando** se toca «Recortar o girar»,
   **Entonces** se abre el editor de recorte con esa imagen.
2. **Dado** el editor de recorte, **Cuando** se recorta o gira y se confirma, **Entonces**
   la vista previa muestra la nueva imagen con sus nuevos datos (dimensiones y tamaño) y
   en el mismo formato.
3. **Dado** el editor de recorte, **Cuando** se cancela, **Entonces** la imagen de la
   vista previa no cambia.
4. **Dado** un recorte que deja algún lado por debajo de 600 px, **Cuando** se confirma,
   **Entonces** se informa el motivo y se conserva la imagen anterior.
5. **Dado** una imagen recortada, **Cuando** se toca «Usar la imagen original»,
   **Entonces** vuelve la imagen tal como se eligió.
6. **Dado** una imagen recortada, **Cuando** se reconoce, **Entonces** se envía la imagen
   recortada, con la autorización previa de siempre.
7. **Dado** cualquier recorte, **Cuando** termina, **Entonces** el archivo original del
   teléfono no se modifica.

### Historia 3 - Compartir el documento (Prioridad: P3)

Una persona guarda su documento como PDF y lo envía por correo a su profesora sin salir
de la app.

**Por qué esta prioridad**: ahorra pasos después de exportar, pero el documento ya quedó
guardado sin esta opción.

**Prueba independiente**: exportar, compartir, cerrar el selector sin elegir, compartir
otra vez y cerrar sesión. Requiere pruebas automatizadas del archivo temporal y de su
borrado.

**Escenarios de aceptación**:

1. **Dado** un documento guardado correctamente, **Cuando** se muestra el aviso de éxito,
   **Entonces** incluye la acción «Compartir».
2. **Dado** «Compartir», **Cuando** se toca, **Entonces** se abre el selector de Android
   con el archivo exportado: mismo nombre, formato y contenido.
3. **Dado** el selector abierto, **Cuando** la persona lo cierra sin elegir, **Entonces**
   nada cambia y puede volver a compartir.
4. **Dado** que se canceló el guardado o falló la exportación, **Cuando** se muestra el
   aviso, **Entonces** no se ofrece «Compartir».
5. **Dado** una copia temporal para compartir, **Cuando** se comparte otro documento, se
   abre la app o se cierra sesión, **Entonces** esa copia se borra.
6. **Dado** un documento guardado, **Cuando** se edita el texto, **Entonces** deja de
   ofrecerse «Compartir» hasta volver a exportar.

### Casos límite

- Si el servicio devuelve posiciones fuera del texto, esas marcas se ignoran y el texto
  no se toca.
- Si antes de una palabra dudosa hay caracteres especiales (por ejemplo, emojis o
  símbolos matemáticos), la marca queda exactamente sobre la palabra.
- Si no hay ninguna app para compartir, se informa.
- Si el editor de recorte no puede abrir la imagen, se informa y se conserva la imagen.

## Criterios de éxito medibles

- **SC-301**: en un conjunto de prueba con seguridad conocida, se marcan el 100 % de las
  palabras con letras o números y seguridad menor al 80 %, y ninguna otra.
- **SC-302**: después de cualquier edición, cada marca que queda está exactamente sobre
  la palabra que se marcó al reconocer.
- **SC-303**: el archivo exportado de un texto con marcas es idéntico al de ese mismo
  texto sin marcas.
- **SC-304**: recortar nunca modifica el archivo original. No quedan copias de la imagen
  en el teléfono después de reconocer, cancelar o cerrar sesión.
- **SC-305**: el archivo compartido es idéntico, byte a byte, al exportado.
- **SC-306**: las marcas se distinguen sin depender del color (subrayado además del
  fondo), y su texto cumple el contraste de SC-208.

## Supuestos pendientes de validación

Decisiones adoptadas para poder implementar; deben confirmarse con el responsable del
proyecto.

1. El umbral de una palabra dudosa es una seguridad menor al 80 %.
2. Se marcan palabras completas, no letras sueltas.
3. El recorte usa el editor nativo de Android, con los colores de la app. Algunos textos
   de ese editor son los del sistema.
4. Solo se puede compartir después de guardar el documento.
5. «Está bien» quita la marca de forma definitiva para ese texto.
