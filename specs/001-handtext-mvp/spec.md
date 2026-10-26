# Feature Specification: MVP de HandText AI

**Feature Branch**: `01-constitucion` (rama actual del repositorio).

**Feature Directory**: `specs/001-handtext-mvp`

**Created**: 2026-10-19

**Status**: Draft

**Input**: Ejecutar `/speckit.specify` sobre el MVP descrito en la propuesta HandText AI
y en la conversación: fotografiar o seleccionar una imagen manuscrita, reconocer su texto,
revisarlo y editarlo, y exportarlo en Word y PDF. Aplicar la constitución vigente 2.0.0.

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Convertir una imagen existente en un documento editable (Priority: P1)

Como estudiante, docente o profesional, quiero seleccionar una imagen de mis apuntes,
obtener su transcripción, corregirla y guardarla como Word para reutilizarla sin tener
que transcribir todo manualmente.

**Why this priority**: Resuelve de principio a fin el problema central y proporciona
una entrega útil aun antes de incorporar la cámara o la segunda opción de exportación.

**Independent Test**: Seleccionar una imagen válida desde el dispositivo, autorizar su
procesamiento, reconocerla, cambiar una palabra y guardar un archivo `.docx` que abra
correctamente y contenga la corrección. No requiere cámara, cuentas ni historial.

**Acceptance Scenarios**:

1. **US1-A1 — Given** una imagen JPEG o PNG legible de una página manuscrita,
   **When** el usuario la selecciona, **Then** puede previsualizarla sin modificar
   el archivo original y decidir si inicia el reconocimiento.
2. **US1-A2 — Given** una imagen válida y el aviso de tratamiento de datos,
   **When** el usuario autoriza e inicia el reconocimiento, **Then** ve el estado de
   procesamiento y después el texto editable, junto con una advertencia de posibles errores.
3. **US1-A3 — Given** el texto reconocido, **When** el usuario agrega o elimina palabras,
   corrige tildes y separa párrafos, **Then** el editor conserva exactamente esos cambios
   mientras continúa la sesión.
4. **US1-A4 — Given** texto no vacío revisado por el usuario, **When** confirma la
   exportación a Word y elige dónde guardarlo, **Then** obtiene un archivo `.docx`
   válido con la última versión confirmada, incluidas sus tildes y párrafos.
5. **US1-A5 — Given** texto corregido, **When** el usuario solicita repetir el
   reconocimiento, **Then** se le advierte antes de sustituirlo; cancelar conserva
   las correcciones y confirmar permite reemplazarlas solo al recibir un nuevo resultado
   válido. Si el reconocimiento falla, se conserva el texto anterior.
6. **US1-A6 — Given** una imagen seleccionada, **When** el usuario rechaza el tratamiento
   externo, **Then** no se envía su contenido y puede volver o elegir otra imagen.

---

### User Story 2 - Digitalizar directamente desde la cámara (Priority: P2)

Como persona que conserva un documento físico, quiero fotografiarlo dentro de la aplicación
y utilizar esa imagen en el mismo flujo de reconocimiento, corrección y exportación.

**Why this priority**: Permite digitalizar documentos que aún no están fotografiados
sin exigir que el usuario salga de la aplicación para capturarlos.

**Independent Test**: Con un documento físico, conceder acceso a la cámara, tomar una
fotografía, aceptarla y completar su edición y exportación a Word. La adquisición por
cámara puede comprobarse por separado de la selección desde la galería.

**Acceptance Scenarios**:

1. **US2-A1 — Given** acceso permitido a la cámara, **When** el usuario toma una fotografía,
   **Then** ve una previsualización y puede aceptarla o repetirla antes de enviarla.
2. **US2-A2 — Given** una fotografía aceptada y válida, **When** inicia el reconocimiento,
   **Then** accede al mismo flujo de revisión y exportación de la historia 1.
