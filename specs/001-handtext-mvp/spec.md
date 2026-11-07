## Features principales

HandText AI es una aplicación móvil para estudiantes, docentes, profesionales, empresas
y personas que necesitan convertir documentos manuscritos en texto digital. Su propósito
es reducir el trabajo de transcripción manual mediante reconocimiento de escritura,
revisión del usuario y exportación a Word o PDF. La primera versión se dirige a Android
y procesa una imagen de un documento a la vez.

### 1. Captura y selección del documento

- Permitir tomar una fotografía de un documento escrito a mano con la cámara del dispositivo.
- Permitir seleccionar una imagen de un documento almacenada en el dispositivo.
- Mostrar la imagen antes de iniciar el reconocimiento y permitir aceptarla, reemplazarla
  o cancelar la selección.
- Solicitar los permisos necesarios para acceder a la cámara o seleccionar una imagen.
  Si el usuario los deniega, mostrar una explicación y permitir volver al paso anterior.
- Validar que el archivo seleccionado sea una imagen que pueda abrirse antes de procesarlo.
- **Conservar la imagen original: cualquier preparación para el reconocimiento debe trabajar
  sobre una copia y no sobrescribir el archivo del usuario.**
- **Admitir imágenes JPEG y PNG, identificadas por su contenido y no por su extensión,
  de hasta 10 MB y con dimensiones entre 600 y 10 000 píxeles por lado.**

### 2. Reconocimiento del texto manuscrito

- Permitir iniciar el reconocimiento del contenido escrito a mano de la imagen aceptada.
- Mostrar que el documento se está procesando y presentar el resultado como texto editable.
- Advertir que el reconocimiento puede contener errores y que el usuario debe revisar
  el resultado antes de exportarlo.
- **Transcribir el contenido identificado sin inventar fragmentos ilegibles ni aplicar
  traducciones, resúmenes o mejoras de redacción automáticamente.**
- Si no se reconoce texto, mostrar un aviso y permitir seleccionar otra imagen o repetir
  la captura, sin presentar un documento vacío como resultado satisfactorio.
- **No reemplazar un texto que ya contiene correcciones del usuario con un nuevo resultado
  de reconocimiento sin su confirmación. Si el nuevo reconocimiento falla, conservar
  las correcciones anteriores.**
- Reconocer escritura en español y en inglés.
- **Si en 60 segundos no se obtiene un resultado, informar el fallo y permitir reintentar.**
- **Pendiente de definición:** calidad mínima aceptable del reconocimiento.

### 3. Revisión y edición del texto

- Mostrar el texto reconocido en un editor dentro de la aplicación.
- Permitir agregar, eliminar y modificar palabras, corregir títulos y separar el contenido
  en párrafos, conservando los caracteres escritos por el usuario.
- Permitir revisar las modificaciones antes de solicitar la exportación.
- **La versión válida para exportar debe ser la última versión del texto confirmada por
  el usuario, incluidas sus correcciones; no una transcripción anterior.**
- **Conservar el texto editado si falla el reconocimiento o la exportación mientras
  el usuario continúa trabajando en el documento.**
- **Solicitar confirmación antes de una acción que descarte o sustituya correcciones;
  cancelar esa acción debe conservarlas.**

### 4. Exportación y guardado en Word y PDF

- Permitir elegir entre exportar el texto revisado a Microsoft Word (.docx) o a PDF (.pdf).
- Permitir guardar el archivo generado en el dispositivo e informar si el guardado terminó
  correctamente o si ocurrió un error.
- Generar un archivo Word que pueda abrirse y editarse en una aplicación compatible,
  o un PDF que pueda abrirse en un lector compatible, según la opción seleccionada.
- **Impedir la exportación cuando el texto esté vacío o contenga únicamente espacios.**
- **El contenido exportado debe corresponder a la última versión confirmada del documento
  y conservar el orden del texto, sus caracteres y la separación de párrafos, sin truncarlo.**
- **El formato real del archivo debe coincidir con su extensión: cambiar el nombre de
  una extensión no constituye una conversión.**
