---

description: "Tareas de la funcionalidad 010: organizar documentos"
---

# Tasks: Organizar documentos

**Input**: [plan.md](plan.md), [spec.md](spec.md), [research.md](research.md)

**Tests**: incluidas (constitución §6). Los identificadores siguen desde T901.

## Phase 1: User Story 1 - Nombre del archivo (Priority: P1) 🎯

- [X] T901 [P] [US1] Pruebas del nombre propuesto (título, caracteres no permitidos, largo, vacío, renombrado) en frontend/test/services/file_name_test.dart
- [X] T902 [US1] suggestedFileName con el título y su uso en DocumentFlowController.export (frontend/lib/state/document_flow_controller.dart)

## Phase 2: User Story 2 - Copiar (Priority: P2)

- [X] T903 [US2] «Copiar todo el texto» en el menú del editor (frontend/lib/presentation/screens/editor_screen.dart), textos en español e inglés y privacidad; pruebas de pantalla en frontend/test/presentation/organize_test.dart

## Phase 3: User Story 3 - Buscar y renombrar (Priority: P3)

- [X] T904 [P] [US3] Pruebas de búsqueda (tildes y mayúsculas), renombrar y conservar el nombre al volver a guardar
- [X] T905 [US3] renamed y matchesQuery en frontend/lib/models/history_entry.dart; JSON en frontend/lib/services/history_store.dart; rename en frontend/lib/state/document_history.dart
- [X] T906 [US3] Búsqueda y «Renombrar» en frontend/lib/presentation/screens/history_screen.dart

## Phase 4: Polish

- [X] T907 Spec 007 (Non-Goals), quickstart.md, README.md y MAPA_DEL_CODIGO.md
- [ ] T908 Formateador, analizador, todas las pruebas y recorrido en el emulador; registro de verificación al final de este archivo (parcial: falta el recorrido en un teléfono; ver el registro)

## Dependencies & Execution Order

US1 → US2 → US3 → Polish. T902 usa el título de T905 cuando el documento se renombró.

## Registro de verificación (T907 y T908, 2026-11-06)

Constitución §6, Entrega: verificaciones ejecutadas, resultados y limitaciones.

| Verificación | Comando o entorno | Resultado |
|--------------|-------------------|-----------|
| Formato y analizador de la app | `dart format` y `flutter analyze` (incluye `integration_test`) | Sin problemas |
| Pruebas del backend | `pytest` y `ruff` | 155 superadas; sin problemas (009 a 012 no cambian la API) |
| Pruebas de la app | `flutter test` | 337 superadas en total, 9 omitidas (contrato). De 010: 4 en `file_name_test.dart` y 9 en `organize_test.dart` |
| Nombre del archivo | `document_flow_controller_test.dart` | La prueba de exportar ahora espera «Texto con error corregido.docx» (el título) en lugar de «HandText_fecha» [SC-1001] |
| Accesibilidad (006) | `history_screen_test.dart` | La lista con documentos, con la búsqueda y los botones «Renombrar» y «Eliminar», cumple las guías al 100 % y 200 % |
| Inglés (008) | `language_test.dart` (prueba nueva) | La búsqueda, el mensaje «sin resultados» y el diálogo «Renombrar», en inglés y con las guías de toque, al 100 % y 200 % [SC-802] [SC-805] |
| Emulador | — | No se hizo (ver limitaciones) |

**La prueba detecta lo que debe** (comprobado a propósito): con un título en español
(«Cambiar el título») puesto en el diálogo en inglés, la prueba nueva falla en «Rename» y
muestra el texto. Se volvió a dejar el texto original.

**Limitaciones**:
- **No hubo recorrido en el emulador**: con 1 a 2 GB de memoria libres en el computador,
  el emulador dejó de responder en la sesión de 011 y se cerró.
- Todo lo de 010 es de la app y está cubierto por pruebas de pantalla. Lo único que
  depende de Android es que su diálogo para guardar muestre el nombre propuesto; falta
  verlo en un teléfono ([quickstart.md](quickstart.md), §2).
- Siguen pendientes los supuestos 1 y 2 (CHK1008) y la confirmación del alcance con la
  profesora (CHK1009).