3. **US2-A3 — Given** permiso de cámara denegado, **When** intenta fotografiar,
   **Then** recibe una explicación y puede elegir una imagen existente; la aplicación
   no queda bloqueada ni repite automáticamente la solicitud de permiso.
4. **US2-A4 — Given** una captura o selección abierta, **When** el usuario la cancela,
   **Then** regresa al paso anterior sin enviar una imagen ni borrar un trabajo existente.

---

### User Story 3 - Guardar el resultado como PDF (Priority: P2)

Como usuario que terminó de revisar un documento, quiero guardarlo también como PDF
para consultarlo o entregarlo con una presentación estable.

**Why this priority**: Completa las dos salidas previstas en el MVP y evita exigir
otra aplicación para producir el PDF.

**Independent Test**: Con texto revisado en el editor, exportar a PDF y abrir el archivo
en un lector compatible para comprobar palabras, tildes, párrafos y orden del contenido.
No requiere comprobar la cámara ni generar Word en esa misma prueba.

**Acceptance Scenarios**:

1. **US3-A1 — Given** texto confirmado y no vacío, **When** el usuario elige PDF,
   **Then** obtiene un archivo `.pdf` válido con la última versión del texto.
2. **US3-A2 — Given** un documento exportado en un formato, **When** exporta también
   en el otro sin cambiar el editor, **Then** ambos mantienen el mismo contenido,
   aunque su distribución de líneas o páginas pueda diferir.
3. **US3-A3 — Given** un texto más largo que una página de salida, **When** lo exporta,
   **Then** el archivo continúa en las páginas necesarias sin truncar su contenido.
   Esta paginación de salida no añade captura ni reconocimiento de múltiples imágenes.
4. **US3-A4 — Given** un fallo al generar o guardar un archivo, **When** ocurre el error,
   **Then** se informa que la exportación no terminó y se conserva el texto para reintentar.

---

### Edge Cases

- **EC-001 — Archivo no admitido:** una extensión engañosa, contenido corrupto, formato
  distinto de JPEG/PNG, más de 10 MiB o más de 20 millones de píxeles se rechaza antes
  de enviarlo a reconocimiento, con el motivo y la opción de seleccionar otra imagen.
  Los valores exactamente iguales a ambos límites están permitidos si el archivo es válido.
- **EC-002 — Sin texto reconocible:** una hoja vacía o una fotografía ilegible que no
  produce texto muestra un aviso distinto de un fallo del servicio y permite repetir
  la captura. No genera automáticamente un documento vacío.
- **EC-003 — Conectividad:** sin conexión o con una interrupción, se conserva el trabajo
  de la sesión y se permite reintentar por acción del usuario. Si el reconocimiento
  no termina en 60 segundos, se informa el vencimiento de la espera.
- **EC-004 — Texto vacío:** borrar todo el contenido o dejar solo espacios impide
  la exportación en ambos formatos y explica cómo continuar.
- **EC-005 — Acciones repetidas:** pulsar varias veces reconocer o exportar no crea
  operaciones simultáneas duplicadas. Una respuesta tardía de una operación abandonada
  no reemplaza la imagen ni el texto del documento actual.
- **EC-006 — Cambio de documento:** seleccionar otra imagen, repetir el reconocimiento
  o abandonar deliberadamente un documento con correcciones requiere confirmación;
  cancelar mantiene el trabajo. El cierre forzado por el dispositivo no garantiza recuperación.
- **EC-007 — Destino de salida:** cancelar la elección del destino no se anuncia como
  exportación exitosa. Un nombre o destino ya existente no debe sobrescribirse sin
  confirmación o sin ofrecer un nombre alternativo.
- **EC-008 — Privacidad y aislamiento:** otra sesión no puede consultar ni descargar
  imágenes, textos o archivos temporales, aunque conozca su identificador.
- **EC-009 — Retención:** los temporales controlados por HandText AI se eliminan al cerrar
  o completar su operación; ante interrupciones, en un máximo de 15 minutos desde su
  creación. El contenido de una operación se conserva solo lo necesario durante su curso.
  Los archivos guardados por el usuario permanecen bajo su control.
