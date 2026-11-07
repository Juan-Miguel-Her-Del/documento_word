## Features principales

HandText AI queda lista para entregarse:
- una pantalla de **Ajustes** para el tema y el tamaño de letra del editor;
- una pantalla **Acerca de** con la versión, la privacidad y las licencias;
- una **versión final** firmada que se puede instalar en cualquier teléfono Android.

Esta funcionalidad amplía 001 a 004 sin cambiar sus reglas.

### 1. Ajustes

- Elegir el tema de la app: automático (según el teléfono), claro u oscuro.
- **El tema cambia el editor, los diálogos y las hojas. Las pantallas de bienvenida,
  ingreso, inicio y vista previa conservan siempre el fondo azul marino de la identidad
  Aurora.**
- Elegir el tamaño de letra del editor: normal, grande o muy grande. Se suma al tamaño de
  letra del sistema.
- **Los ajustes se guardan en el teléfono y se conservan al cerrar la app y al cambiar de
  cuenta.**
- Los ajustes no contienen datos personales ni documentos.

### 2. Acerca de

- Mostrar el nombre, el logo y la versión de la app (por ejemplo, «Versión 1.0.0
  (1)»).
- **Explicar qué datos usa la app, dónde se guardan y cuándo se borran.** Es el resumen
  de las reglas de privacidad de 001 a 004.
- **Mostrar las licencias de todas las librerías y de la tipografía Poppins (OFL).**
- Se puede abrir sin haber iniciado sesión (desde la bienvenida), porque la privacidad
  debe poder leerse antes de crear una cuenta.

### 3. Versión final

- **La versión final se firma con una clave propia del proyecto. La clave y sus
  contraseñas nunca se guardan en el repositorio (constitución §2).**
- **La versión final solo se conecta por HTTPS.** Para una demostración con la API en el
  computador, se puede compilar una versión de demostración que permita HTTP, y eso se
  pide de forma explícita al compilar.
- La versión que muestra la app coincide siempre con la del paquete instalado.

## Lo que NO se va a construir en esta iteración (Non-Goals)

- Publicar la app en Google Play.
- Ajustes guardados en la cuenta o sincronizados entre teléfonos.
- ~~Cambiar el idioma (la app sigue en español).~~ *(Se incorpora en la funcionalidad
  [008](../008-idioma-ingles/spec.md): español o inglés.)*
- Notificaciones.
- Publicar la API con HTTPS en internet.

## Clarifications

### Session 2026-10-29

- Q: ¿Qué se incorpora para que la app se vea más profesional? → A: Ajustes, «Acerca
  de» y la versión final firmada. Las eligió el responsable del proyecto entre varias
  propuestas, junto con un documento y diapositivas del proyecto, que no son parte de la
  app.

## Historias de usuario y escenarios de aceptación

Las etiquetas del código usan el prefijo `AV` (ajustes y versión): `[AV-H1-E2]` es la
Historia 1, escenario 2, de esta funcionalidad.

### Historia 1 - Ajustar la app (Prioridad: P1)

Un docente con poca vista agranda la letra del editor y elige el tema oscuro para revisar
de noche.

**Por qué esta prioridad**: la revisión del texto es la tarea más larga de la app, y leer
cómodo cambia la experiencia.

**Prueba independiente**: cambiar cada ajuste, cerrar y abrir la app. Requiere pruebas
automatizadas del almacenamiento y de las pantallas.

**Escenarios de aceptación**:

1. **Dado** una sesión iniciada, **Cuando** se abre el menú de la cuenta, **Entonces**
   ofrece «Ajustes» y «Acerca de».
2. **Dado** Ajustes, **Cuando** se elige el tema oscuro (o claro), **Entonces** el editor,
   los diálogos y las hojas se ven oscuros (o claros), aunque el teléfono use el otro
   modo.
3. **Dado** Ajustes, **Cuando** se elige «Automático», **Entonces** la app sigue el modo
   del teléfono, como en 002.
