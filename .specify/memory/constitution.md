# Constitución del Proyecto: HandText AI

## 1. Naturaleza del Proyecto

HandText AI — Digitalización inteligente de documentos escritos a mano es una aplicación
móvil dirigida a estudiantes, docentes, profesionales, empresas y personas que necesitan
conservar o utilizar información manuscrita en formato digital. Su propósito central es
reducir el trabajo de transcripción manual mediante reconocimiento de escritura con IA,
revisión humana y generación de documentos digitales editables o listos para compartir.

El desarrollo inicial DEBE centrarse en Android; la adaptación a iOS corresponde a una
etapa posterior. El MVP DEBE limitarse al flujo de captura o selección de una imagen,
reconocimiento manuscrito, revisión y edición del texto y exportación a Word o PDF.
Los detalles y criterios de aceptación de cada entrega DEBEN definirse en `spec.md`.

El procesamiento de múltiples páginas, la conservación del diseño original, la traducción,
los resúmenes y las demás ampliaciones propuestas NO DEBEN incorporarse al MVP sin una
especificación aprobada. La autenticación, el historial y el almacenamiento en la nube
NO DEBEN considerarse requisitos implícitos del MVP.

## 2. Stack Tecnológico (Reglas de Implementación)

- **Frontend / UI:** Flutter, con Dart, widgets y temas centralizados de Flutter para la
  presentación. La lógica de OCR, persistencia y exportación DEBE estar separada de los
  widgets. No se incorporará otro framework de interfaz sin modificar esta constitución.
- **Backend:** Python con FastAPI, comunicado con la aplicación mediante una API REST.
  La integración de IA y los secretos de los proveedores DEBEN permanecer en el backend.
  La generación de archivos DEBE organizarse como un servicio independiente de las rutas.
- **Base de Datos:** PostgreSQL para la persistencia relacional de usuarios, metadatos,
  textos e historial cuando esas funciones estén aprobadas. Los archivos binarios DEBEN
  almacenarse en una ubicación privada definida en el plan, con referencias en la base de
  datos. Todo acceso DEBE pasar por una capa de persistencia y utilizar consultas
  parametrizadas o un ORM justificado en el plan. Firebase no se adopta en esta base.
- **Lenguaje:** Dart para la aplicación móvil; Python para la API, procesamiento e
  integraciones; SQL para esquemas, consultas y migraciones de PostgreSQL.
- **IA / OCR:** se utilizará inicialmente un servicio existente, encapsulado mediante un
  adaptador del backend. El proveedor DEBE seleccionarse en el plan con evidencia de
  reconocimiento de escritura manuscrita, evaluación de privacidad, costo y límites.
  La lista de alternativas de la propuesta no autoriza automáticamente ningún proveedor.
  El entrenamiento de un modelo propio requiere una especificación posterior.
- **Dependencias:** las versiones utilizadas DEBEN registrarse en los manifiestos y
  archivos de bloqueo aplicables. Cada incorporación DEBE tener una necesidad trazable
  en el plan; las credenciales DEBEN suministrarse mediante configuración externa.

## 3. Reglas de Dominio y Lógica de Negocio

Estas reglas son obligatorias para todas las funcionalidades a las que apliquen:

- **Conservación del original:** el procesamiento DEBE trabajar sobre una copia de la
  imagen. NO DEBE sobrescribir el original salvo solicitud explícita del usuario.
  Las operaciones destructivas DEBEN exigir confirmación o disponer de recuperación
  documentada y verificada.
- **Fidelidad del reconocimiento:** el OCR DEBE transcribir el contenido identificado.
  NO DEBE inventar fragmentos ilegibles ni aplicar resúmenes, traducciones o mejoras de
  redacción por iniciativa propia. La aplicación DEBE advertir que el resultado puede
  contener errores y permitir su revisión antes de exportarlo.
- **Autoridad del texto editado:** la exportación DEBE utilizar la última versión del texto
  confirmada por el usuario. Un nuevo resultado de OCR NO DEBE reemplazar correcciones
  existentes sin confirmación. No se garantiza la reproducción del diseño manuscrito.