- **No sobrescribir un archivo existente sin confirmación del usuario o sin ofrecer
  un mecanismo de recuperación.**
- **Un fallo al generar o guardar el archivo no debe anunciarse como una exportación
  exitosa ni eliminar el texto que el usuario estaba editando.**

### 5. Validaciones, estados y manejo de errores

- Mostrar mensajes en español que distingan una operación en curso, una operación terminada
  y una operación fallida.
- Informar cuando una imagen no pueda abrirse, no cumpla los formatos o límites acordados,
  no produzca texto reconocible o falle su procesamiento.
- Informar cuando un problema de conexión impida completar una operación que la necesite.
- Explicar qué puede hacer el usuario ante un error, como elegir otra imagen, repetir
  la captura o reintentar la operación.
- Evitar que pulsaciones repetidas sobre la misma acción inicien operaciones duplicadas
  mientras esa acción se está procesando.
- **Validar las entradas antes de procesarlas o generar archivos y rechazar las que
  incumplan las condiciones acordadas, indicando el motivo.**
- **Los mensajes al usuario no deben mostrar credenciales, rutas internas ni detalles
  técnicos sensibles.**

### 6. Privacidad y control de los documentos

- ~~Permitir utilizar el flujo del MVP sin crear una cuenta ni iniciar sesión.~~
  Reemplazado el 2026-10-27: desde la funcionalidad
  [002-cuentas-de-usuario](../002-cuentas-de-usuario/spec.md), usar el flujo requiere
  iniciar sesión.
- **Mantener la privacidad de las imágenes, los textos y los documentos generados. Un usuario
  no debe poder acceder a documentos de otro usuario.**
- **Antes de enviar el contenido a un servicio externo, informar al usuario de ese
  tratamiento y obtener su autorización. Sin autorización, no se debe enviar el contenido.**
- **No incluir documentos privados, transcripciones ni credenciales en los registros
  de diagnóstico.**
- **El servicio de procesamiento no almacena imágenes ni textos: los trata en memoria
  durante cada solicitud.**
- **La copia de trabajo de la imagen se conserva solo hasta terminar el reconocimiento
  o cancelar la selección; las copias que queden de una sesión anterior se eliminan al
  abrir la aplicación.**
- **El texto con cambios no exportados se guarda como borrador en el almacenamiento privado
  de la aplicación, se recupera al volver a abrirla y se elimina al exportarlo correctamente
  o al descartarlo con confirmación. El borrador no se incluye en copias de seguridad.**

## Lo que NO se va a construir en esta iteración (Non-Goals)

- Registro de usuarios, inicio de sesión con correo o Google y administración de perfiles.
  (El registro y el inicio de sesión con correo se incorporan en la funcionalidad 002; el
  inicio con Google y la administración de perfiles siguen fuera).
- ~~Historial persistente de documentos~~ y almacenamiento de una biblioteca en la nube.
  *(El historial se incorpora en la funcionalidad
  [007](../007-historial-de-documentos/spec.md), solo en el teléfono; la biblioteca en la
  nube sigue fuera.)*
- ~~Captura o reconocimiento de múltiples páginas o imágenes dentro de un mismo documento.~~
  *(Se incorpora en la funcionalidad [004](../004-varias-paginas/spec.md), hasta 10
  páginas.)*
- Reconocimiento estructurado de tablas, diagramas o formularios con campos identificados.
- Reproducción exacta del diseño, la tipografía y la distribución del documento original.
- Detección automática del idioma y traducción de documentos.
- Resúmenes, mejoras de redacción, corrección ortográfica automática o transformación
  de apuntes en informes mediante IA.
- Búsqueda de palabras en un historial, categorías y organización automática de documentos.
- Lectura del texto mediante voz.
- Edición avanzada con estilos, plantillas o herramientas de maquetación.
- Versión para iOS o una versión web de la aplicación.

## Clarifications

### Session 2026-10-26

- Q: ¿Qué imágenes se admiten? → A: JPEG y PNG, identificadas por su contenido, de hasta
  10 MB y con dimensiones entre 600 y 10 000 píxeles por lado.
