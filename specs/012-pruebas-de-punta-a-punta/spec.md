## Features principales

HandText AI tiene **pruebas de punta a punta**: un robot instala la app en el emulador
y la recorre como una persona, desde crear la cuenta hasta guardar el Word, contra la API
y la base de datos reales.

Esta funcionalidad no cambia lo que la app hace: agrega una forma de comprobarlo.

### 1. El recorrido

- **Crear una cuenta en la API real** (PostgreSQL), elegir una hoja, autorizar el
  envío, revisar y corregir el texto y **guardarlo como Word generado por la API real**.
- Comprobar que el archivo guardado es un Word de verdad (constitución §3: contenido,
  extensión y tipo coinciden) y que llegó a Mis documentos.
- Cerrar sesión, volver a entrar y encontrar el documento en Mis documentos.

### 2. Lo que se simula

- **El reconocimiento se simula, porque la clave de Google todavía no está (T061 de
  001)**. El resto del camino (cuentas, exportación y guardado) es real.
- Las pantallas de Android que no son de la app (el selector de fotos y el diálogo para
  guardar) se reemplazan por versiones de prueba: la hoja es una imagen sintética y el
  archivo se guarda en la carpeta privada de la app.

### 3. Cómo se ejecuta

- Un solo comando, con la API local encendida y el emulador abierto.
- Al terminar, el registro dice cuánto tardó cada paso.

## Lo que NO se va a construir en esta iteración (Non-Goals)

- Ejecutarlas en la nube o en cada cambio (va con GitHub, que necesita su cuenta).
- Manejar las pantallas de Android (selector de fotos, diálogo para guardar).
- Reconocimiento real (necesita la clave de Google).

## Clarifications

### Session 2026-11-05

- Q: ¿Qué se incorpora ahora? → A: El responsable del proyecto eligió pruebas
  automáticas de punta a punta en el emulador, para mostrarlas al presentar.

## Historias de usuario y escenarios de aceptación

Las etiquetas del código usan el prefijo `PP` (punta a punta): `[PP-H1-E2]` es la Historia
1, escenario 2, de esta funcionalidad.

### Historia 1 - De la cuenta al Word (Prioridad: P1)

El responsable del proyecto quiere mostrar que la app funciona completa, sin tocarla.

**Por qué esta prioridad**: las pruebas de widgets usan servicios falsos; esta usa la API
y la base reales en un teléfono Android.

**Prueba independiente**: ejecutar el comando con la API local.

**Escenarios de aceptación**:

1. **Dado** la API local y el emulador, **Cuando** se ejecuta la prueba, **Entonces**
   crea una cuenta nueva en la API.
2. **Dado** la cuenta, **Cuando** elige la hoja y autoriza el envío, **Entonces** llega
   al editor con el texto reconocido y sus palabras dudosas.
3. **Dado** el editor, **Cuando** corrige el texto y lo guarda como Word, **Entonces** el
   archivo empieza con la firma de un .docx y contiene el texto corregido.
4. **Dado** el guardado, **Cuando** se abre Mis documentos, **Entonces** el documento
   está ahí.

### Historia 2 - Volver a encontrarlo (Prioridad: P2)

**Prueba independiente**: la misma ejecución, después de la Historia 1.

**Escenarios de aceptación**:

1. **Dado** el documento guardado, **Cuando** se cierra sesión y se vuelve a entrar con
   la misma cuenta, **Entonces** el documento sigue en Mis documentos.

### Casos límite

- Sin la API encendida, la prueba falla en el primer paso con un mensaje que lo dice.
- Cada ejecución crea una cuenta con un correo distinto, así se puede repetir.

## Criterios de éxito medibles

- **SC-1201**: el recorrido completo pasa en el emulador de referencia (Android 16) en
  menos de 3 minutos.
- **SC-1202**: el archivo guardado es un .docx real (firma «PK») con el texto corregido.
- **SC-1203**: la prueba se ejecuta con un solo comando documentado en el quickstart.

## Supuestos pendientes de validación

1. Simular el reconocimiento es aceptable hasta tener la clave de Google.
2. El diálogo para guardar se reemplaza en la prueba porque no es de la app.
