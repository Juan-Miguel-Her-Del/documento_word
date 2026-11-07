## Features principales

HandText AI agrega un **escáner de documentos**:
- detecta los bordes de la hoja, la endereza y permite elegir un filtro (por ejemplo,
  blanco y negro) antes de aceptarla;
- escanea una o varias hojas seguidas, que llegan a la vista previa como páginas;
- funciona en el teléfono con el escáner de documentos de Google y no envía nada.

Esta funcionalidad amplía 001 a 008 sin cambiar sus reglas.

### 1. Escanear

- En el inicio, **«Escanear hoja»** es la primera opción, antes de «Tomar fotografía» y
  «Elegir imagen guardada», que siguen igual.
- El escáner muestra la cámara, marca los bordes de la hoja y la recorta y endereza.
  Antes de aceptar, se puede ajustar el recorte, girar y elegir un filtro.
- **Se pueden escanear varias hojas seguidas, hasta las que quepan en el documento (10 en
  total, como en 004).** Llegan a la vista previa en el orden en que se escanearon.
- También se puede escanear desde «Agregar página» en la vista previa.

### 2. Las mismas reglas de siempre

- **Las hojas escaneadas cumplen las mismas reglas que cualquier imagen (JPEG, hasta
  10 MB, de 600 a 10 000 píxeles por lado) y se guardan como copias de trabajo
  (constitución §3).**
- **El escáner trabaja en el teléfono y no envía nada. La imagen solo sale con la
  autorización de siempre, al reconocer el texto.**
- El escáner no borra marcas ni manchas por su cuenta: solo recorta, endereza y aplica
  el filtro que la persona elige, para no alterar la escritura (constitución §3).

### 3. Si el escáner no está disponible

- El escáner depende de los servicios de Google Play. **Si el teléfono no los tiene o no
  se puede usar, la app lo explica y ofrece tomar una fotografía o elegir una imagen.**
- Cancelar el escáner no cambia nada.

## Lo que NO se va a construir en esta iteración (Non-Goals)

- Un escáner propio (detección de bordes programada en la app).
- Limpieza automática de manchas o dedos (modo «completo» del escáner).
- Guardar las hojas escaneadas en la galería del teléfono.
- Escanear a PDF directamente, sin reconocer el texto.

## Clarifications

### Session 2026-11-05

- Q: ¿Qué se incorpora ahora? → A: El responsable del proyecto eligió el escáner
  automático de la hoja, junto con otras mejoras que van en 010 a 012.

## Historias de usuario y escenarios de aceptación

Las etiquetas del código usan el prefijo `ED` (escáner de documentos): `[ED-H1-E2]` es
la Historia 1, escenario 2, de esta funcionalidad.

### Historia 1 - Escanear una hoja (Prioridad: P1)

Una estudiante escanea sus apuntes sobre la mesa; el escáner endereza la hoja torcida y
la IA lee mejor.

**Por qué esta prioridad**: una hoja recortada y derecha es lo que más mejora el
reconocimiento (consejo 2 de 006).

**Prueba independiente**: escanear una y varias hojas y reconocerlas. Requiere pruebas
automatizadas del controlador y de las pantallas.

**Escenarios de aceptación**:

1. **Dado** el inicio, **Cuando** se muestra, **Entonces** ofrece «Escanear hoja» como
   primera opción.
2. **Dado** el escáner abierto, **Cuando** se acepta una hoja, **Entonces** aparece en la
   vista previa como página 1, lista para reconocer con la autorización de siempre.
3. **Dado** el escáner, **Cuando** se escanean varias hojas, **Entonces** llegan como
   páginas en el mismo orden, sin pasar de 10 en el documento.
4. **Dado** la vista previa, **Cuando** se elige «Agregar página» y «Escanear»,
   **Entonces** las hojas escaneadas se agregan al final.
5. **Dado** el escáner abierto, **Cuando** se cancela, **Entonces** nada cambia.

### Historia 2 - Escáner no disponible (Prioridad: P2)

Un docente con un teléfono sin servicios de Google intenta escanear.

**Por qué esta prioridad**: la app no puede quedar bloqueada si falta el escáner.

**Prueba independiente**: simular el escáner no disponible y un fallo. Requiere pruebas
automatizadas del controlador y de las pantallas.

**Escenarios de aceptación**:

1. **Dado** un teléfono sin el escáner, **Cuando** se elige «Escanear hoja», **Entonces**
   un aviso lo explica y ofrece tomar una fotografía.
2. **Dado** un fallo del escáner, **Cuando** ocurre, **Entonces** se explica y el texto
   en edición y las páginas se conservan.

### Historia 3 - Las reglas de imagen se cumplen (Prioridad: P3)

**Por qué esta prioridad**: el escáner es una fuente nueva de imágenes y debe pasar por
los mismos controles.

**Prueba independiente**: entregar hojas escaneadas válidas y no válidas. Requiere
pruebas automatizadas del controlador.

**Escenarios de aceptación**:

1. **Dado** una hoja escaneada válida, **Cuando** llega a la app, **Entonces** se trabaja
   con una copia y la vista previa muestra su formato, tamaño y medidas.
2. **Dado** una hoja escaneada que no cumple las reglas, **Cuando** llega, **Entonces**
   se explica por qué y las demás hojas válidas se agregan (como en 004).
3. **Dado** una hoja escaneada en la vista previa, **Cuando** se toca el botón para
   reemplazarla, **Entonces** dice «Escanear de nuevo» y abre el escáner.

### Casos límite

- La primera vez, el teléfono puede tener que descargar el escáner. Mientras tanto, el
  escáner muestra su propio aviso de espera.
- Si ya hay 10 páginas, «Escanear» no se ofrece (como en 004).

## Criterios de éxito medibles

- **SC-901**: con el escáner, una hoja llega a la vista previa con un toque en la app
  («Escanear hoja») más la aceptación en el escáner.
- **SC-902**: 0 hojas escaneadas se envían sin autorización.
- **SC-903**: cancelar el escáner no cambia nada: 0 páginas agregadas y el texto en
  edición igual.
- **SC-904**: con el escáner no disponible, el aviso y la opción de la cámara aparecen
  el 100 % de las veces.

## Supuestos pendientes de validación

Decisiones adoptadas para poder implementar; deben confirmarse con el responsable del
proyecto.

1. Se usa el escáner de documentos de Google (ML Kit), que viene con los servicios de
   Google Play: no requiere cuenta ni clave.
2. Modo con filtros, sin limpieza automática (sección 2).
3. «Tomar fotografía» se conserva para los teléfonos sin el escáner.