- **EC-010 — Alcance manuscrito:** tablas, diagramas, varios documentos en una sola imagen
  y escritura en otros idiomas no tienen garantía de transcripción estructurada en el MVP.
  La aplicación no debe presentarlos como una reproducción fiel del diseño original.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: El sistema DEBE permitir iniciar un documento sin registro ni inicio de
  sesión, seleccionando una sola imagen existente o tomando una fotografía.
- **FR-002**: El sistema DEBE mostrar la imagen antes del reconocimiento y permitir
  aceptarla, cambiarla o cancelar. DEBE gestionar la denegación de permisos sin bloquear
  la alternativa de selección de archivos.
- **FR-003**: El sistema DEBE aceptar imágenes JPEG y PNG válidas de hasta 10 MiB
  (10 485 760 bytes) y hasta 20 000 000 de píxeles, ambos límites inclusivos.
  DEBE comprobar el contenido y rechazar entradas inválidas antes del reconocimiento.
- **FR-004**: El sistema DEBE conservar el archivo original. Cualquier preparación para
  reconocimiento DEBE realizarse sobre una copia y no eliminar contenido del documento.
- **FR-005**: Antes de enviar contenido a un servicio externo, el sistema DEBE informar
  qué proveedor lo procesará, la finalidad y su política de retención, y obtener la
  autorización del usuario para ese documento. Rechazarla DEBE impedir el envío.
- **FR-006**: El sistema DEBE reconocer escritura manuscrita legible en español y devolver
  una transcripción editable; DEBE advertir de posibles errores y no inventar fragmentos
  ilegibles, resumir, traducir ni mejorar la redacción automáticamente.
- **FR-007**: El editor DEBE permitir agregar, eliminar y corregir texto y separar párrafos,
  incluidas tildes y la letra ñ. DEBE conservar las modificaciones durante la sesión,
  también cuando falle una solicitud de reconocimiento o exportación.
- **FR-008**: El sistema DEBE solicitar confirmación antes de sustituir texto corregido
  mediante un nuevo reconocimiento, cambiar de imagen o abandonar deliberadamente el
  trabajo. Cancelar DEBE conservarlo y confirmar DEBE aplicar solo la acción solicitada.
  En un nuevo reconocimiento, el reemplazo solo ocurre al obtener un resultado válido;
  si falla, las correcciones anteriores permanecen disponibles.
- **FR-009**: El sistema DEBE permitir exportar la versión actual confirmada a un archivo
  Word `.docx` válido y editable en aplicaciones compatibles.
- **FR-010**: El sistema DEBE permitir exportar la versión actual confirmada a un archivo
  PDF `.pdf` válido y legible en lectores compatibles.
- **FR-011**: Ambas exportaciones DEBEN rechazar texto vacío o formado solo por espacios
  y conservar palabras, tildes, orden y separaciones de párrafos. El texto que no quepa
  en una página DEBE continuar sin truncarse. No se exige conservar el diseño manuscrito.
- **FR-012**: El sistema DEBE permitir elegir el destino y nombre del archivo generado,
  mantener la extensión correspondiente y comunicar éxito solo después de guardarlo.
  NO DEBE sobrescribir archivos existentes sin confirmación o sin proponer otro nombre.
- **FR-013**: El sistema DEBE distinguir visualmente espera, procesamiento, éxito y fallo,
  y evitar operaciones simultáneas duplicadas sobre el documento actual.
- **FR-014**: El sistema DEBE distinguir falta de conexión, vencimiento de la espera,
  fallo del reconocimiento, resultado sin texto y fallo al guardar. DEBE ofrecer una
  acción útil en cada caso y conservar el trabajo para reintentar durante la sesión.
- **FR-015**: El reconocimiento DEBE dejar de mostrarse como pendiente al cumplirse
  60 segundos sin resultado. Las respuestas tardías NO DEBEN sobrescribir un trabajo
  sustituido ni anunciar éxito después de que la operación haya sido abandonada.
