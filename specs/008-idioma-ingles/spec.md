## Features principales

HandText AI se puede usar en **inglés**:
- un ajuste **Idioma**: Español, English o Automático (el idioma del teléfono);
- **toda la interfaz cambia de idioma al instante**, sin cerrar la app ni perder el texto
  en edición;
- los textos de cada idioma están en su propio archivo de traducción.

Esta funcionalidad amplía 001 a 007 sin cambiar sus reglas.

### 1. Elegir el idioma

- En Ajustes: Español, English o Automático.
- **El español es el idioma por omisión** (constitución §4: los mensajes iniciales de la
  interfaz van en español). Con «Automático», la app usa el inglés si el teléfono está en
  inglés y el español en cualquier otro caso.
- En la bienvenida, un botón de idioma permite elegirlo antes de crear la cuenta.
- El idioma se guarda en el teléfono, como los demás ajustes.

### 2. Toda la interfaz en el idioma elegido

- **Pantallas, botones, avisos, errores, diálogos, la autorización de envío, la
  privacidad y los consejos.**
- También los textos propios de Android y Flutter que la app controla: el título del
  diálogo para guardar, el del editor de recorte, y «Copiar» y «Pegar» en el editor.
- Las fechas y los números siguen el idioma: «29 oct 2026» y «2,4 MB» en español,
  «Oct 29, 2026» y «2.4 MB» en inglés.

### 3. Lo que no cambia

- **El texto del documento nunca se traduce: cambiar el idioma de la app no toca lo que
  la persona escribió** (constitución §3, fidelidad: sin traducciones).
- El reconocimiento sigue indicando español e inglés al servicio, como en 001.
- Los archivos Word y PDF solo contienen el texto de la persona.

## Lo que NO se va a construir en esta iteración (Non-Goals)

- Otros idiomas además del español y el inglés.
- Traducir los documentos o el texto reconocido.
- Mostrar en inglés los mensajes que devuelve la API (la app muestra los suyos).
- Cambiar el nombre de la app o su ícono según el idioma.

## Clarifications

### Session 2026-10-29

- Q: ¿Qué extras se incorporan ahora? → A: El responsable del proyecto pidió «los demás
  plus» de la lista propuesta. Esta funcionalidad toma la app en inglés, con los textos
  en archivos de traducción.
- Q: ¿Qué idioma usa la app al instalarla? → A: Español, por la constitución §4. El
  inglés se elige en Ajustes o en la bienvenida; «Automático» sigue al teléfono.

## Historias de usuario y escenarios de aceptación

Las etiquetas del código usan el prefijo `IE` (idioma inglés): `[IE-H1-E2]` es la
Historia 1, escenario 2, de esta funcionalidad.

### Historia 1 - Elegir el idioma (Prioridad: P1)

Un estudiante de intercambio que no lee bien español quiere usar la app en inglés.

**Por qué esta prioridad**: sin poder elegirlo, la traducción no sirve.

**Prueba independiente**: elegir cada opción, cerrar y abrir la app. Requiere pruebas
automatizadas del ajuste y de las pantallas.

**Escenarios de aceptación**:

1. **Dado** la app recién instalada, **Cuando** se abre, **Entonces** está en español.
2. **Dado** Ajustes o la bienvenida, **Cuando** se elige «English», **Entonces** toda la
   interfaz pasa al inglés al instante.
3. **Dado** «Automático», **Cuando** el teléfono está en inglés, **Entonces** la app está
   en inglés; con cualquier otro idioma del teléfono, en español.
4. **Dado** un idioma elegido, **Cuando** se cierra y se abre la app o se cambia de
   cuenta, **Entonces** se conserva.
5. **Dado** un archivo de ajustes de una versión anterior, **Cuando** se abre la app,
   **Entonces** está en español.

### Historia 2 - Usar toda la app en inglés (Prioridad: P2)

La misma persona digitaliza sus apuntes de principio a fin en inglés.

**Por qué esta prioridad**: una pantalla o un error en otro idioma rompe la experiencia.

**Prueba independiente**: recorrer todas las pantallas, avisos y diálogos en inglés.
Requiere pruebas automatizadas de pantallas.

**Escenarios de aceptación**:

1. **Dado** el inglés, **Cuando** se recorren todas las pantallas, menús, hojas y
   diálogos, **Entonces** ningún texto aparece en español.
2. **Dado** el inglés, **Cuando** ocurre un fallo (sin conexión, imagen no válida, sesión
   vencida…), **Entonces** el mensaje está en inglés y dice qué hacer (constitución §5).
3. **Dado** el inglés, **Cuando** se abren el diálogo para guardar y el editor de
   recorte, **Entonces** sus títulos están en inglés.
4. **Dado** el inglés, **Cuando** se ven el historial o los detalles de una imagen,
   **Entonces** las fechas y los tamaños usan el formato inglés.
5. **Dado** el inglés y la letra del sistema al 200 %, **Cuando** se recorren las
   pantallas, **Entonces** nada se corta (spec 006).

### Historia 3 - El texto de la persona no cambia (Prioridad: P3)

Una docente cambia el idioma con un texto a medio corregir.

**Por qué esta prioridad**: la fidelidad del texto es una regla de la constitución.

**Prueba independiente**: cambiar el idioma con un texto en edición y exportarlo.
Requiere pruebas automatizadas del controlador y de las pantallas.

**Escenarios de aceptación**:

1. **Dado** un texto en edición con palabras dudosas, **Cuando** se cambia el idioma,
   **Entonces** el texto, las marcas y el borrador siguen iguales.
2. **Dado** un texto en edición, **Cuando** se exporta con la app en inglés,
   **Entonces** el archivo tiene exactamente el texto de la persona.

### Casos límite

- Si el teléfono está en un idioma que no es español ni inglés, «Automático» usa el
  español.
- Si la API devuelve un detalle de error en español (por ejemplo, los caracteres que no
  se pueden exportar), con la app en inglés se muestra el mensaje general en inglés.

## Criterios de éxito medibles

- **SC-801**: el 100 % de los textos de la interfaz tiene traducción al inglés (la app no
  compila si falta uno).
- **SC-802**: con el inglés, 0 textos en español visibles en el recorrido de todas las
  pantallas, menús, hojas y diálogos.
- **SC-803**: cambiar el idioma no modifica el texto en edición ni sus marcas (0 cambios).
- **SC-804**: el idioma elegido se conserva al cerrar y abrir la app, el 100 % de las
  veces.
- **SC-805**: con el inglés y la letra al 200 %, 0 desbordes en las pantallas de PA-H3-E1.

## Supuestos pendientes de validación

Decisiones adoptadas para poder implementar; deben confirmarse con el responsable del
proyecto.

1. El español es el idioma por omisión; «Automático» es una opción, no el valor inicial.
2. Las traducciones al inglés las revisa una persona con buen nivel de inglés antes de la
   entrega.
3. El nombre de la app («HandText AI») no se traduce.
4. La constitución §4 («mensajes iniciales de interfaz en español») se cumple porque el
   español sigue siendo el idioma inicial; si la profesora lo interpreta distinto, se
   enmienda la constitución.
