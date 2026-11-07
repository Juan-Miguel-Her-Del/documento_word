## Features principales

HandText AI recuerda los documentos que cada persona guardó:
- una pantalla **Mis documentos** con lo que se guardó, del más reciente al más antiguo;
- **abrir** un documento guardado en el editor para corregirlo, exportarlo de nuevo o
  compartirlo;
- **borrar** un documento del historial o todo el historial.

Esta funcionalidad amplía 001 a 006. **El historial se guarda solo en el teléfono, para
cada cuenta, como el borrador: el servidor sigue sin guardar documentos.**

### 1. Mis documentos

- **Cada vez que un documento se guarda correctamente (Word o PDF), queda en el
  historial de la cuenta.** Un guardado cancelado o fallido no aparece.
- Cada documento muestra:
  - su título: la primera línea con texto, hasta 60 caracteres;
  - la fecha y la hora del último guardado;
  - los formatos en que se guardó (Word, PDF o ambos);
  - cuántas palabras tiene.
- **Volver a guardar el mismo documento (en otro formato o después de corregirlo)
  actualiza su entrada; no la duplica.**
- Se abre desde el inicio, con «Mis documentos».
- Se guardan hasta 50 documentos; al guardar uno más, sale el más antiguo.

### 2. Abrir un documento guardado

- Tocar un documento lo abre en el editor, con su texto, para editarlo, exportarlo y
  compartirlo como cualquier otro.
- **Si hay un texto con cambios sin exportar, la app pide confirmación antes de
  reemplazarlo.**
- Si se edita y la app se cierra, el borrador se recupera y sigue unido a ese documento
  del historial.

### 3. Borrar

- «Eliminar» quita un documento del historial y «Borrar todo» lo vacía. **Ambos piden
  confirmación.**
- **Borrar del historial no toca los archivos Word o PDF ya guardados en el teléfono.**
- **Cerrar sesión conserva el historial; eliminar la cuenta lo borra del teléfono.**
- Otra cuenta en el mismo teléfono nunca ve el historial de la primera.

## Lo que NO se va a construir en esta iteración (Non-Goals)

- Guardar el historial en el servidor o sincronizarlo entre teléfonos.
- ~~Buscar~~, filtrar, ~~renombrar~~ u ordenar en carpetas. *(Buscar y renombrar se
  incorporan en la funcionalidad [010](../010-organizar-documentos/spec.md).)*
- Guardar las imágenes o los archivos Word y PDF dentro del historial (solo el texto).
- Recuperar documentos guardados antes de esta versión.
- ~~Cambiar el idioma (la app sigue en español).~~ *(Se incorpora en la funcionalidad
  [008](../008-idioma-ingles/spec.md): español o inglés.)*

## Clarifications

### Session 2026-10-29

- Q: ¿Qué extras se incorporan ahora? → A: El responsable del proyecto pidió «los demás
  plus» de la lista propuesta. Esta funcionalidad toma el historial de documentos.
- Q: ¿El historial va en el servidor (PostgreSQL) o en el teléfono? → A: En el teléfono,
  como el borrador. Así se mantiene la promesa de privacidad de 001 a 005 («el texto no
  se guarda en el servidor»). Sincronizarlo queda como Non-Goal (supuesto 1).

## Historias de usuario y escenarios de aceptación

Las etiquetas del código usan el prefijo `HD` (historial de documentos): `[HD-H1-E2]` es
la Historia 1, escenario 2, de esta funcionalidad.

### Historia 1 - Encontrar lo que ya guardé (Prioridad: P1)

Un estudiante guardó sus apuntes la semana pasada y hoy quiere saber cómo los llamó y
cuándo.

**Por qué esta prioridad**: hoy, al guardar, el texto desaparece de la app y solo queda el
archivo.

**Prueba independiente**: guardar documentos, cerrar la app y volver a abrirla. Requiere
pruebas automatizadas del almacenamiento, del controlador y de la pantalla.

**Escenarios de aceptación**:

1. **Dado** un texto en el editor, **Cuando** se guarda correctamente como Word o PDF,
   **Entonces** aparece primero en «Mis documentos» con su título, la fecha y hora, el
   formato y la cantidad de palabras.
2. **Dado** un documento ya guardado, **Cuando** se vuelve a guardar en otro formato o
   después de corregirlo, **Entonces** se actualiza su entrada (texto, formatos y fecha)
   y no aparece otra.