- Q: ¿Qué idiomas se reconocen y cuánto puede esperar el usuario? → A: Español e inglés;
  si en 60 segundos no hay resultado, se informa el fallo y se ofrece reintentar.
- Q: ¿Qué se conserva de los documentos? → A: Nada en el servicio de procesamiento. En el
  teléfono, solo un borrador del texto con cambios no exportados, en el almacenamiento
  privado de la aplicación, que se elimina al exportar correctamente o al descartarlo.

### Session 2026-10-27

- Q: ¿Se mantiene el uso de la app sin cuenta? → A: No. Se incorporan cuentas de correo y
  contraseña en la funcionalidad 002; el resto de este spec sigue vigente.

## Historias de usuario y escenarios de aceptación

Las prioridades ordenan la implementación; las tres historias forman parte del alcance del
MVP. Los requisitos de cada historia son los de los módulos indicados en «Features
principales».

### Historia 1 - Digitalizar una imagen guardada y exportarla a Word (Prioridad: P1)

Un estudiante tiene en su teléfono la foto de unos apuntes. La selecciona, autoriza su envío
para el reconocimiento, corrige el texto obtenido y guarda un archivo Word con el resultado.

**Por qué esta prioridad**: es el recorrido más corto que entrega el valor central del
producto. Partir de una imagen guardada permite probarlo con muestras fijas, sin depender
de la cámara.

**Prueba independiente**: seleccionar una imagen de muestra sintética, reconocerla, editar
el texto y exportarlo a .docx; abrir el archivo en una aplicación compatible y compararlo con
el texto del editor. Requiere pruebas automatizadas de reconocimiento y exportación, con
casos satisfactorios y de fallo. Módulos: 1 a 6.

**Escenarios de aceptación**:

1. **Dado** un archivo que no puede abrirse como imagen o que incumple los formatos y límites
   acordados (pendientes de definición), **Cuando** el usuario lo selecciona, **Entonces** se
   rechaza indicando el motivo y puede elegir otro.
2. **Dado** una imagen válida seleccionada, **Cuando** se muestra la vista previa,
   **Entonces** el usuario puede aceptarla, reemplazarla o cancelar la selección.
3. **Dado** una imagen aceptada, **Cuando** el usuario inicia el reconocimiento, **Entonces**
   se le informa que el contenido se enviará a un servicio externo y no se envía hasta que
   lo autorice.
4. **Dado** que el usuario rechaza la autorización, **Cuando** responde, **Entonces** el
   contenido no se envía y vuelve a la vista previa.
5. **Dado** un reconocimiento en curso, **Cuando** el usuario pulsa de nuevo la misma acción,
   **Entonces** se sigue mostrando el procesamiento y no se inicia otra operación.
6. **Dado** un reconocimiento que obtuvo texto, **Cuando** termina, **Entonces** el texto
   aparece en el editor con la advertencia de que puede contener errores.
7. **Dado** un reconocimiento que no encontró texto, **Cuando** termina, **Entonces** se
   muestra un aviso y se ofrece elegir otra imagen, sin presentar un documento vacío como
   resultado satisfactorio.
8. **Dado** un reconocimiento que falla por conexión, tiempo de espera o error del servicio,
   **Cuando** termina, **Entonces** el mensaje lo distingue de «no se encontró texto», ofrece
   reintentar y no muestra detalles técnicos.
9. **Dado** un texto con correcciones del usuario, **Cuando** solicita exportar a Word,
   **Entonces** el archivo .docx contiene exactamente el texto del editor, con el mismo orden,
   caracteres y separación de párrafos.
10. **Dado** un editor vacío o con solo espacios, **Cuando** el usuario solicita exportar,
    **Entonces** la exportación se impide y se indica el motivo.
11. **Dado** que ya existe un archivo con el mismo nombre, **Cuando** el usuario guarda,
    **Entonces** el archivo existente no se sobrescribe sin su confirmación.
12. **Dado** un fallo al generar o guardar el archivo, **Cuando** termina la operación,
    **Entonces** se informa el error, no se anuncia éxito y el texto del editor se conserva.
