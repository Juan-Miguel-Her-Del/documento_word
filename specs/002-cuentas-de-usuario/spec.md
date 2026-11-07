## Features principales

HandText AI incorpora cuentas de usuario y una nueva identidad visual. Cada persona crea
una cuenta con su nombre, su correo y una contraseña, e inicia sesión para usar el
reconocimiento y la exportación. Esta funcionalidad amplía el MVP de
[001-handtext-mvp](../001-handtext-mvp/spec.md): reemplaza su regla de uso sin cuenta y
conserva todas las demás.

### 1. Bienvenida y registro

- Mostrar una pantalla de bienvenida con el propósito de la aplicación y las opciones de
  crear una cuenta o iniciar sesión.
- Permitir crear una cuenta con nombre para mostrar, correo electrónico y contraseña.
- **Validar el formato y la longitud del correo, exigir un nombre de 1 a 60 caracteres y
  una contraseña de 8 a 128 caracteres, e indicar el motivo de cada rechazo.**
- **Pedir autorización para tratar los datos personales de la cuenta (nombre y correo)
  antes de crearla. Sin autorización, la cuenta no se crea.**
- **No permitir dos cuentas con el mismo correo; el correo se compara sin distinguir
  mayúsculas de minúsculas.**
- Iniciar sesión automáticamente al crear la cuenta.

### 2. Inicio y cierre de sesión

- Permitir iniciar sesión con correo y contraseña.
- **Ante datos incorrectos, mostrar un único mensaje que no revele si el correo existe.**
- **Tras 5 intentos fallidos seguidos, bloquear el inicio de sesión de esa cuenta durante
  15 minutos e informarlo.**
- Mantener la sesión abierta durante 30 días en el teléfono, aunque se cierre la
  aplicación.
- Permitir cerrar la sesión. **Si hay texto sin exportar, pedir confirmación, porque se
  descartará.**
- **Si la sesión vence o deja de ser válida, informarlo y pedir que se inicie sesión de
  nuevo, conservando el texto en edición de esa persona.**

### 3. Acceso protegido

- **El reconocimiento y la exportación solo están disponibles con una sesión válida.**
- **Las contraseñas y los tokens de sesión nunca se guardan ni se registran en texto
  plano.**
- **La sesión se guarda en el almacenamiento seguro del teléfono.**
- **Una persona no puede ver el texto en edición de otra que use el mismo teléfono.**

### 4. Eliminación de la cuenta

- Permitir eliminar la cuenta desde la aplicación, confirmando con la contraseña.
- **Al eliminarla, se borran del servidor la cuenta y sus sesiones, y del teléfono la
  sesión y el borrador de esa persona.**

### 5. Identidad visual

- Presentar todas las pantallas con un estilo común: ~~degradados, tarjetas translúcidas,~~
  **fondo azul marino, botones de color sólido, tarjetas con borde fino,** tipografía propia
  y animaciones sobrias (Clarifications, 2026-10-28).
- Mostrar una animación de escaneo sobre la imagen mientras se reconoce el texto.
- **Respetar la preferencia del sistema de reducir animaciones y su modo oscuro.**
- **Mantener legibles los textos largos del editor y los mensajes en español.**

## Lo que NO se va a construir en esta iteración (Non-Goals)

- Recuperación de contraseña por correo y verificación del correo.
- Inicio de sesión con Google u otros proveedores.
- Edición del perfil (nombre, correo o contraseña) después de crear la cuenta.
- Historial de documentos o almacenamiento en la nube (siguen fuera, como en 001).
- Roles, cuentas compartidas o administración de usuarios.

## Clarifications

### Session 2026-10-27

- Q: ¿Cómo se resuelve el inicio de sesión que 001 excluía? → A: Con cuentas reales de
  correo y contraseña en una funcionalidad nueva (002). La regla de 001 de usar la app sin
  cuenta queda reemplazada.