3. **Dado** un guardado cancelado o fallido, **Cuando** se abre «Mis documentos»,
   **Entonces** ese intento no aparece.
4. **Dado** el inicio, **Cuando** se toca «Mis documentos», **Entonces** se ven los
   documentos del más reciente al más antiguo; si no hay ninguno, un mensaje lo explica.
5. **Dado** documentos guardados, **Cuando** se cierra y se abre la app, o se cierra
   sesión y se vuelve a entrar con la misma cuenta, **Entonces** siguen ahí.
6. **Dado** otra cuenta en el mismo teléfono, **Cuando** abre «Mis documentos»,
   **Entonces** no ve los documentos de la primera.

### Historia 2 - Abrir un documento guardado (Prioridad: P2)

Una docente encuentra un error en una guía que digitalizó ayer y quiere corregirla y
exportarla de nuevo sin volver a fotografiarla.

**Por qué esta prioridad**: sin abrirlo, el historial solo sirve para mirar.

**Prueba independiente**: abrir un documento del historial, corregirlo y guardarlo.
Requiere pruebas automatizadas del controlador y de la pantalla.

**Escenarios de aceptación**:

1. **Dado** «Mis documentos», **Cuando** se toca un documento, **Entonces** se abre en el
   editor con su texto, listo para editar, exportar y compartir.
2. **Dado** un texto con cambios sin exportar, **Cuando** se toca un documento del
   historial, **Entonces** la app pide confirmación; si se cancela, nada cambia.
3. **Dado** un documento abierto desde el historial, **Cuando** se corrige y se guarda,
   **Entonces** se actualiza esa misma entrada.
4. **Dado** un documento abierto desde el historial y editado, **Cuando** la app se cierra
   y se vuelve a abrir, **Entonces** el borrador se recupera y, al guardarlo, actualiza esa
   entrada.

### Historia 3 - Borrar el historial (Prioridad: P3)

Una persona presta su teléfono y quiere quitar de la lista unos apuntes personales.

**Por qué esta prioridad**: control de la persona sobre sus datos (constitución §3).

**Prueba independiente**: eliminar un documento, borrar todo y eliminar la cuenta.
Requiere pruebas automatizadas del almacenamiento, del controlador y de la pantalla.

**Escenarios de aceptación**:

1. **Dado** un documento del historial, **Cuando** se elige «Eliminar» y se confirma,
   **Entonces** desaparece de la lista; los archivos guardados en el teléfono no cambian.
2. **Dado** «Mis documentos», **Cuando** se elige «Borrar todo» y se confirma,
   **Entonces** la lista queda vacía.
3. **Dado** cualquiera de las dos confirmaciones, **Cuando** se cancela, **Entonces** no
   se borra nada.
4. **Dado** una cuenta con historial, **Cuando** se elimina la cuenta, **Entonces** su
   historial se borra del teléfono.

### Casos límite

- Al guardar el documento 51, sale el más antiguo.
- Si el historial no se puede actualizar (por ejemplo, sin espacio), el archivo igual se
  guarda y el guardado se informa como correcto: el historial es un extra, no parte del
  guardado.
- Si el archivo del historial está dañado, la lista aparece vacía y la app sigue
  funcionando.
- Si la cuenta se elimina desde otro teléfono, el historial de este teléfono deja de ser
  accesible y se borra al borrar los datos de la app o desinstalarla.

## Criterios de éxito medibles

- **SC-701**: el 100 % de los guardados correctos aparece en el historial, y 0 guardados
  cancelados o fallidos.
- **SC-702**: 0 entradas duplicadas al volver a guardar el mismo documento.
- **SC-703**: una cuenta nunca ve el historial de otra en el mismo teléfono.
- **SC-704**: al eliminar la cuenta, queda 0 rastro de su historial en el teléfono.
- **SC-705**: con 50 documentos guardados, «Mis documentos» se abre y un documento se
  abre en el editor en menos de 1 s en el emulador de referencia (Android 16).

## Supuestos pendientes de validación

Decisiones adoptadas para poder implementar; deben confirmarse con el responsable del
proyecto.

1. El historial vive solo en el teléfono, para cada cuenta; no se envía al servidor.
2. Hasta 50 documentos por cuenta.
3. El título es la primera línea con texto, hasta 60 caracteres.
4. Cerrar sesión conserva el historial; eliminar la cuenta lo borra.
5. El historial se agrega al alcance de 001, que lo dejaba fuera: la profesora debe
   aprobarlo (constitución §1).