13. **Dado** un texto con correcciones, **Cuando** el usuario elige procesar otra imagen,
    **Entonces** se pide confirmación antes de sustituirlas; si cancela o el nuevo
    reconocimiento falla, las correcciones se conservan.
14. **Dado** cualquier procesamiento terminado, **Cuando** se compara la imagen original del
    usuario con la que tenía antes, **Entonces** no ha sido modificada.
15. **Dado** un texto con cambios no exportados, **Cuando** el sistema cierra la aplicación
    y el usuario la vuelve a abrir, **Entonces** el editor muestra ese texto.
16. **Dado** un texto exportado correctamente y sin cambios posteriores, **Cuando** termina
    la exportación, **Entonces** su borrador se elimina del teléfono.
17. **Dado** un texto en edición, **Cuando** el usuario elige descartarlo, **Entonces** se
    pide confirmación; si confirma, el texto y su borrador se eliminan; si cancela, se
    conservan.

### Historia 2 - Capturar el documento con la cámara (Prioridad: P2)

Una docente fotografía una hoja manuscrita desde la aplicación y continúa con el mismo flujo
de la Historia 1.

**Por qué esta prioridad**: fotografiar el papel es el uso más natural del producto, pero
depende de permisos y del hardware del dispositivo; el resto del flujo ya queda validado por
la Historia 1.

**Prueba independiente**: en un dispositivo con cámara, capturar una hoja y comprobar que
llega a la vista previa; repetir denegando el permiso. Requiere pruebas automatizadas de la
concesión y la denegación del permiso. Módulos: 1 y 5.

**Escenarios de aceptación**:

1. **Dado** que el permiso de cámara no está concedido, **Cuando** el usuario elige tomar una
   fotografía, **Entonces** se le solicita el permiso.
2. **Dado** que el usuario deniega el permiso, **Cuando** responde, **Entonces** se le
   explica por qué es necesario y puede volver al paso anterior.
3. **Dado** una fotografía tomada, **Cuando** se muestra la vista previa, **Entonces** el
   usuario puede aceptarla, repetir la captura o cancelar.
4. **Dado** una fotografía aceptada, **Cuando** el usuario continúa, **Entonces** el flujo
   sigue como en la Historia 1 a partir del escenario 3.
5. **Dado** una fotografía en la que no se encontró texto, **Cuando** termina el
   reconocimiento, **Entonces** se ofrece repetir la captura.

### Historia 3 - Exportar el texto revisado a PDF (Prioridad: P3)

Un profesional necesita sus notas en un formato listo para leer o imprimir y elige PDF en
lugar de Word.

**Por qué esta prioridad**: reutiliza el texto revisado de la Historia 1 y añade un segundo
formato de salida sin cambiar el flujo principal.

**Prueba independiente**: exportar a .pdf un texto de prueba con tildes, ñ, signos ¿ y ¡,
varios párrafos y extensión suficiente para ocupar más de una página; abrirlo en un lector
compatible y compararlo con el texto del editor. Requiere pruebas automatizadas de
exportación satisfactoria y fallida. Módulos: 4 y 5.

**Escenarios de aceptación**:

1. **Dado** un texto revisado, **Cuando** el usuario solicita exportar, **Entonces** puede
   elegir entre Word (.docx) y PDF (.pdf).
2. **Dado** que el usuario elige PDF, **Cuando** la exportación termina, **Entonces** el
   archivo es un PDF real que se abre en un lector compatible y contiene el texto completo,
   sin truncarlo, con el mismo orden, caracteres y separación de párrafos.
3. **Dado** un fallo al generar o guardar el PDF, **Cuando** termina la operación,
   **Entonces** se aplica el mismo comportamiento que en el escenario 12 de la Historia 1.

### Casos límite

- Una respuesta inválida del servicio de reconocimiento se trata como un fallo, no como un
  resultado sin texto.
- Un texto extenso se exporta completo; ni el archivo Word ni el PDF lo truncan.
- Si el permiso de cámara se deniega de forma permanente, se muestra la misma explicación y
  el usuario puede volver al paso anterior.
- La falta de espacio en el dispositivo se trata como un fallo de guardado (Historia 1,
  escenario 12).