- Q: ¿Qué estilo visual se adopta? → A: «Aurora»: ~~degradados índigo y violeta, tarjetas
  translúcidas,~~ tipografía grande y animación de escaneo, con modo oscuro automático.
  *(Paleta reemplazada el 2026-10-28, ver abajo.)*

### Session 2026-10-28

- Q: La paleta índigo, violeta y rosa no se ve profesional. ¿Qué colores se usan? → A:
  «Azul corporativo». La identidad conserva el nombre «Aurora», sus pantallas y sus
  animaciones, pero cambia a:
  - fondo azul marino casi plano;
  - botones de azul sólido, sin degradado;
  - un acento celeste solo para el escaneo;
  - tarjetas sólidas con borde fino.

  Se eliminan el rosa, el violeta y las luces de colores.

### Session 2026-10-29

- Q: ¿La app usa un ícono propio en el teléfono? → A: Sí. El logo-escáner azul (hoja
  blanca con el marco y la línea de escaneo) reemplaza al ícono de Flutter. Es un ícono
  adaptable de Android y tiene una versión monocromática para los íconos con tema.

## Historias de usuario y escenarios de aceptación

Las etiquetas del código usan el prefijo `CU` (cuentas de usuario): `[CU-H1-E2]` es la
Historia 1, escenario 2, de esta funcionalidad.

### Historia 1 - Crear una cuenta e ingresar (Prioridad: P1)

Una estudiante instala la app, crea su cuenta con su correo y empieza a digitalizar sus
apuntes; al día siguiente la app la recuerda.

**Por qué esta prioridad**: sin cuenta no se puede usar el reconocimiento ni la
exportación.

**Prueba independiente**: crear una cuenta, cerrar la app, volver a abrirla y comprobar
que la sesión sigue abierta; intentar ingresar con datos incorrectos. Requiere pruebas
automatizadas del registro, el ingreso y el bloqueo.

**Escenarios de aceptación**:

1. **Dado** que no hay sesión, **Cuando** se abre la app, **Entonces** se muestra la
   bienvenida con «Crear cuenta» e «Iniciar sesión».
2. **Dado** el formulario de registro con datos válidos y la autorización marcada,
   **Cuando** se envía, **Entonces** se crea la cuenta y se entra a la app.
3. **Dado** un correo ya registrado (aunque cambien las mayúsculas), **Cuando** se intenta
   registrar, **Entonces** se rechaza indicando que ya existe una cuenta con ese correo.
4. **Dado** un nombre, un correo o una contraseña que no cumplen las reglas, **Cuando** se
   intenta registrar, **Entonces** se rechaza indicando el motivo.
5. **Dado** que no se marcó la autorización de datos, **Cuando** se intenta registrar,
   **Entonces** la cuenta no se crea.
6. **Dado** una cuenta existente, **Cuando** se ingresa con el correo y la contraseña
   correctos, **Entonces** se entra a la app y se saluda a la persona por su nombre.
7. **Dado** un correo inexistente o una contraseña incorrecta, **Cuando** se intenta
   ingresar, **Entonces** se muestra el mismo mensaje en ambos casos.
8. **Dado** 5 intentos fallidos seguidos, **Cuando** se intenta otra vez, **Entonces** se
   informa el bloqueo de 15 minutos, aunque la contraseña sea correcta.
9. **Dado** una sesión iniciada, **Cuando** se cierra y se vuelve a abrir la app,
   **Entonces** la sesión sigue abierta.

### Historia 2 - Cerrar sesión y eliminar la cuenta (Prioridad: P2)

Un docente presta su teléfono: cierra su sesión y, al final del curso, elimina su cuenta.

**Por qué esta prioridad**: protege la privacidad cuando varias personas usan el mismo
teléfono y permite retirar los datos personales.

**Prueba independiente**: cerrar sesión con y sin texto pendiente; eliminar la cuenta con
contraseña correcta e incorrecta. Requiere pruebas automatizadas de la persistencia.

**Escenarios de aceptación**:

1. **Dado** una sesión sin texto pendiente, **Cuando** la persona cierra sesión,
   **Entonces** vuelve a la bienvenida y la sesión deja de servir en el servidor.
