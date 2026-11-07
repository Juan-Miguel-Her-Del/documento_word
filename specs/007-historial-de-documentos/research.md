# Research: Historial de documentos

Decisiones técnicas de la funcionalidad 007. Cada una indica la alternativa descartada.

## R1. Dónde se guarda

**Decisión**: un archivo JSON por cuenta, `history_<id>.json`, en la carpeta privada de
soporte de la app, junto al borrador. El id se limpia igual que el del borrador (solo
letras, números y guiones), así nunca forma otra ruta. La app no permite copias de
seguridad (`allowBackup="false"`, spec 001), así que el historial no sale del teléfono.

**Alternativas**:
- Tablas en PostgreSQL con endpoints nuevos. Rompe la promesa de privacidad de 001 a 005
  («el texto no se guarda en el servidor») y obliga a cambiar la API, la eliminación de
  la cuenta y la política de privacidad. Queda para una futura sincronización.
- SQLite en el teléfono (`sqflite`). Agrega una dependencia nativa para, como máximo,
  50 documentos; un JSON alcanza.

## R2. Formato y escritura

**Decisión**:
`{"version": 1, "entries": [{"id", "title", "text", "formats": ["docx"], "savedAt"}]}`.
Escritura atómica (temporal y luego renombrar), como el borrador y los ajustes. Un
archivo dañado o con otra versión se lee como historial vacío; el siguiente guardado lo
reemplaza.

## R3. Identidad de un documento

**Decisión**: el primer guardado de un documento le asigna un id (fecha en microsegundos
y un número aleatorio). El controlador lo recuerda mientras se edita el mismo documento y
lo olvida cuando empieza uno nuevo (un reconocimiento correcto, descartar o cerrar
sesión). El borrador guarda ese id (campo opcional `historyId`), así un borrador
recuperado sigue unido a su entrada [HD-H2-E4]. Los borradores anteriores, sin el campo,
se siguen leyendo.

**Alternativa**: comparar el texto para reconocer el mismo documento. Falla en cuanto se
corrige una palabra, que es justamente el caso de HD-H1-E2.

## R4. Cuándo se registra

**Decisión**: solo cuando el guardado termina bien (`SaveCompleted`), con el texto que se
exportó y la hora del guardado. Si escribir el historial falla, se anota el tipo de
error (nunca el contenido) y el guardado se informa igual como correcto.

## R5. Orden, límite y título

**Decisión**:
- el documento guardado pasa al principio de la lista;
- al pasar de 50, sale el último (el más antiguo);
- el título es la primera línea con texto, sin espacios a los lados, hasta 60
  caracteres (se cuenta por caracteres Unicode, no por unidades UTF-16) y con «…» si se
  corta.

## R6. Fechas en español

**Decisión**: un formateador propio en `strings.dart`: «29 oct 2026, 15:30».

**Alternativa**: el paquete `intl`. Una dependencia para un solo formato de fecha.

## R7. Abrir un documento

**Decisión**: el controlador carga el texto, sin marcas de palabras dudosas (ya se
revisó), como documento sin cambios por exportar, y pasa al editor. Si había cambios sin
exportar, la pantalla pide confirmación antes [HD-H2-E2]. Las copias de imágenes que
quedaran se borran, como al empezar cualquier documento.

## R8. Borrar

**Decisión**:
- «Eliminar» y «Borrar todo» piden confirmación (constitución §3) y solo cambian el JSON.
- Al eliminar la cuenta, `clearLocalData(deleteHistory: true)` también borra el archivo.
- Cerrar sesión no lo borra.

## R9. Pantalla

**Decisión**: una pantalla Aurora, «Mis documentos», con una tarjeta por documento:
- título;
- fecha, formatos y palabras;
- un botón «Eliminar» con nombre propio para TalkBack («Eliminar Apuntes de biología»).

Tocar la tarjeta abre el documento. «Borrar todo» va en el encabezado. Sin documentos, un
mensaje explica cómo aparecen. Cumple las guías de accesibilidad de 006 (nombres, 48 dp,
letra al 200 %).