- **Integridad antes de guardar o exportar:** la entrada DEBE validarse antes de procesarse.
  La exportación DEBE rechazar texto vacío o compuesto solo por espacios. Un fallo parcial
  NO DEBE marcarse como éxito ni eliminar el texto editado. Los límites de tamaño y formatos
  de imagen DEBEN establecerse en la especificación antes de implementar la carga.
- **Formatos de salida:** las salidas autorizadas son Microsoft Word `.docx` y PDF `.pdf`.
  Cada entrega DEBE declarar qué formatos soporta. El contenido, la extensión y el tipo
  de archivo DEBEN coincidir; renombrar una extensión no constituye una conversión.
- **Privacidad:** las imágenes, textos y documentos generados DEBEN ser privados por
  defecto. El envío a un proveedor externo DEBE declararse y contar con autorización
  del usuario en el flujo correspondiente. Los registros y datos de prueba NO DEBEN
  contener documentos privados, contraseñas ni credenciales.
- **Acceso:** si se incorporan cuentas e historial persistente, el backend DEBE autenticar
  las operaciones sobre documentos privados y verificar su pertenencia al usuario en
  cada solicitud. Conocer el identificador de un documento no autoriza su acceso.
  Una sesión sin cuenta NO DEBE exponer documentos de otros usuarios.
- **Retención y consistencia:** antes de implementar persistencia o archivos temporales,
  el plan DEBE definir ubicación, permisos, retención y eliminación. Los metadatos y las
  referencias a archivos DEBEN mantenerse consistentes; el historial NO DEBE presentar
  como disponible una exportación que falló.

## 4. Estructura y Estilo de Código

- **Estructura:** `/frontend` contendrá la aplicación Flutter; `/backend`, la API y los
  servicios Python; `/db`, los esquemas y migraciones; `/specs`, las especificaciones,
  planes y tareas; `.specify/memory/constitution.md` será la constitución vigente.
  Las pruebas se ubicarán en `/frontend/test` y `/backend/tests` cuando correspondan.
  Estas carpetas se crearán al necesitarlas, sin generar módulos vacíos anticipadamente.
- **Organización:** Flutter DEBE separar presentación, modelos y servicios. FastAPI DEBE
  separar rutas, validación de datos, servicios y acceso a datos. Las integraciones OCR
  y la generación documental DEBEN poder verificarse sin ejecutar la interfaz móvil.
- **Estilo:** se usarán funciones y componentes con una responsabilidad identificable,
  composición antes que jerarquías innecesarias y la solución de menor complejidad que
  cumpla la especificación. No se introducirán microservicios ni capas adicionales sin
  justificación en el plan. El código DEBE pasar el formateador y analizador configurados.
- **Nomenclatura Dart:** `lowerCamelCase` para variables, funciones y métodos;
  `UpperCamelCase` para clases, tipos y widgets; `snake_case.dart` para archivos.
- **Nomenclatura Python y SQL:** `snake_case` para funciones, variables, archivos Python,
  tablas y columnas; `PascalCase` para clases y esquemas de datos Python;
  `UPPER_SNAKE_CASE` para constantes Python. Los identificadores de código DEBEN estar
  en inglés y los mensajes iniciales de interfaz en español.

## 5. Manejo de Errores y Validaciones

- **UI:** los mensajes DEBEN explicar qué ocurrió y qué puede hacer el usuario, por
  ejemplo repetir la fotografía o reintentar la operación. La interfaz DEBE distinguir
  procesamiento, éxito y fallo, conservar las correcciones ante errores y evitar envíos
  duplicados mientras una operación esté en curso. NO DEBE mostrar trazas, consultas SQL,
  rutas internas, credenciales ni respuestas técnicas crudas del proveedor OCR.
- **Validación:** la UI DEBE orientar al usuario, pero el backend DEBE validar de nuevo
  cada entrada. Las imágenes DEBEN comprobarse por su contenido y decodificación, además
  de su tamaño y formato; no basta con su extensión. El texto, los identificadores y el
  formato de exportación DEBEN validarse antes de guardar o generar archivos.