- **FR-016**: La interfaz y los mensajes DEBEN estar en español. Los errores públicos
  NO DEBEN revelar trazas, rutas internas, credenciales ni respuestas técnicas crudas.
- **FR-017**: Los documentos y temporales DEBEN estar aislados por sesión y ser privados.
  Conocer un identificador NO DEBE permitir acceder al contenido de otra sesión.
- **FR-018**: El sistema NO DEBE conservar cuentas, historial ni copias permanentes de
  los documentos en esta entrega. Los temporales controlados por HandText AI DEBEN
  eliminarse al terminar su operación o, si esta se interrumpe, antes de 15 minutos
  desde su creación. Los registros NO DEBEN contener imágenes, transcripciones ni secretos.
- **FR-019**: La configuración del reconocimiento DEBE impedir el uso de documentos para
  entrenar modelos y el archivo permanente por el proveedor. Su política efectiva de
  tratamiento DEBE verificarse y mostrarse antes de autorizar el envío; la integración
  NO DEBE habilitarse si incumple estas restricciones.
- **FR-020**: El sistema DEBE limitar esta entrega al procesamiento de una imagen por
  documento, reconocimiento, edición y guardado local en Word y PDF. NO DEBE incorporar
  cuentas, historial persistente, traducción, resúmenes, corrección automática, búsqueda,
  lectura en voz alta, organización automática ni procesamiento de múltiples imágenes.

### Verification Requirements

- **VR-001**: La entrega DEBE incluir pruebas automatizadas del reconocimiento, edición
  y exportación afectados, con resultados satisfactorios, entradas inválidas, errores,
  respuestas tardías y preservación del trabajo. Las pruebas de reconocimiento DEBEN
  distinguir la verificación del flujo de la evaluación de calidad con imágenes reales.
- **VR-002**: La entrega DEBE comprobar de forma automatizada el aislamiento entre sesiones,
  la eliminación de temporales, el rechazo de contenido vacío y la correspondencia entre
  texto confirmado y contenido exportado. Los registros DEBEN revisarse para descartar
  contenido privado.
- **VR-003**: Las imágenes de prueba DEBEN ser sintéticas, públicas o anonimizadas.
  Las evaluaciones con personas DEBEN usar documentos de prueba sin información privada.
  Los resultados DEBEN documentar el conjunto evaluado, condiciones, medidas y limitaciones.

### Key Entities *(include if feature involves data)*

- **Documento de trabajo:** una imagen de una página, su transcripción inicial, la versión
  editada actual, la confirmación de esa versión y el estado de la operación; existe
  durante la sesión y no constituye un registro permanente de historial.
- **Imagen original:** contenido capturado o seleccionado, origen, formato, dimensiones
  y tamaño. Es la referencia de reconocimiento y no debe sobrescribirse.
- **Operación de reconocimiento:** documento asociado, autorización de tratamiento,
  estado, inicio y resultado o motivo de fallo; permite distinguir respuestas vigentes
  de respuestas tardías.
- **Archivo exportado:** documento y versión de texto de origen, formato, nombre,
  resultado del guardado y destino elegido por el usuario.
- **Sesión de trabajo:** contexto temporal de un usuario sin cuenta que delimita el acceso
  a sus operaciones; no representa un perfil ni un historial entre aperturas.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001 — Utilidad:** al menos 4 de 5 personas que usan la aplicación por primera vez
  completan, sin ayuda del evaluador y en un máximo de 5 minutos, la selección o captura,
  revisión, corrección de una palabra y guardado de un documento de 50 a 150 palabras.
  La prueba DEBE repartir participantes entre ambas entradas y ambos formatos de salida.
- **SC-002 — Tiempo de reconocimiento:** en al menos 18 de las 20 imágenes del corpus
  de referencia, el texto aparece en el editor en un máximo de 30 segundos desde que
  el usuario inicia el reconocimiento, en las condiciones de referencia indicadas abajo.
