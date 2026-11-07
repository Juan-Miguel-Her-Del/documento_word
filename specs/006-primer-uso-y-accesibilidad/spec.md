## Features principales

HandText AI ayuda desde el primer uso y se puede usar con las herramientas de
accesibilidad de Android:
- **Consejos para una buena foto** la primera vez que se entra a la app, y cuando se
  quieran volver a ver;
- uso completo con **TalkBack**, el lector de pantalla de Android;
- uso completo con la **letra grande del sistema**, hasta el 200 %.

Esta funcionalidad amplía 001 a 005 sin cambiar sus reglas.

### 1. Consejos para una buena foto

- Cuatro consejos cortos, uno por pantalla:
  1. buena luz, sin sombras ni reflejos;
  2. toda la hoja, de frente, y recortar los bordes que sobren;
  3. una hoja por foto; para varias hojas, agregarlas como páginas;
  4. revisar las palabras resaltadas antes de guardar.
- Se pasa de uno a otro con «Siguiente»; el último termina con «Empezar». «Saltar» los
  cierra en cualquier momento.
- **Aparecen solos una única vez en el teléfono, la primera vez que se entra a la app
  con una cuenta.** Después se pueden abrir desde el inicio y desde Ajustes.
- Los consejos no piden permisos ni envían nada.

### 2. TalkBack

- **Cada botón, enlace y campo tiene un nombre que dice qué hace.** Los íconos y
  dibujos decorativos no se leen.
- **Los avisos de estado (reconociendo, guardado, fallo) se leen solos**, sin que la
  persona tenga que buscarlos.
- **Al ir a una palabra dudosa con «Siguiente», TalkBack lee la palabra**, porque el
  resaltado amarillo no se puede ver.
- El título de cada pantalla está marcado como encabezado, para saltar entre secciones.

### 3. Letra grande del sistema

- **Con la letra del sistema al 200 %, ninguna pantalla, menú, hoja ni diálogo corta ni
  superpone su contenido**; lo que no cabe se alcanza desplazando.
- En el editor, los avisos de arriba se desplazan en su propio espacio y **el texto
  siempre conserva lugar para editarse**.
- **Todo lo que se puede tocar mide al menos 48 × 48 dp**, el tamaño mínimo que
  recomienda Android.

## Lo que NO se va a construir en esta iteración (Non-Goals)

- Videos o animaciones de tutorial.
- Consejos distintos para cada cuenta.
- Certificar la app con una auditoría externa de accesibilidad.
- Control por voz o por interruptores.
- Cambiar las pantallas de otras apps que la app abre (el recorte con uCrop, el diálogo
  para guardar y el menú de compartir de Android).
- ~~Cambiar el idioma (la app sigue en español).~~ *(Se incorpora en la funcionalidad
  [008](../008-idioma-ingles/spec.md): español o inglés.)*

## Clarifications

### Session 2026-10-29

- Q: ¿Qué extras se incorporan ahora? → A: El responsable del proyecto pidió «los demás
  plus» de la lista propuesta, en lugar del documento y las diapositivas. De esa lista,
  esta funcionalidad toma el tutorial de la primera vez y la revisión de accesibilidad
  (TalkBack y letra grande). El historial y el idioma inglés van en funcionalidades
  propias.

## Historias de usuario y escenarios de aceptación

Las etiquetas del código usan el prefijo `PA` (primer uso y accesibilidad):
`[PA-H1-E2]` es la Historia 1, escenario 2, de esta funcionalidad.

### Historia 1 - Ver los consejos la primera vez (Prioridad: P1)

Una estudiante crea su cuenta y, antes de su primera foto, aprende a tomarla bien para
que la IA reconozca mejor su letra.

**Por qué esta prioridad**: la calidad de la foto es lo que más influye en el
reconocimiento, y hoy nada lo explica.

**Prueba independiente**: entrar por primera vez, recorrer y saltar los consejos, cerrar
y abrir la app. Requiere pruebas automatizadas del ajuste guardado y de la pantalla.

**Escenarios de aceptación**:

1. **Dado** un teléfono donde nunca se vieron los consejos, **Cuando** una persona entra
   a la app con su cuenta, **Entonces** ve el primer consejo antes del inicio.
2. **Dado** un consejo que no es el último, **Cuando** se toca «Siguiente», **Entonces**
   se muestra el siguiente; en el último, «Empezar» lleva al inicio.
3. **Dado** cualquier consejo, **Cuando** se toca «Saltar» o el botón atrás de Android,
   **Entonces** se va al inicio.