- **Backend:** los errores DEBEN seguir una estructura consistente con código estable,
  mensaje comprensible e identificador de solicitud. Se utilizarán `400` para solicitudes
  mal formadas, `401` para autenticación ausente o inválida, `403` para acciones prohibidas,
  `404` para recursos no disponibles al solicitante, `409` para conflictos de estado,
  `413` para cargas excesivas y `415` para tipos no admitidos. Los errores de validación
  de esquema devolverán `422`. Los fallos internos y de dependencias utilizarán códigos
  `5xx` adecuados y mensajes públicos sin detalles sensibles.
- **OCR e integraciones:** los tiempos de espera, respuestas inválidas y fallos del
  proveedor DEBEN distinguirse de un reconocimiento sin texto. Un resultado vacío NO
  DEBE convertirse en un archivo anunciado como exitoso. Los diagnósticos DEBEN permitir
  localizar la operación fallida sin registrar el contenido del documento.

## 6. Comportamiento del Agente de IA (Reglas SDD)

- **Cero Código Sombra (Shadow Code):** el agente DEBE implementar únicamente lo definido
  en las especificaciones aprobadas (`spec.md`). NO DEBE añadir funcionalidades,
  dependencias ni complejidad «por si acaso». La propuesta orienta el producto; no convierte
  todas sus ideas en tareas autorizadas de la primera entrega.
- **Fuente de la Verdad:** si una solicitud contradice esta constitución o una especificación
  resulta inconsistente, el agente DEBE detener la implementación afectada, explicar el
  conflicto y solicitar la actualización del documento correspondiente antes de modificar
  ese código. Los cambios de reglas DEBEN actualizar primero esta constitución.
- **Trazabilidad:** cada funcionalidad DEBE tener escenarios de aceptación y resultados
  medibles. El plan DEBE justificar las decisiones técnicas y comprobar esta constitución
  antes de la investigación y después del diseño. Las tareas DEBEN vincularse con los
  requisitos y registrar las dependencias necesarias.
- **Verificación:** los cambios en OCR, exportación, persistencia, permisos o integraciones
  DEBEN incluir pruebas automatizadas de casos satisfactorios y fallos relevantes,
  indicadas en las especificaciones y tareas. Las correcciones en esas áreas DEBEN añadir
  una prueba de regresión. Los cambios de texto sin impacto funcional requieren revisión
  documentada. Las muestras DEBEN ser sintéticas, públicas o anonimizadas.
- **Entrega:** el agente DEBE registrar las verificaciones ejecutadas, sus resultados y
  limitaciones. NO DEBE declarar terminada una entrega con fallos que impidan sus criterios
  de aceptación. Los cambios de comportamiento público DEBEN actualizar su documentación.
  Los objetivos de rendimiento DEBEN indicar medida, volumen y entorno de referencia.

### Gobierno y cambios de la constitución

Esta constitución prevalece sobre ejemplos de plantillas y convenciones del proyecto.
Cada revisión DEBE verificar las reglas aplicables; registrar un incumplimiento como deuda
no concede una excepción. Las enmiendas DEBEN explicar motivo, impacto, reglas afectadas
y acciones de migración, y contar con la aprobación del responsable del proyecto.

Después de una enmienda DEBEN revisarse las especificaciones y planes afectados antes de
continuar la implementación. Los cambios incompatibles de contratos o datos DEBEN incluir
un procedimiento de migración y recuperación cuando afecten información existente.

La versión sigue `MAJOR.MINOR.PATCH`: MAJOR para eliminar o redefinir reglas de forma
incompatible, MINOR para ampliar obligaciones y PATCH para aclaraciones sin alterar reglas.
La fecha de ratificación original se conserva; la de enmienda se actualiza al cambiar la
constitución. Los informes temporales de sincronización DEBEN retirarse antes del commit.

**Versión**: 2.0.0 | **Ratificada**: 2026-10-19 | **Última enmienda**: 2026-10-19
