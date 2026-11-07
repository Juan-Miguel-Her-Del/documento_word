# Research: Organizar documentos

Decisiones técnicas de la funcionalidad 010. Cada una indica la alternativa descartada.

## R1. Nombre propuesto

**Decisión**: `suggestedFileName` recibe el título del documento:
- el de Mis documentos si se renombró;
- si no, la primera línea con texto (`historyTitleFor`, de 007).

Se quitan `/ \ : * ? " < > |` y los caracteres de control, se juntan los espacios, se
quitan los puntos del final y se corta en 60 caracteres Unicode. Si no queda nada, se usa
el nombre de 001 («HandText_fecha_hora»). El diálogo de Android sigue dejando cambiarlo.

**Alternativa**: preguntar el nombre en un diálogo propio antes del de Android. Serían dos
diálogos seguidos para lo mismo.

## R2. Copiar

**Decisión**: `Clipboard.setData` con el texto del editor, desde el menú del editor, y un
aviso breve (`SnackBar`). Android 13 y posteriores muestran además su propio aviso del
portapapeles. La privacidad lo menciona: lo copiado queda en el portapapeles del teléfono,
donde otras apps pueden leerlo.

## R3. Búsqueda

**Decisión**: filtro en memoria sobre el título y el texto (como máximo 50 documentos,
007). Para comparar, se pasa todo a minúsculas y se quitan las tildes (á→a, ñ→n,
ü→u…) en los dos lados.

**Alternativa**: un índice de búsqueda o SQLite. No hace falta para 50 documentos.

## R4. Renombrar

**Decisión**: `HistoryEntry` suma `renamed` (campo opcional en el JSON). Si es `true`,
volver a guardar conserva el título que se le dio [OR-H3-E4]; si no, el título sigue la
primera línea, como en 007. El diálogo pide de 1 a 60 caracteres sin contar los espacios
de los lados.

## R5. Botones de cada documento

**Decisión**: junto a «Eliminar», un botón «Renombrar» con su propio nombre para TalkBack
(«Renombrar Apuntes de biología»), con las guías de 006 (48 dp).

**Alternativa**: un menú de tres puntos. Agrega un toque y esconde las acciones.