4. **Dado** que los consejos ya se vieron o se saltaron, **Cuando** se cierra y se abre
   la app, o entra otra cuenta en el mismo teléfono, **Entonces** no vuelven a aparecer
   solos.
5. **Dado** el inicio o Ajustes, **Cuando** se toca «Consejos para una buena foto»,
   **Entonces** se abren los consejos y, al terminar o saltarlos, se vuelve a esa
   pantalla.

### Historia 2 - Usar la app con TalkBack (Prioridad: P2)

Un docente con baja visión usa TalkBack para digitalizar las notas de una reunión.

**Por qué esta prioridad**: sin nombres en los botones ni avisos hablados, la app no se
puede usar con un lector de pantalla.

**Prueba independiente**: activar TalkBack y completar elegir imagen, reconocer, revisar
y exportar. Requiere pruebas automatizadas de nombres, avisos y encabezados.

**Escenarios de aceptación**:

1. **Dado** TalkBack activo, **Cuando** se recorre cualquier pantalla, **Entonces** cada
   elemento que se puede tocar tiene un nombre que dice qué hace, incluido el botón de
   la cuenta.
2. **Dado** una operación en curso, **Cuando** aparece un aviso de estado, **Entonces**
   TalkBack lo lee sin que la persona mueva el foco.
3. **Dado** el editor con palabras dudosas, **Cuando** se toca «Siguiente», **Entonces**
   TalkBack lee la palabra seleccionada.
4. **Dado** los consejos, **Cuando** TalkBack los recorre, **Entonces** lee «Consejo 2
   de 4», el título y el texto, y omite los dibujos.
5. **Dado** cualquier pantalla, **Cuando** TalkBack navega por encabezados, **Entonces**
   encuentra su título.

### Historia 3 - Usar la app con la letra grande del sistema (Prioridad: P3)

Una persona mayor tiene la letra del teléfono al máximo y necesita que la app siga
completa.

**Por qué esta prioridad**: con la letra al 200 %, hoy el editor y un diálogo se cortan.

**Prueba independiente**: poner la letra del sistema al 200 % y recorrer todas las
pantallas. Requiere pruebas automatizadas de desbordes y de tamaño de los botones.

**Escenarios de aceptación**:

1. **Dado** la letra del sistema al 200 %, **Cuando** se recorren la bienvenida, el
   registro, el ingreso, los consejos, el inicio, la vista previa, el editor, Ajustes,
   «Acerca de», Privacidad, los menús, las hojas y los diálogos, **Entonces** nada se
   corta ni se superpone.
2. **Dado** el editor con la letra al 200 %, **Cuando** hay avisos y palabras dudosas,
   **Entonces** los avisos se desplazan en su espacio, el texto sigue editable y
   «Exportar» sigue a la vista.
3. **Dado** cualquier pantalla, **Cuando** se mide lo que se puede tocar, **Entonces**
   todo mide al menos 48 × 48 dp.

### Casos límite

- Si no se puede guardar que los consejos ya se vieron (por ejemplo, sin espacio), no
  vuelven a aparecer mientras la app siga abierta.
- Quien actualiza desde una versión anterior ve los consejos una vez.
- Si hay un borrador para recuperar, los consejos aparecen primero y el borrador se
  recupera igual al llegar al inicio.
- Con la letra al 200 % y el teclado abierto, el editor reduce los avisos y conserva el
  campo de texto.

## Criterios de éxito medibles

- **SC-601**: los consejos aparecen solos una sola vez por teléfono: 0 apariciones
  automáticas después de verlos o saltarlos, al cerrar y abrir la app y al cambiar de
  cuenta.
- **SC-602**: el 100 % de los elementos que se pueden tocar en las pantallas del
  escenario PA-H3-E1 tienen un nombre para TalkBack.
- **SC-603**: el 100 % de esos elementos mide al menos 48 × 48 dp.
- **SC-604**: con la letra del sistema al 200 %, 0 desbordes en esas pantallas.
- **SC-605**: los avisos de estado y la palabra elegida con «Siguiente» se anuncian sin
  mover el foco.
- **SC-606**: en el emulador de referencia (Android 16) con TalkBack, se completan
  elegir imagen, reconocer y exportar.

## Supuestos pendientes de validación

Decisiones adoptadas para poder implementar; deben confirmarse con el responsable del
proyecto.

1. Los consejos son del teléfono, no de la cuenta (como los ajustes de 005).
2. Cuatro consejos son suficientes; sus textos los revisa el responsable del proyecto.
3. El 200 % es la referencia de letra grande (el máximo de Android 14 y posteriores).
4. Las pantallas de otras apps (uCrop, guardar, compartir) quedan fuera del alcance.
