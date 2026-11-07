# Research: App en inglés

Decisiones técnicas de la funcionalidad 008. Cada una indica la alternativa descartada.

## R1. Archivos de traducción

**Decisión**: una clase abstracta `AppStrings` (en `strings.dart`) declara cada texto y
cada mensaje, y hay una clase por idioma:
- `strings_es.dart` (`AppStringsEs`): los textos de siempre;
- `strings_en.dart` (`AppStringsEn`): la traducción.

Si a un idioma le falta un texto, la app no compila [SC-801]. Los mensajes con lógica
(«Página 2 de 3», la lista de páginas vacías, el aviso de cada fallo) se escriben en cada
idioma con su propia gramática.

**Alternativas**:
- Archivos ARB con `gen-l10n`. Es el formato habitual de Flutter, pero exige el paquete
  `intl` y generar código. Además, los mensajes con lógica (el aviso de cada estado y de
  cada fallo) seguirían en Dart, así que cada texto quedaría repartido entre el ARB y el
  código.
- Un mapa de claves y textos. No avisa si falta una traducción.

## R2. Cómo llegan los textos a las pantallas

**Decisión**: un `LocalizationsDelegate<AppStrings>` en `MaterialApp`, como los textos
propios de Flutter. Las pantallas usan `context.strings` (o `AppStrings.of(context)`).
Al cambiar el idioma, Flutter vuelve a dibujar lo que usa los textos, sin reiniciar la
app ni perder el estado [IE-H1-E2] [SC-803].

**Alternativa**: textos estáticos y reiniciar la app al cambiar el idioma. Se perdería
lo que no está guardado (por ejemplo, las páginas de la vista previa).

## R3. Servicios sin pantalla

**Decisión**: el diálogo para guardar y el editor de recorte (uCrop) se crean en
`main.dart`, antes de saber el idioma. Reciben una función que lee el título en el
momento de usarlo, desde `AppStrings.current`, que el delegado actualiza al cargar cada
idioma [IE-H2-E3].

## R4. El ajuste

**Decisión**: `AppLanguage { spanish, english, system }` en `AppSettings`, con el campo
`language` en `settings.json`. Si falta o es desconocido, se usa `spanish` [IE-H1-E5].

## R5. «Automático»

**Decisión**: con `system`, `MaterialApp.locale` queda en `null`, y una función de
resolución elige el inglés si el idioma del teléfono es inglés y el español en cualquier
otro caso [IE-H1-E3].

## R6. Fechas y números

**Decisión**: cada idioma da formato a sus fechas («29 oct 2026, 15:30» / «Oct 29,
2026, 15:30») y tamaños («2,4 MB» / «2.4 MB») sin paquetes, como en 007 (R6).

## R7. Pruebas

**Decisión**:
- Completitud: la clase abstracta (en compilación).
- Recorrido en inglés de todas las pantallas, menús, hojas y diálogos, con la letra
  normal y al 200 %. Falla si un texto visible tiene `¿ ¡ á é í ó ú ñ`, letras que el
  inglés de la app nunca usa [SC-802] [SC-805]. El texto de la persona está en el campo
  del editor y no se revisa.
- Las pruebas anteriores usan la instancia en español (`es`) en lugar de los textos
  estáticos.

## R8. Detalle de error que viene de la API

**Decisión**: la API redacta en español el detalle de los caracteres que no se pueden
exportar. En inglés se muestra el mensaje general en inglés y no el detalle.

## R9. Idioma desde la bienvenida

**Decisión**: un botón con el ícono de idioma y el nombre del idioma actual abre una hoja
con las tres opciones. Los nombres de los idiomas se escriben siempre en su propio idioma
(«Español», «English»), para que se reconozcan aunque no se entienda la app.
