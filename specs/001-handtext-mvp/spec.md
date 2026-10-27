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
- **Pendiente de definición:** formatos de imagen admitidos, tamaño máximo y límites de
  dimensiones. Estos valores deben acordarse antes de implementar la carga de imágenes.

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
- **Pendiente de definición:** idiomas de escritura admitidos, calidad mínima aceptable
  del reconocimiento y tiempo máximo de espera antes de informar que no se obtuvo resultado.

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

- Permitir utilizar el flujo del MVP sin crear una cuenta ni iniciar sesión.
- **Mantener la privacidad de las imágenes, los textos y los documentos generados. Un usuario
  no debe poder acceder a documentos de otro usuario.**
- **Antes de enviar el contenido a un servicio externo, informar al usuario de ese
  tratamiento y obtener su autorización. Sin autorización, no se debe enviar el contenido.**
- **No incluir documentos privados, transcripciones ni credenciales en los registros
  de diagnóstico.**
- **Pendiente de definición:** condiciones y plazos de conservación y eliminación de
  imágenes, textos y archivos temporales utilizados durante el procesamiento. Deben quedar
  definidos antes de implementar su almacenamiento o tratamiento temporal.

## Lo que NO se va a construir en esta iteración (Non-Goals)

- Registro de usuarios, inicio de sesión con correo o Google y administración de perfiles.
- Historial persistente de documentos y almacenamiento de una biblioteca en la nube.
- Captura o reconocimiento de múltiples páginas o imágenes dentro de un mismo documento.
- Reconocimiento estructurado de tablas, diagramas o formularios con campos identificados.
- Reproducción exacta del diseño, la tipografía y la distribución del documento original.
- Detección automática del idioma y traducción de documentos.
- Resúmenes, mejoras de redacción, corrección ortográfica automática o transformación
  de apuntes en informes mediante IA.
- Búsqueda de palabras en un historial, categorías y organización automática de documentos.
- Lectura del texto mediante voz.
- Edición avanzada con estilos, plantillas o herramientas de maquetación.
- Versión para iOS o una versión web de la aplicación.