- **SC-003 — Calidad de transcripción:** antes de correcciones humanas, la media de la
  tasa de error por palabra de las 20 imágenes de referencia es como máximo del 20 %.
  Por imagen, la tasa es (sustituciones + eliminaciones + inserciones) / palabras de la
  transcripción correcta. Para compararlas se ignoran mayúsculas, puntuación y espacios
  repetidos, pero se conservan tildes y ñ. Las transcripciones de referencia se fijan
  antes de evaluar el servicio.
- **SC-004 — Integridad de salida:** 20 textos de prueba con tildes, ñ, párrafos y al menos
  un caso que exceda una página generan 40 archivos —uno por formato y texto— que abren
  correctamente y conservan el 100 % de las palabras en su orden y las separaciones de
  párrafos, ignorando los saltos de línea producidos únicamente por el ajuste de página.
- **SC-005 — Recuperación:** el 100 % de los casos aplicables EC-001 a EC-007 rechaza o
  comunica la situación correspondiente sin anunciar éxito falso, sobrescribir originales
  ni perder correcciones durante una sesión que permanece abierta, salvo sustitución
  o descarte confirmado expresamente por el usuario.
- **SC-006 — Privacidad:** las pruebas entre dos sesiones rechazan todos los intentos
  de acceso cruzado; después del plazo de 15 minutos no quedan temporales vencidos
  controlados por HandText AI. Una revisión de los registros de esas pruebas no encuentra
  contenido de documentos ni credenciales. La política del proveedor cumple FR-019.

## Assumptions

- **Alcance acordado:** se toma el MVP de la propuesta y el alcance descrito en la
  conversación como entrada del comando sin argumentos adicionales. La especificación
  permanece en borrador hasta su revisión; no autoriza implementar funciones futuras.
- **Plataforma e idioma:** la primera entrega se evalúa en Android y con manuscritos
  en español. La adaptación a iOS y la detección automática de otros idiomas quedan fuera.
- **Valores iniciales derivados:** JPEG/PNG, 10 MiB, 20 millones de píxeles, los plazos
  de 30/60 segundos, los 15 minutos de retención y los objetivos de calidad y usabilidad
  son decisiones iniciales para hacer verificable la propuesta, que no fijaba cifras.
  Pueden revisarse explícitamente antes de aprobar el plan; no son resultados ya medidos.
- **Corpus de referencia:** 20 imágenes de una página con 50 a 150 palabras legibles
  en español por imagen, con al menos cinco estilos de escritura, iluminación uniforme
  y sin texto cortado. Se fija el conjunto y su transcripción correcta antes de seleccionar
  el servicio de reconocimiento, para evitar evaluaciones sobre ejemplos elegidos a posteriori.
- **Entorno de evaluación:** dispositivo Android con cámara, al menos 4 GB de memoria
  y conexión estable con 10 Mbps o más de subida y bajada. Las medidas de tiempo incluyen
  el envío de la imagen y la recepción del resultado; se excluyen caídas de conectividad.
- **Dependencia de reconocimiento:** el proveedor aún no está seleccionado; su elección
  corresponde al plan y DEBE demostrar SC-002, SC-003 y FR-019 antes de habilitar su uso.
  La especificación no presupone que un servicio concreto ya soporte escritura manuscrita.
- **Sesión y archivos:** no se garantiza recuperar un documento sin guardar después de
  cerrar forzadamente la aplicación. Los archivos exportados se guardan donde el usuario
  elija y no están sujetos a la eliminación de temporales de HandText AI.
- **Tratamiento externo:** cada documento requiere autorización antes de transmitirse.
  El plazo de 15 minutos se aplica a temporales controlados por HandText AI; la retención
  transitoria del proveedor debe declararse y verificarse según FR-019 antes del uso.
  Esta entrega no habilita el uso sin conexión.
