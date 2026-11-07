## Features principales

HandText AI ayuda a organizar y reutilizar lo digitalizado:
- al guardar, **propone como nombre del archivo el título del documento**;
- **copia todo el texto** con un toque, para pegarlo en otra app;
- en Mis documentos se puede **buscar** y **renombrar**.

Esta funcionalidad amplía 001 a 009. Buscar y renombrar eran Non-Goals de 007 y se
incorporan aquí.

### 1. Nombre del archivo

- **El diálogo para guardar propone el título del documento** (la primera línea con
  texto, o el nombre que se le dio en Mis documentos), por ejemplo «Apuntes de
  biología.docx». La persona lo puede cambiar en ese mismo diálogo, como antes.
- **El nombre propuesto nunca tiene caracteres que Android no acepta** (`/ \ : * ? " < >
  |`) y tiene como máximo 60 caracteres.
- Si no queda un nombre útil, se usa el de siempre: «HandText_20261105_1530.docx».

### 2. Copiar todo el texto

- En el menú del editor, **«Copiar todo el texto»** lo copia tal cual está, sin las marcas
  de palabras dudosas, y un aviso lo confirma.
- No aparece si el texto está vacío.

### 3. Buscar y renombrar en Mis documentos

- Un campo de búsqueda filtra los documentos por título o por texto, **sin importar
  mayúsculas ni tildes** («celula» encuentra «célula»).
- Si nada coincide, un mensaje lo dice.
- «Renombrar» cambia el título de un documento (de 1 a 60 caracteres). **Renombrar no
  cambia el texto ni los archivos ya guardados**, y el nombre se conserva al volver a
  guardar el documento.

## Lo que NO se va a construir en esta iteración (Non-Goals)

- Carpetas, etiquetas u ordenar por otros criterios.
- Renombrar los archivos ya guardados en el teléfono.
- Copiar solo una parte con un botón (para eso está la selección del editor).

## Clarifications

### Session 2026-11-05

- Q: ¿Qué se incorpora ahora? → A: El responsable del proyecto eligió el nombre del
  archivo al guardar, copiar todo el texto, y buscar y renombrar en Mis documentos.

## Historias de usuario y escenarios de aceptación

Las etiquetas del código usan el prefijo `OR` (organizar): `[OR-H1-E2]` es la Historia
1, escenario 2, de esta funcionalidad.

### Historia 1 - Un nombre de archivo útil (Prioridad: P1)

Un estudiante guarda tres documentos y quiere reconocerlos en la carpeta por su nombre.

**Por qué esta prioridad**: «HandText_20261105_1530» no dice qué hay dentro.

**Prueba independiente**: guardar documentos con distintos títulos. Requiere pruebas
automatizadas del nombre y del controlador.

**Escenarios de aceptación**:

1. **Dado** un texto cuya primera línea es «Apuntes de biología», **Cuando** se exporta
   a Word, **Entonces** el diálogo propone «Apuntes de biología.docx».
2. **Dado** un título con caracteres no permitidos («Tema 1: ¿qué es la célula?»),
   **Cuando** se exporta, **Entonces** el nombre propuesto los quita («Tema 1 ¿qué es la
   célula.pdf»).
3. **Dado** un título que queda vacío al limpiarlo, **Cuando** se exporta, **Entonces**
   se propone «HandText_fecha_hora».
4. **Dado** un documento renombrado en Mis documentos, **Cuando** se abre y se exporta,
   **Entonces** se propone ese nombre.

### Historia 2 - Copiar todo el texto (Prioridad: P2)

Una docente quiere pegar la transcripción en un mensaje a sus estudiantes.

**Por qué esta prioridad**: exportar un archivo es demasiado para un mensaje corto.

**Prueba independiente**: copiar y comparar con el editor. Requiere pruebas
automatizadas de pantalla.

**Escenarios de aceptación**:

1. **Dado** el editor con texto, **Cuando** se elige «Copiar todo el texto» en el menú,
   **Entonces** el portapapeles tiene exactamente ese texto y un aviso lo confirma.
2. **Dado** el editor con el texto vacío, **Cuando** se abre el menú, **Entonces** la
   opción no aparece.

### Historia 3 - Buscar y renombrar (Prioridad: P3)

Con 40 documentos guardados, una persona busca los apuntes donde habló de «célula».

**Por qué esta prioridad**: con muchos documentos, la lista sola no alcanza.

**Prueba independiente**: buscar, renombrar y volver a guardar. Requiere pruebas
automatizadas del historial y de la pantalla.

**Escenarios de aceptación**:

1. **Dado** Mis documentos, **Cuando** se escribe en la búsqueda, **Entonces** se ven
   solo los documentos cuyo título o texto contiene lo buscado, sin importar mayúsculas
   ni tildes.
2. **Dado** una búsqueda sin resultados, **Cuando** se muestra, **Entonces** un mensaje
   lo dice.
3. **Dado** un documento, **Cuando** se elige «Renombrar» y se escribe un nombre de 1 a
   60 caracteres, **Entonces** la lista muestra el nuevo nombre; cancelar no cambia
   nada.
4. **Dado** un documento renombrado, **Cuando** se abre, se corrige y se guarda,
   **Entonces** conserva el nombre que se le dio.

### Casos límite

- Un nombre de solo espacios no se acepta al renombrar.
- La búsqueda vacía muestra todos los documentos.

## Criterios de éxito medibles

- **SC-1001**: el 100 % de los nombres propuestos en las pruebas no tiene caracteres no
  permitidos y mide como máximo 60 caracteres más la extensión.
- **SC-1002**: el texto copiado es idéntico al del editor (0 diferencias).
- **SC-1003**: la búsqueda encuentra el documento con o sin tildes y mayúsculas en el
  100 % de los casos de prueba.
- **SC-1004**: renombrar no cambia el texto (0 cambios), y el nombre se conserva al
  volver a guardar.

## Supuestos pendientes de validación

Decisiones adoptadas para poder implementar; deben confirmarse con el responsable del
proyecto.

1. El nombre propuesto es el título del documento, de hasta 60 caracteres.
2. La búsqueda mira el título y el texto completo.
3. Buscar y renombrar se agregan al alcance de 007, que los dejaba fuera: la profesora
   debe aprobarlo.
