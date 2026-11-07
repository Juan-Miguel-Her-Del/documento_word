## Features principales

HandText AI permite digitalizar varias hojas en un solo documento. La persona elige o
fotografía hasta 10 páginas, las ordena, las revisa en la vista previa y las reconoce
juntas. El texto de todas queda en un solo documento, en el orden elegido.

Esta funcionalidad amplía [001](../001-handtext-mvp/spec.md),
[002](../002-cuentas-de-usuario/spec.md) y [003](../003-revision-recorte-compartir/spec.md):
- reemplaza el Non-Goal de 001 «Captura o reconocimiento de múltiples páginas o imágenes
  dentro de un mismo documento»;
- reemplaza el de 003 «Recortar varias páginas o unir imágenes»;
- conserva todas las demás reglas. Cada página sigue las reglas de imagen de 001 y
  puede recortarse como en 003.

### 1. Agregar páginas

- **Un documento tiene de 1 a 10 páginas.**
- «Elegir imagen guardada» permite elegir varias imágenes de la galería a la vez.
- En la vista previa, «Agregar página» suma más páginas desde la galería o la cámara,
  hasta el límite.
- **Cada página se valida con las reglas de 001.** Si una no las cumple, no se agrega, se
  informa el motivo y las demás sí se agregan.

### 2. Organizar las páginas

- La vista previa muestra miniaturas numeradas de todas las páginas y una en grande.
- Permite elegir una página, moverla antes o después, quitarla y recortarla o girarla.
- «Elegir otra imagen» o «Repetir captura» reemplaza solo la página elegida.

### 3. Reconocer las páginas

- **Se pide una sola autorización para todas las páginas; el mensaje dice cuántas
  imágenes se enviarán.**
- Las páginas se reconocen una por una, en orden, y se muestra el avance («Página 2
  de 3»).
- El texto de todas las páginas se une en el orden elegido, con una línea en blanco
  entre página y página.
- Las palabras dudosas de cada página (003) se marcan en el texto unido.
- **Si una página falla, se informa cuál y se puede reintentar. Las páginas ya
  reconocidas no se vuelven a enviar.**
- Si una página no tiene texto, se omite y se informa; si ninguna tiene texto, se informa
  como en 001.

### 4. Privacidad y retención

- **Las copias de trabajo de todas las páginas se borran al reconocer, al cancelar y al
  cerrar sesión, como en 001.**

## Lo que NO se va a construir en esta iteración (Non-Goals)

- Saltos de página en el Word o el PDF. Las páginas quedan separadas por una línea en
  blanco.
- Más de 10 páginas por documento.
- Reconocer varias páginas en paralelo.
- Escanear documentos de varias páginas con detección automática de bordes.
- Guardar las imágenes de las páginas después de reconocer (sigue fuera, como en 001).

## Clarifications

### Session 2026-10-29

- Q: ¿Se incorporan varias páginas por documento, que 001 excluía? → A: Sí. Lo eligió el
  responsable del proyecto entre varias propuestas. Se especifica como funcionalidad 004
  (constitución §1: el procesamiento de múltiples páginas requiere una especificación
  aprobada).

## Historias de usuario y escenarios de aceptación

Las etiquetas del código usan el prefijo `VP` (varias páginas): `[VP-H1-E3]` es la
Historia 1, escenario 3, de esta funcionalidad.

### Historia 1 - Digitalizar varias hojas en un documento (Prioridad: P1)

Una estudiante fotografía las 4 hojas de sus apuntes de biología y obtiene un solo Word con
todo el texto, en orden.

**Por qué esta prioridad**: los apuntes casi nunca son de una sola hoja; sin esto, la
persona debe unir varios documentos a mano.

**Prueba independiente**: elegir 3 imágenes de la galería, reconocerlas y comprobar el
orden del texto. Requiere pruebas automatizadas del controlador con servicios falsos.

**Escenarios de aceptación**:

1. **Dado** el inicio, **Cuando** la persona elige 3 imágenes de la galería,
   **Entonces** la vista previa muestra 3 páginas numeradas, en el orden elegido.
2. **Dado** la vista previa, **Cuando** toca «Agregar página» y elige la cámara o la
   galería, **Entonces** las nuevas páginas se agregan al final.
3. **Dado** 3 páginas, **Cuando** toca «Aceptar y reconocer», **Entonces** se pide una
   sola autorización que menciona 3 imágenes.
4. **Dado** la autorización, **Cuando** se reconoce, **Entonces** el avance muestra qué
   página se está leyendo.