4. **Dado** Ajustes, **Cuando** se elige la letra grande o muy grande, **Entonces** el
   texto del editor se ve más grande y sigue siendo editable.
5. **Dado** unos ajustes elegidos, **Cuando** se cierra y se abre la app o se cambia de
   cuenta, **Entonces** se conservan.
6. **Dado** que el archivo de ajustes no existe o está dañado, **Cuando** se abre la app,
   **Entonces** se usan los valores por omisión (automático y normal).

### Historia 2 - Conocer la app (Prioridad: P2)

Antes de crear su cuenta, una estudiante quiere saber qué pasa con sus fotos.

**Por qué esta prioridad**: transparencia sobre los datos (constitución §3) y requisito
habitual de cualquier app.

**Prueba independiente**: abrir «Acerca de» desde la bienvenida y desde el menú, y
revisar la privacidad y las licencias. Requiere pruebas automatizadas de pantalla y de
la versión.

**Escenarios de aceptación**:

1. **Dado** la bienvenida, **Cuando** se toca «Privacidad y acerca de», **Entonces** se
   abre «Acerca de» sin iniciar sesión.
2. **Dado** «Acerca de», **Cuando** se muestra, **Entonces** se ven el logo, el nombre y
   la versión.
3. **Dado** «Acerca de», **Cuando** se lee la privacidad, **Entonces** explica:
   - que la imagen se envía a HandText AI y a Google solo con autorización y no se
     guarda;
   - que el texto en edición queda solo en el teléfono hasta exportarlo o descartarlo;
   - que la cuenta guarda nombre, correo y contraseña cifrada;
   - cómo se elimina la cuenta.
4. **Dado** «Acerca de», **Cuando** se toca «Licencias», **Entonces** se listan las
   licencias de las librerías y la de Poppins.

### Historia 3 - Instalar la versión final (Prioridad: P3)

El responsable del proyecto instala la app en su teléfono para la presentación.

**Por qué esta prioridad**: la versión de depuración es lenta y no es la que se entrega.

**Prueba independiente**: compilar la versión final, instalarla y medir el arranque.

**Escenarios de aceptación**:

1. **Dado** la clave del proyecto configurada, **Cuando** se compila la versión final,
   **Entonces** el APK queda firmado con esa clave, no con la de depuración.
2. **Dado** la versión final normal, **Cuando** intenta conectarse a una API por HTTP,
   **Entonces** Android no lo permite.
3. **Dado** la versión de demostración pedida al compilar, **Cuando** se conecta a la API
   del computador por HTTP, **Entonces** funciona.
4. **Dado** la versión final instalada, **Cuando** se abre «Acerca de», **Entonces** la
   versión coincide con la del paquete.

### Casos límite

- Sin la clave del proyecto, la versión final se firma con la clave de depuración y la
  compilación lo advierte. Ese APK no se entrega.
- Si el tamaño de letra del sistema ya es grande, el ajuste del editor se suma y el
  editor sigue pudiendo desplazarse.

## Criterios de éxito medibles

- **SC-501**: los ajustes elegidos se conservan al cerrar y abrir la app, el 100 % de las
  veces.
- **SC-502**: la versión mostrada en «Acerca de» coincide con la de `pubspec.yaml`.
- **SC-503**: la pantalla de licencias incluye la de Poppins (OFL) y las de las librerías
  usadas.
- **SC-504**: la versión final abre en menos de 5 s en frío en el emulador de referencia
  (Android 16).
- **SC-505**: ninguna clave de firma ni contraseña está en el repositorio.
- **SC-506**: la versión final normal rechaza las conexiones HTTP sin cifrar.

## Supuestos pendientes de validación

Decisiones adoptadas para poder implementar; deben confirmarse con el responsable del
proyecto.

1. Los ajustes son del teléfono, no de la cuenta.
2. Tres tamaños de letra: normal (100 %), grande (120 %) y muy grande (140 %).
3. Las pantallas Aurora no cambian con el tema: son parte de la identidad visual.
4. La versión de demostración con HTTP solo se usa en presentaciones con la API local.
