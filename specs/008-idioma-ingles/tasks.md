---

description: "Tareas de la funcionalidad 008: app en inglés"
---

# Tasks: App en inglés

**Input**: [plan.md](plan.md), [spec.md](spec.md), [research.md](research.md)

**Tests**: incluidas (constitución §6). Los identificadores siguen desde T701.

## Phase 1: Base

- [X] T701 Clase abstracta AppStrings, delegado y context.strings en frontend/lib/presentation/strings.dart; los textos en español pasan a frontend/lib/presentation/strings_es.dart
- [X] T702 Las pantallas y widgets usan context.strings; main.dart y los servicios leen AppStrings.current (R3); las pruebas usan la instancia en español (frontend/test/support/strings_es.dart). Todas las pruebas anteriores siguen pasando

## Phase 2: User Story 1 - Elegir el idioma (Priority: P1) 🎯

- [X] T703 [P] [US1] Pruebas del ajuste (guardar, leer, archivo anterior, valor desconocido) en frontend/test/state/settings_test.dart
- [X] T704 [US1] AppLanguage en AppSettings, almacén y controlador; locale y resolución en frontend/lib/app.dart
- [X] T705 [P] [US1] Pruebas de pantalla: Ajustes, bienvenida, «Automático» con teléfono en inglés y en otro idioma, conservar al cerrar, en frontend/test/presentation/language_test.dart
- [X] T706 [US1] Selector en Ajustes y hoja de idioma en la bienvenida (frontend/lib/presentation/widgets/language_sheet.dart)

## Phase 3: User Story 2 - Toda la app en inglés (Priority: P2)

- [X] T707 [US2] Traducción completa en frontend/lib/presentation/strings_en.dart (fechas y tamaños en inglés; detalle de la API, R8)
- [X] T708 [P] [US2] Recorrido de todas las pantallas en inglés al 100 % y al 200 % sin textos en español (SC-802, SC-805), fallos y títulos de servicios

## Phase 4: User Story 3 - El texto no cambia (Priority: P3)

- [X] T709 [P] [US3] Prueba: cambiar el idioma con texto y marcas en el editor no los cambia, y la exportación usa el mismo texto (SC-803)

## Phase 5: Polish

- [X] T710 Privacidad (el idioma en «Ajustes»), quickstart.md, README.md y MAPA_DEL_CODIGO.md; spec 005 (Non-Goal del idioma)
- [X] T711 Formateador, analizador, todas las pruebas y recorrido en el emulador en inglés; registro de verificación al final de este archivo

## Dependencies & Execution Order

Base → US1 → US2 → US3 → Polish. T702 toca casi todas las pantallas: va antes que lo
demás.

## Registro de verificación (T711, 2026-10-29)

Constitución §6, Entrega: verificaciones ejecutadas, resultados y limitaciones.

| Verificación | Comando o entorno | Resultado |
|--------------|-------------------|-----------|
| Formato y analizador de la app | `dart format` y `flutter analyze` | Sin problemas |
| Pruebas de la app | `flutter test` | 298 superadas en total (16 de 008); 9 omitidas (contrato). Las 282 anteriores pasaron sin cambios después de mover los textos |
| Pruebas del backend | `pytest` y `ruff` | 155 superadas; sin problemas (008 no cambia la API) |
| Traducción completa | Compilación | `AppStringsEn` implementa los 158 textos de la clase abstracta [SC-801] |
| Recorrido en inglés, 100 % y 200 % | `language_test.dart` | 20 pantallas, menús, hojas y diálogos sin textos en español ni desbordes [SC-802] [SC-805] |
| Recorrido en el emulador (Android 16) | Versión final | Ver detalle abajo |

**La prueba detecta lo que debe** (comprobado a propósito):
- La primera versión del control solo buscaba letras del español (¿ ¡ á é í ó ú ñ). Una
  frase sin tildes («Sus apuntes a mano, convertidos…») puesta en una pantalla en inglés
  pasaba sin detectarse.
- Ahora también busca las frases del archivo en español que no están en el inglés.
- Con esa misma frase escrita directamente en la bienvenida, la prueba falla en
  «bienvenida» y muestra el texto.

**Recorrido en el emulador**:
- Recién instalada, la app está en español [IE-H1-E1].
- El botón «Español» de la bienvenida abre la hoja «Idioma»; al elegir «English», la
  bienvenida cambia al instante, sin reiniciar [IE-H1-E2].
- Ingreso, consejos («Tip 1 of 4»), inicio, «My documents» y Ajustes (con la tarjeta
  «Language») se ven en inglés.
- Vista previa, autorización («Allow sending the image?») y un fallo real del servidor:
  sin la clave de Google, la app dice «The recognition service is not available right
  now. Try again later.» [IE-H2-E2].
- Se volvió a dejar en español desde Ajustes.

**Limitaciones**:
- El selector de fotos, el diálogo para guardar, uCrop y el menú de compartir son de
  Android: sus botones siguen el idioma del teléfono. La app controla solo los títulos
  que les pasa (IE-H2-E3).
- La traducción la hizo el asistente; falta la revisión de una persona con buen nivel
  de inglés (supuesto 2, CHK808).

