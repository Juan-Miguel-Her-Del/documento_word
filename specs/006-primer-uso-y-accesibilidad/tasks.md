---

description: "Tareas de la funcionalidad 006: primer uso y accesibilidad"
---

# Tasks: Primer uso y accesibilidad

**Input**: [plan.md](plan.md), [spec.md](spec.md), [research.md](research.md)

**Tests**: incluidas (constitución §6). Los identificadores siguen desde T501.

## Phase 1: User Story 1 - Consejos la primera vez (Priority: P1) 🎯

- [X] T501 [P] [US1] Pruebas de tipsSeen (almacén, JSON antiguo y controlador) en frontend/test/state/settings_test.dart
- [X] T502 [US1] tipsSeen en frontend/lib/models/app_settings.dart, frontend/lib/services/settings_store.dart y frontend/lib/state/settings_controller.dart
- [X] T503 [P] [US1] Pruebas de pantalla de los consejos (primera vez, Siguiente, Empezar, Saltar, atrás, cambio de cuenta, abrir desde el inicio y Ajustes) en frontend/test/presentation/tips_screen_test.dart
- [X] T504 [US1] Pantalla frontend/lib/presentation/screens/tips_screen.dart y textos en frontend/lib/presentation/strings.dart
- [X] T505 [US1] Consejos la primera vez en frontend/lib/presentation/screens/app_root.dart; enlaces en start_screen.dart y settings_screen.dart; arnés de pruebas con tipsSeen

## Phase 2: User Story 2 - TalkBack (Priority: P2)

- [X] T506 [P] [US2] Pruebas de nombres (labeledTapTargetGuideline), del anuncio de la palabra dudosa y de los encabezados en frontend/test/presentation/accessibility_test.dart
- [X] T507 [US2] Avatar sin la inicial en la lectura (R9) en frontend/lib/presentation/widgets/account_menu.dart
- [X] T508 [US2] Anuncio de la palabra elegida con «Siguiente» (R7) en frontend/lib/presentation/screens/editor_screen.dart
- [X] T509 [US2] Títulos como encabezados (R8) en las pantallas y en aurora_header.dart

## Phase 3: User Story 3 - Letra grande (Priority: P3)

- [X] T510 [P] [US3] Recorrido de todas las pantallas al 100 % y al 200 % con androidTapTargetGuideline y desbordes en frontend/test/presentation/accessibility_test.dart
- [X] T511 [US3] Avatar de 48 dp (R9) y diálogo de eliminar cuenta desplazable (R6) en frontend/lib/presentation/widgets/account_menu.dart
- [X] T512 [US3] Avisos del editor en un área desplazable y encabezado más corto con letra grande (R5) en frontend/lib/presentation/screens/editor_screen.dart; hoja de exportar desplazable (R6) en frontend/lib/presentation/widgets/export_format_sheet.dart

## Phase 4: Polish

- [X] T513 Documentación: quickstart.md, README.md, MAPA_DEL_CODIGO.md y la sección «Ajustes» de la privacidad
- [X] T514 Formateador, analizador, todas las pruebas y recorrido en el emulador con letra al 200 % y TalkBack (SC-606); registro de verificación al final de este archivo

## Dependencies & Execution Order

US1 → US2 → US3 → Polish. T506 y T510 comparten el archivo de pruebas; T511 y T507
tocan el mismo widget.

## Registro de verificación (T514, 2026-10-29)

Constitución §6, Entrega: verificaciones ejecutadas, resultados y limitaciones.

| Verificación | Comando o entorno | Resultado |
|--------------|-------------------|-----------|
| Formato y analizador de la app | `dart format` y `flutter analyze` | Sin problemas |
| Pruebas de la app | `flutter test` | 282 superadas en total (21 de 006); 9 omitidas (contrato) |
| Pruebas del backend | `pytest` y `ruff` | 155 superadas; sin problemas (006 no cambia la API) |
| Auditoría con pruebas, 100 % y 200 % | `accessibility_test.dart` | 19 pantallas, menús, hojas y diálogos: todo con nombre, de 48 dp o más y sin desbordes [SC-602] [SC-603] [SC-604] |
| Letra al 200 % en el emulador (Android 16) | `adb shell settings put system font_scale 2.0`, versión final | Bienvenida, registro, los cuatro consejos, inicio, Ajustes y editor sin cortes |
| TalkBack 16.0 en el emulador | TalkBack con «Mostrar la salida de voz» | «Siguiente» activado con doble toque; TalkBack dice «Palabra para revisar: eucariotas» [SC-605]; lee la barra «3 palabras para revisar…» al cambiar |

**Hallazgos en el emulador, corregidos con prueba de regresión**:
1. El título del inicio y el saludo se mezclaban con el botón de la cuenta en un solo
   nodo. TalkBack lo leía como encabezado y botón, sin decir «Cuenta» (research.md, R8).
   Ahora son nodos propios; la prueba falla si se quita la corrección (comprobado).
2. En Ajustes, con la letra al 200 %, los botones segmentados partían palabras
   («Autom-ático»). Ahora las opciones pasan a una lista cuando no caben (R10).

**Limitaciones**:
- SC-606 se verificó en parte. Con TalkBack se recorrieron la bienvenida, el inicio, el
  editor y la revisión de palabras. El reconocimiento no se pudo completar porque falta
  la clave de Google (T061 de 001). Guardar abre el diálogo de Android, que está fuera
  del alcance (supuesto 4).
- En un primer intento automático en el emulador, tres toques seguidos en «Siguiente»
  terminaron en el inicio en lugar del cuarto consejo. No se repitió al tocar uno por
  uno con capturas (consejo 1, 2, 3 y 4, y «Empezar» al inicio), y la causa no se
  confirmó. Las pruebas de widgets cubren la navegación exacta (PA-H1-E2).

