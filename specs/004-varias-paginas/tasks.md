---

description: "Tareas de la funcionalidad 004: varias páginas por documento"
---

# Tasks: Varias páginas por documento

**Input**: [plan.md](plan.md), [spec.md](spec.md), [research.md](research.md),
[data-model.md](data-model.md)

**Tests**: incluidas (constitución §6). Los identificadores siguen desde T301.

## Phase 1: Foundational

- [X] T301 [P] Pruebas de joinPages en frontend/test/services/page_join_test.dart
- [X] T302 joinPages en frontend/lib/services/page_join.dart y DocumentPage en frontend/lib/models/document_page.dart
- [X] T303 pickMultipleFromGallery en frontend/lib/services/image_source_service.dart y en el servicio falso de las pruebas
- [X] T304 Página, total y páginas sin texto en frontend/lib/models/operation_status.dart; mensajes y fallo «demasiadas páginas» en frontend/lib/presentation/strings.dart y frontend/lib/models/app_failure.dart

## Phase 2: User Story 1 - Digitalizar varias hojas (Priority: P1) 🎯

- [X] T305 [P] [US1] Pruebas del controlador con varias páginas en frontend/test/state/pages_flow_test.dart
- [X] T306 [US1] Páginas en frontend/lib/state/document_flow_controller.dart: elegir varias, agregar, límite de 10 y reconocimiento en orden
- [X] T307 [US1] Autorización con la cantidad de imágenes en frontend/lib/presentation/widgets/consent_dialog.dart

## Phase 3: User Story 2 - Organizar las páginas (Priority: P2)

- [X] T308 [US2] Elegir, mover, quitar, recortar y reemplazar la página elegida en el controlador, con pruebas
- [X] T309 [US2] Tira de miniaturas y acciones en frontend/lib/presentation/widgets/page_strip.dart y frontend/lib/presentation/screens/preview_screen.dart, con pruebas de pantalla

## Phase 4: User Story 3 - Fallos de una página (Priority: P3)

- [X] T310 [US3] Fallo con número de página, reintento sin reenviar y páginas sin texto en el controlador, con pruebas

## Phase 5: Polish

- [X] T311 Documentación: quickstart.md, README.md y MAPA_DEL_CODIGO.md
- [X] T312 Formateadores, analizadores, todas las pruebas, APK y recorrido en el emulador; registro de verificación al final de este archivo

## Dependencies & Execution Order

Foundational → US1 → US2 → US3 → Polish. US2 y US3 dependen del modelo de páginas de
US1.

## Registro de verificación (T312, 2026-10-29)

Constitución §6, Entrega: verificaciones ejecutadas, resultados y limitaciones.

| Verificación | Comando | Resultado |
|--------------|---------|-----------|
| Formato y analizador de la app | `dart format` y `flutter analyze` | Sin problemas |
| Pruebas de la app | `flutter test` | 215 superadas (31 nuevas de 004); 9 omitidas (contrato, requieren `HANDTEXT_API_URL`) |
| Pruebas del backend | `pytest` | 155 superadas (004 no cambia la API) |
| Compilación Android | `flutter build apk --debug` | `app-debug.apk` generado |
| Recorrido en el emulador (Android 16, API 36) | APK instalado, API con PostgreSQL temporal y 3 hojas sintéticas en la galería | Ver detalle abajo |

**Recorrido en el emulador**:
- **Selección múltiple**: el selector de fotos de Android permitió marcar 3 imágenes. La
  vista previa mostró 3 miniaturas numeradas en el orden de selección, «Página 1 de 3» y
  «Reconocer 3 páginas» [VP-H1-E1].
- **Orden**: la página elegida pasó al lugar siguiente con la flecha, y la numeración se
  actualizó [VP-H2-E2].
- **Agregar página**: la tarjeta «+» abrió la hoja con «Tomar fotografía» y «Elegir de la
  galería» [VP-H1-E2].
- **Autorización**: el diálogo dijo «¿Autoriza el envío de 3 imágenes?» [VP-H1-E3].
- **Fallo de una página**: sin clave de Google, el aviso dijo «Página 1 de 3: El
  servicio de reconocimiento no está disponible…» con «Reintentar», y las 3 páginas
  siguieron en la vista previa [VP-H3-E1].
- **Retención**: con 3 páginas había 3 copias de trabajo; al quitar una, 2; al cancelar,
  0 [VP-H2-E3] [SC-403].

**Incidencias resueltas**:
- *Flechas desactivadas que parecían activas*: el color blanco fijo del ícono ocultaba
  el estado. Ahora se ven en gris cuando no se pueden usar.
- *Regla de reenvío al mover*: el spec decía que mover una página obligaba a reenviarla.
  No hace falta, porque su texto solo cambia de lugar al unir las páginas. Se corrigió el
  escenario VP-H3-E3 y R2 antes de implementar, y hay una prueba de que mover no reenvía.

**Limitaciones**:
- Sin clave de Google no se vio en el emulador un reconocimiento correcto de varias
  páginas. La unión del texto, las marcas y los reintentos están probados con la API
  falsa (pages_flow_test.dart).
- Siguen pendientes CHK408 (supuestos) y CHK409 (aprobación del alcance).