5. **Dado** que todas las páginas se reconocieron, **Cuando** se abre el editor,
   **Entonces** el texto contiene las páginas en orden, separadas por una línea en blanco.
6. **Dado** 10 páginas, **Cuando** intenta agregar otra, **Entonces** no se permite y se
   informa el límite.
7. **Dado** que una de las imágenes elegidas no cumple las reglas de 001, **Cuando** se
   agregan, **Entonces** esa no se agrega, se informa el motivo y las demás sí.

### Historia 2 - Organizar las páginas (Prioridad: P2)

Un docente eligió las fotos en desorden: las reordena, quita una repetida y recorta otra
antes de reconocer.

**Por qué esta prioridad**: el orden de la galería no siempre es el de las hojas.

**Prueba independiente**: mover, quitar, recortar y reemplazar páginas en la vista
previa. Requiere pruebas automatizadas del controlador y de la pantalla.

**Escenarios de aceptación**:

1. **Dado** varias páginas, **Cuando** toca una miniatura, **Entonces** esa página se ve
   en grande con sus datos.
2. **Dado** una página elegida, **Cuando** la mueve antes o después, **Entonces** cambia
   su posición y la numeración se actualiza.
3. **Dado** varias páginas, **Cuando** quita una, **Entonces** desaparece, su copia de
   trabajo se borra y las demás se renumeran.
4. **Dado** una página elegida, **Cuando** la recorta o gira, o la reemplaza con otra
   imagen, **Entonces** solo cambia esa página.
5. **Dado** una sola página, **Cuando** se mira la vista previa, **Entonces** no se
   ofrecen las acciones de mover ni quitar (se usa «Cancelar»).

### Historia 3 - Fallos de una página (Prioridad: P3)

Mientras se reconoce la tercera de 5 hojas se corta la conexión. Al volver, la persona
reintenta y solo se envían las 3 que faltaban.

**Por qué esta prioridad**: evita reenviar imágenes y esperar de nuevo por páginas que ya
se leyeron.

**Prueba independiente**: simular un fallo en una página y reintentar. Requiere pruebas
automatizadas del controlador.

**Escenarios de aceptación**:

1. **Dado** que una página falla, **Cuando** termina el intento, **Entonces** se informa
   qué página falló, se ofrece «Reintentar» y las páginas siguen en la vista previa.
2. **Dado** el fallo, **Cuando** la persona reintenta (con la autorización de siempre),
   **Entonces** solo se envían las páginas que no se habían reconocido.
3. **Dado** una página ya reconocida, **Cuando** se recorta o se reemplaza, **Entonces**
   se vuelve a enviar al reconocer, porque cambió su imagen. Si solo se mueve, no se
   reenvía: su texto se ubica en el nuevo orden.
4. **Dado** que una página no tiene texto, **Cuando** las demás sí, **Entonces** el
   documento se arma con las demás y el aviso dice qué página no tenía texto.
5. **Dado** que ninguna página tiene texto, **Cuando** termina, **Entonces** se informa
   como en 001 y se ofrece cambiar las imágenes.

### Casos límite

- Si el selector de la galería devuelve más imágenes de las que caben, se agregan solo
  hasta completar 10 y se informa.
- Si la persona cancela la vista previa con páginas ya reconocidas, esos resultados se
  descartan con las copias.
- Un documento de una sola página funciona exactamente como en 001.

## Criterios de éxito medibles

- **SC-401**: el texto del editor contiene todas las páginas reconocidas, en el orden
  elegido y separadas por una línea en blanco, sin perder ni duplicar ninguna.
- **SC-402**: al reintentar después de un fallo, ninguna página ya reconocida, y sin
  cambios, se vuelve a enviar.
- **SC-403**: nunca hay más de 10 páginas. No queda ninguna copia de trabajo de ninguna
  página después de reconocer, cancelar o cerrar sesión.
- **SC-404**: cada marca de palabra dudosa queda sobre su palabra en el texto unido.
- **SC-405**: cada página espera como máximo 60 s (SC-009 de 001 se aplica a cada una).

## Supuestos pendientes de validación

Decisiones adoptadas para poder implementar; deben confirmarse con el responsable del
proyecto.

1. El límite es de 10 páginas por documento.
2. Las páginas se separan con una línea en blanco, sin salto de página en el archivo.
3. Una sola autorización cubre todas las páginas de ese envío; reintentar la pide de
   nuevo.
4. Las páginas sin texto se omiten sin detener el reconocimiento de las demás.
