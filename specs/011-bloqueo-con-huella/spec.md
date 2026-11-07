## Features principales

HandText AI se puede **bloquear con la huella o el rostro**:
- un ajuste para activarlo, apagado por omisión;
- con el bloqueo activo, la app pide la huella, el rostro o el bloqueo de pantalla del
  teléfono al abrirla y al volver a ella después de un rato;
- mientras está bloqueada, no se ve ningún documento.

Esta funcionalidad amplía 001 a 010 sin cambiar sus reglas.

### 1. Activar el bloqueo

- En Ajustes, **«Bloquear con huella o rostro»**. Al activarlo, la app pide la huella o
  el rostro para confirmar que funciona.
- **Si el teléfono no tiene huella, rostro ni bloqueo de pantalla configurados, la opción
  lo explica y no se puede activar.**
- El ajuste es del teléfono, como los demás (spec 005).

### 2. Abrir la app bloqueada

- **Con el bloqueo activo y una sesión iniciada, la app muestra la pantalla de bloqueo al
  abrirse y al volver después de más de 1 minuto en segundo plano.**
- La pantalla de bloqueo muestra el logo y «Desbloquear». **Mientras está bloqueada, no
  se ve ningún documento.**
- Se puede desbloquear con la huella, el rostro o el PIN, patrón o contraseña del
  teléfono. Si se cancela o falla, sigue bloqueada y se puede volver a intentar.
- La bienvenida, el ingreso y el registro no se bloquean: no muestran documentos.

### 3. Privacidad

- **La huella y el rostro nunca llegan a la app**: Android los verifica y solo responde
  si la persona es la dueña del teléfono.
- Nada se envía al servidor.

## Lo que NO se va a construir en esta iteración (Non-Goals)

- Un PIN propio de la app.
- Ocultar la vista previa en la lista de apps recientes.
- Elegir cuánto tiempo pasa antes de bloquear.
- Bloquear por cuenta en lugar de por teléfono.

## Clarifications

### Session 2026-11-05

- Q: ¿Qué se incorpora ahora? → A: El responsable del proyecto eligió abrir la app con
  huella o rostro.

## Historias de usuario y escenarios de aceptación

Las etiquetas del código usan el prefijo `BL` (bloqueo): `[BL-H1-E2]` es la Historia 1,
escenario 2, de esta funcionalidad.

### Historia 1 - Activar el bloqueo (Prioridad: P1)

Un docente presta el teléfono a sus hijos y no quiere que vean las notas de sus
estudiantes.

**Por qué esta prioridad**: sin activarlo, el bloqueo no existe.

**Prueba independiente**: activar y desactivar el ajuste con y sin huella configurada.
Requiere pruebas automatizadas del ajuste y de la pantalla.

**Escenarios de aceptación**:

1. **Dado** Ajustes, **Cuando** se muestra, **Entonces** el bloqueo está apagado.
2. **Dado** un teléfono con huella o rostro, **Cuando** se activa el bloqueo y se
   confirma la huella, **Entonces** queda activo y se guarda.
3. **Dado** que se cancela la confirmación, **Cuando** se vuelve a Ajustes, **Entonces**
   el bloqueo sigue apagado.
4. **Dado** un teléfono sin huella, rostro ni bloqueo de pantalla, **Cuando** se abre
   Ajustes, **Entonces** la opción explica por qué no se puede activar.

### Historia 2 - Abrir la app bloqueada (Prioridad: P2)

**Por qué esta prioridad**: es el propósito del bloqueo.

**Prueba independiente**: abrir la app, salir y volver con el bloqueo activo. Requiere
pruebas automatizadas de pantalla con un verificador falso.

**Escenarios de aceptación**:

1. **Dado** el bloqueo activo y una sesión, **Cuando** se abre la app, **Entonces** se ve
   la pantalla de bloqueo y ningún documento.
2. **Dado** la pantalla de bloqueo, **Cuando** la persona se verifica, **Entonces** se ve
   la app donde estaba, con el borrador intacto.
3. **Dado** la pantalla de bloqueo, **Cuando** se cancela o falla la verificación,
   **Entonces** sigue bloqueada y «Desbloquear» lo vuelve a intentar.
4. **Dado** la app desbloqueada, **Cuando** pasa más de 1 minuto en segundo plano y se
   vuelve, **Entonces** se bloquea; si pasa menos, no.
5. **Dado** el bloqueo activo y sin sesión, **Cuando** se abre la app, **Entonces** se ve
   la bienvenida sin bloqueo.

### Historia 3 - Desactivar el bloqueo (Prioridad: P3)

**Prueba independiente**: desactivar el ajuste. Requiere pruebas automatizadas.

**Escenarios de aceptación**:

1. **Dado** el bloqueo activo, **Cuando** se desactiva en Ajustes, **Entonces** la app
   deja de pedir la huella al abrirse.

### Casos límite

- Si la huella se borra del teléfono con el bloqueo activo, la app pide el bloqueo de
  pantalla del teléfono.
- Cerrar sesión no cambia el ajuste; la próxima sesión también se bloquea.
- Las pantallas de Android que abre la app (escáner, recorte, guardar y compartir) también
  cuentan como segundo plano: si se usan más de 1 minuto, al volver se pide la
  verificación.

## Criterios de éxito medibles

- **SC-1101**: con el bloqueo activo, el 100 % de las aperturas con sesión muestran la
  pantalla de bloqueo antes que cualquier documento.
- **SC-1102**: una verificación cancelada o fallida nunca deja ver la app (0 casos).
- **SC-1103**: desbloquear conserva el estado: el texto en edición y su borrador no
  cambian.
- **SC-1104**: el bloqueo está apagado por omisión y solo se activa con una verificación
  correcta.

## Supuestos pendientes de validación

Decisiones adoptadas para poder implementar; deben confirmarse con el responsable del
proyecto.

1. El bloqueo es del teléfono, no de la cuenta.
2. Se bloquea al volver después de más de 1 minuto en segundo plano.
3. Se acepta el PIN, patrón o contraseña del teléfono como alternativa a la huella.
