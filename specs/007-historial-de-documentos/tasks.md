---

description: "Tareas de la funcionalidad 007: historial de documentos"
---

# Tasks: Historial de documentos

**Input**: [plan.md](plan.md), [spec.md](spec.md), [research.md](research.md), [data-model.md](data-model.md)

**Tests**: incluidas (constitución §6). Los identificadores siguen desde T601.

## Phase 1: Base

- [X] T601 [P] Pruebas del almacén (guardar y leer, archivo dañado, otra cuenta, borrar, nombre seguro) y del título en frontend/test/services/history_store_test.dart
- [X] T602 HistoryEntry en frontend/lib/models/history_entry.dart y almacén en frontend/lib/services/history_store.dart
- [X] T603 DocumentHistory (cargar, registrar con límite de 50, eliminar, borrar todo) en frontend/lib/state/document_history.dart; arnés de pruebas con un almacén en memoria

## Phase 2: User Story 1 - Encontrar lo guardado (Priority: P1) 🎯

- [X] T604 [P] [US1] Pruebas del controlador: registrar al guardar, actualizar sin duplicar, no registrar cancelados ni fallidos, fallo del historial sin afectar el guardado, en frontend/test/state/history_flow_test.dart
- [X] T605 [US1] Registrar en DocumentFlowController.export y olvidar historyId al empezar otro documento (frontend/lib/state/document_flow_controller.dart); conexión en frontend/lib/main.dart
- [X] T606 [P] [US1] Pruebas de pantalla (lista, vacío, orden, otra cuenta) en frontend/test/presentation/history_screen_test.dart
- [X] T607 [US1] Pantalla frontend/lib/presentation/screens/history_screen.dart, «Mis documentos» en el inicio y textos (fechas en español) en frontend/lib/presentation/strings.dart

## Phase 3: User Story 2 - Abrir un documento (Priority: P2)

- [X] T608 [P] [US2] Pruebas de abrir (con y sin cambios sin exportar, confirmación, actualizar la misma entrada, borrador con historyId)
- [X] T609 [US2] openFromHistory en el controlador; historyId en frontend/lib/models/document_draft.dart y frontend/lib/services/draft_storage.dart; confirmación en la pantalla

## Phase 4: User Story 3 - Borrar (Priority: P3)

- [X] T610 [P] [US3] Pruebas de eliminar, borrar todo, cancelar y eliminar la cuenta
- [X] T611 [US3] Eliminar y borrar todo con confirmación en la pantalla; clearLocalData(deleteHistory: true) al eliminar la cuenta en frontend/lib/presentation/widgets/account_menu.dart

## Phase 5: Polish

- [X] T612 Privacidad («Historial»), quickstart.md, README.md y MAPA_DEL_CODIGO.md; guías de accesibilidad de 006 (nombres y 48 dp, al 100 % y al 200 %) en history_screen_test.dart
- [X] T613 Formateador, analizador, todas las pruebas y recorrido en el emulador con 50 documentos (SC-705); registro de verificación al final de este archivo

## Dependencies & Execution Order

Base → US1 → US2 → US3 → Polish. T605 y T609 tocan el mismo controlador.

## Registro de verificación (T613, 2026-10-29)

Constitución §6, Entrega: verificaciones ejecutadas, resultados y limitaciones.

| Verificación | Comando o entorno | Resultado |
|--------------|-------------------|-----------|
| Formato y analizador de la app | `dart format` y `flutter analyze` | Sin problemas |
| Pruebas de la app | `flutter test` | 282 superadas en total (36 de 007); 9 omitidas (contrato) |
| Pruebas del backend | `pytest` y `ruff` | 155 superadas; sin problemas (007 no cambia la API) |
| «Mis documentos» con 50 documentos en el emulador (Android 16) | Historial sintético de 50 documentos de unas 220 palabras; tiempos con los eventos de accesibilidad | Ver tabla [SC-705] |

**Tiempos** (desde el toque hasta el último cambio de pantalla, con la animación de
350 ms incluida):

| Acción | Compilación profile (AOT, como la final) | Compilación debug |
|--------|------------------------------------------|-------------------|
| Abrir «Mis documentos» | 0,13 s / 0,17 s / 0,36 s | 0,78 s |
| Abrir un documento en el editor | 0,39 s / 0,50 s (*) | 1,37 s |

(*) Una tercera medición registró solo dos eventos (0,07 s); el editor sí se abrió.

Con la compilación profile se cumple SC-705 (< 1 s). La de depuración compila el código
sobre la marcha, así que no representa la app que se entrega.

**Recorrido en el emulador**:
- el inicio muestra «Mis documentos — 50 documentos guardados»;
- la lista va del más reciente al más antiguo, con fecha, formatos y palabras;
- tocar un documento lo abre en el editor con el aviso «Se abrió el documento guardado».

**Limitaciones**:
- Para cargar 50 documentos se copió un historial sintético con `run-as`. Eso solo es
  posible en compilaciones depurables (debug y profile), no en la versión final.
- La compilación profile no permite HTTP, así que la app entró con la sesión guardada y
  sin conexión (caso límite de 002); para abrir la lista no hace falta la API.