- Si el sistema cierra la aplicación durante la edición, el texto se recupera del borrador
  al volver a abrirla (Historia 1, escenario 15).

## Criterios de éxito medibles

Se verifican con muestras sintéticas, públicas o anonimizadas. El plan define los casos de
prueba; aquí no se fijan volúmenes, tiempos ni porcentajes de precisión que no se hayan
acordado.

- **SC-001**: el 100 % de los archivos exportados en las pruebas de aceptación se abren sin
  errores en una aplicación compatible, y su formato real coincide con su extensión.
- **SC-002**: el 100 % de las exportaciones de prueba reproducen el texto del editor sin
  diferencias de orden, caracteres (incluidos tildes, ñ, ¿ y ¡) ni separación de párrafos.
- **SC-003**: en las pruebas de fallo de reconocimiento, generación y guardado, ningún caso
  se anuncia como exitoso y ninguno elimina el texto en edición.
- **SC-004**: ningún contenido sale del dispositivo sin la autorización previa del usuario.
- **SC-005**: ningún registro de diagnóstico contiene imágenes, transcripciones ni
  credenciales, y ningún mensaje al usuario muestra rutas internas, trazas ni credenciales.
- **SC-006**: tras procesar una imagen, el archivo original del usuario es idéntico byte a
  byte al que tenía antes.
- **SC-007**: ninguna exportación se genera a partir de un texto vacío o compuesto solo por
  espacios.
- **SC-008**: pulsar varias veces una acción en curso inicia exactamente una operación.
- **SC-009**: con una imagen de hasta 10 MB, conexión Wi-Fi o 4G y el servicio de
  reconocimiento disponible, la aplicación muestra el texto reconocido o informa el fallo
  en un máximo de 60 segundos.
- **SC-010**: con al menos 10 hojas manuscritas legibles en español, la tasa de error de
  caracteres (CER) global del reconocimiento es del 10 % o menos.
  - *Hojas*: letra clara, buena luz y la hoja completa en la foto.
  - *Medición*: se compara el texto reconocido con la transcripción correcta de cada hoja,
    escrita a mano por una persona. Se usa la herramienta
    `backend/tools/measure_ocr_quality.py` ([research.md](research.md), R15).
  - *Meta*: propuesta el 2026-10-29. La forma de medir queda definida, pero la meta del
    10 % debe aprobarla el responsable del proyecto (CHK012).
- **SC-011**: ningún borrador permanece en el teléfono después de exportar correctamente un
  texto sin cambios posteriores o de descartarlo.

## Supuestos pendientes de validación

Interpretaciones adoptadas para que las historias puedan verificarse. No son decisiones
aprobadas: deben confirmarse con el responsable del proyecto y, si cambian, deben
actualizarse los escenarios afectados.

1. La versión confirmada es el contenido del editor en el momento en que el usuario solicita
   la exportación; no existe un paso de confirmación adicional.
2. Revisar las modificaciones consiste en poder leer el texto completo en el editor antes de
   exportarlo; no requiere una vista comparativa con la transcripción original.
3. Corregir títulos significa editar su texto; los títulos se exportan como párrafos sin
   estilos de encabezado, en coherencia con los Non-Goals.
4. ~~El usuario no recorta ni rota la imagen en esta iteración; si se prepara la imagen para
   el reconocimiento, se hace de forma automática sobre una copia.~~ *(Reemplazado por la
   funcionalidad [003](../003-revision-recorte-compartir/spec.md): la persona puede
   recortar y girar la imagen en el teléfono, siempre sobre una copia.)*
5. El reconocimiento siempre envía la imagen a un servicio externo, por lo que la
   autorización forma parte del flujo principal y se solicita antes de cada envío.
6. El reconocimiento necesita conexión; sin ella se informa al usuario y puede reintentar.
7. La aplicación guarda el archivo en el dispositivo; ~~compartirlo directamente desde la
   aplicación no forma parte de esta iteración.~~ *(Reemplazado por la funcionalidad
   [003](../003-revision-recorte-compartir/spec.md): tras guardarlo se puede compartir.)*
