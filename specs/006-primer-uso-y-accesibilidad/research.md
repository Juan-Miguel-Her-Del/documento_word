# Research: Primer uso y accesibilidad

Decisiones técnicas de la funcionalidad 006. Cada una indica la alternativa descartada.

## Auditoría inicial (2026-10-29)

Antes de diseñar, se recorrieron con pruebas de widgets 14 pantallas, menús y diálogos
con la letra normal y al 200 %, usando las guías de accesibilidad de `flutter_test`:

| Hallazgo | Dónde | Escala |
|----------|-------|--------|
| El botón de la cuenta mide 44 × 44 dp (mínimo 48) y TalkBack lee «A» | Avatar del menú de cuenta | 100 % y 200 % |
| La columna se desborda 894 px | Editor | 200 % |
| El contenido se desborda 310 px | Diálogo «¿Eliminar su cuenta?» | 200 % |
| El contenido se desborda 138 px (apareció al corregir el editor) | Hoja «Exportar como» | 200 % |

Todo lo demás ya tenía nombre y medía al menos 48 dp. Los avisos de estado ya se
anunciaban (`liveRegion`, spec 001).

## R1. Dónde se recuerda que los consejos ya se vieron

**Decisión**: un campo `tipsSeen` en los ajustes del teléfono (`settings.json`, spec 005).
Si falta o el archivo está dañado, vale `false`.

**Alternativas**: un archivo propio (más código para un solo valor); guardarlo por cuenta
(contradice el supuesto 1).

## R2. Cuándo se muestran solos

**Decisión**: la zona con sesión (`SignedInScope`) muestra los consejos en lugar del
flujo de documentos mientras `tipsSeen` sea `false`. El controlador de documentos se crea
y se inicia igual, así el borrador se recupera en paralelo [caso límite].

**Alternativa**: abrir una ruta encima del inicio después del primer cuadro. Se ve el
inicio un instante y es más difícil de probar.

## R3. Pantalla de consejos

**Decisión**: `PageView` con cuatro páginas. Cada dibujo es un ícono grande de Material en
una insignia Aurora, sin imágenes nuevas ni dependencias. El cambio de página respeta
«quitar animaciones» (`motionDuration`). Al terminar o saltar, la misma pantalla sirve
para la primera vez (marca `tipsSeen`) y para volver a verlos (cierra la ruta).

**Alternativa**: un paquete de introducción (por ejemplo, `introduction_screen`). Agrega
una dependencia para algo que se resuelve con widgets de Flutter.

## R4. Cómo se comprueba la accesibilidad

**Decisión**: pruebas de widgets que recorren la app y, en cada pantalla, evalúan:
- `labeledTapTargetGuideline`: todo lo tocable tiene nombre [SC-602];
- `androidTapTargetGuideline`: mide al menos 48 × 48 dp [SC-603];
- la letra al 200 % (`textScaleFactorTestValue`): un desborde hace fallar la prueba
  [SC-604].

**Alternativa**: `textContrastGuideline`. El contraste ya lo cubren SC-208 y SC-306 con
los valores WCAG, y esa guía da falsos positivos sobre degradados e imágenes.

## R5. Editor con letra grande

**Decisión**: los avisos de arriba (advertencia, estado y barra de revisión) van en un
área desplazable de hasta el 45 % del alto disponible (`LayoutBuilder`,
`ConstrainedBox` y `SingleChildScrollView`). El campo de texto ocupa el resto. Con la
letra normal no cambia nada, porque los avisos caben.

Con solo eso, al 200 % el campo quedaba de 82 dp: el encabezado ocupaba 432 px (título
en tres líneas y subtítulo en cinco). Por eso, además:
- el título del editor crece hasta el 150 % (`MediaQuery.withClampedTextScaling`), como
  hace Android 14 con los textos grandes en su escala no lineal;
- con la letra por encima del 130 %, se omite el subtítulo, porque la advertencia de
  abajo dice lo mismo.

Con los tres cambios, el campo supera los 150 dp al 200 % (prueba de PA-H3-E2).

**Alternativas**:
- Desplazar toda la pantalla: con textos largos, «Exportar» queda al final del texto.
- Cambiar de diseño según el tamaño de letra: el campo se crearía de nuevo y el teclado
  se cerraría al abrirse.

## R6. Diálogo de eliminar cuenta y hoja de exportar

**Decisión**:
- Diálogo: `AlertDialog(scrollable: true)`; el mensaje y la contraseña se desplazan y
  los botones siguen a la vista.
- Hoja «Exportar como»: `isScrollControlled: true` y `SingleChildScrollView`; la hoja
  puede pasar de 9/16 de la pantalla y se desplaza si aun así no cabe.

## R7. Leer la palabra dudosa elegida

**Decisión**: después de «Siguiente», la app pide a TalkBack que lea «Palabra para
revisar: …» con un anuncio de accesibilidad (`SemanticsService`). Solo se anuncia; el foco
no se mueve.

**Alternativa**: una región que se lee sola (`liveRegion`) con la palabra. La barra ya es
una región de ese tipo para el contador, y anunciar dos cosas a la vez se entiende mal.

## R8. Encabezados

**Decisión**: el título de cada pantalla va dentro de
`Semantics(container: true, header: true)`.

`container: true` es necesario. Sin él, en el emulador el título del inicio y el saludo
se mezclaron con el botón de la cuenta en un solo nodo: TalkBack leía «Hola, Ana, ¿Qué
vamos a digitalizar hoy?» como un botón y como encabezado, sin decir «Cuenta». Por eso el
botón de la cuenta también es un nodo propio, y las pruebas exigen que un encabezado no
se pueda tocar y que el botón no tenga texto propio ni sea encabezado.

## R9. Botón de la cuenta

**Decisión**: mide 48 × 48 dp y la inicial se excluye de la lectura (`ExcludeSemantics`).
TalkBack lee «Cuenta, botón».

## R10. Opciones de Ajustes con la letra grande

**Hallazgo** (verificación en el emulador, letra al 200 %): los botones segmentados de
Ajustes partían las palabras («Autom-ático», «Norma-l», «Muy grand-e»). No es un
desborde, así que la auditoría con pruebas no lo detectó.

**Decisión**: antes de dibujar, se mide cada opción con la letra actual (`TextPainter`).
Si alguna no cabe en una línea dentro de su segmento, las opciones se muestran una debajo
de otra: una fila por opción, con un círculo marcado en la elegida, y TalkBack las lee
como botones de opción («Oscuro, marcado»). Con la letra normal no cambia nada.

La prueba carga la tipografía real (Poppins). La letra de prueba de Flutter es más ancha y
daría medidas distintas a las del teléfono.

**Alternativa**: decidir por el tamaño de letra (por ejemplo, más de 130 %). Depende de la
pantalla y de la tipografía; medir es exacto.