2. **Dado** un texto sin exportar, **Cuando** la persona cierra sesión, **Entonces** se
   pide confirmación; si confirma, el texto se descarta; si cancela, todo sigue igual.
3. **Dado** la opción de eliminar la cuenta, **Cuando** la persona confirma con su
   contraseña, **Entonces** se borran la cuenta, sus sesiones y su borrador, y vuelve a la
   bienvenida.
4. **Dado** una contraseña incorrecta al eliminar, **Cuando** confirma, **Entonces** la
   cuenta no se elimina y se informa el motivo.
5. **Dado** una sesión vencida o inválida, **Cuando** se intenta reconocer o exportar,
   **Entonces** se pide iniciar sesión y, si vuelve a ingresar la misma persona, su texto
   sigue disponible.
6. **Dado** dos personas que usan el mismo teléfono, **Cuando** una ingresa, **Entonces**
   no ve el texto en edición de la otra.

### Historia 3 - Experiencia visual Aurora (Prioridad: P3)

**Por qué esta prioridad**: mejora la primera impresión y la claridad, sin cambiar las
reglas del flujo.

**Prueba independiente**: recorrer todas las pantallas en modo claro y oscuro, con y sin
la preferencia de reducir animaciones.

**Escenarios de aceptación**:

1. **Dado** cualquier pantalla, **Cuando** se muestra, **Entonces** usa la identidad visual
   común.
2. **Dado** un reconocimiento en curso, **Cuando** se espera el resultado, **Entonces** se
   ve la animación de escaneo sobre la imagen.
3. **Dado** que el sistema pide reducir animaciones, **Cuando** se abre la app,
   **Entonces** las animaciones decorativas se detienen.
4. **Dado** el modo oscuro del sistema, **Cuando** se abre la app, **Entonces** las
   pantallas usan colores oscuros legibles.

### Casos límite

- Sin conexión al abrir la app con una sesión guardada: se entra con los datos guardados
  y, si luego el servidor rechaza la sesión, se pide ingresar de nuevo.
- Si el servicio de cuentas no está disponible, se informa sin revelar detalles técnicos.
- Al eliminar la cuenta, las operaciones en curso de esa sesión dejan de autorizarse.

## Criterios de éxito medibles

- **SC-201**: ninguna contraseña ni token de sesión aparece en texto plano en la base de
  datos ni en los registros.
- **SC-202**: el 100 % de las solicitudes de reconocimiento y exportación sin una sesión
  válida se rechazan.
- **SC-203**: el mensaje de error de ingreso es idéntico para un correo inexistente y para
  una contraseña incorrecta.
- **SC-204**: tras 5 intentos fallidos, el siguiente se rechaza durante 15 minutos aunque la
  contraseña sea correcta.
- **SC-205**: tras eliminar una cuenta, no queda en la base ningún registro con su correo
  ni sesiones suyas.
- **SC-206**: una persona nunca ve el borrador de otra en el mismo teléfono.
- **SC-207**: con la preferencia de reducir animaciones activa, no hay animaciones
  decorativas en repetición.
- **SC-208**: sobre el fondo y las tarjetas de la identidad visual, los pares de colores
  tienen un contraste mínimo (WCAG 2.1, nivel AA):
  - 4,5:1 para todo el texto, incluido el de los botones, los enlaces y los avisos;
  - 3:1 para los bordes de los campos con foco y los íconos.

## Supuestos pendientes de validación

Decisiones adoptadas para poder implementar; deben confirmarse con el responsable del
proyecto.

1. La cuenta es obligatoria para usar la app.
2. La sesión dura 30 días desde que se inicia.
3. El bloqueo es de 15 minutos tras 5 intentos fallidos seguidos.
4. La contraseña exige longitud (8 a 128 caracteres), no símbolos ni mayúsculas.
5. Al cerrar sesión se descarta el texto no exportado, previa confirmación; si la sesión
   vence, el texto se conserva para la misma persona.
6. Eliminar la cuenta exige escribir la contraseña.
