---

description: "Tareas de la funcionalidad 009: escáner de documentos"
---

# Tasks: Escáner de documentos

**Input**: [plan.md](plan.md), [spec.md](spec.md), [research.md](research.md)

**Tests**: incluidas (constitución §6). Los identificadores siguen desde T801.

## Phase 1: Base

- [X] T801 Dependencia google_mlkit_document_scanner 0.5.0 en frontend/pubspec.yaml; servicio DocumentScannerService con la versión de ML Kit (R1 a R4) en frontend/lib/services/document_scanner_service.dart; escáner falso en frontend/test/support/fakes.dart

## Phase 2: User Story 1 - Escanear (Priority: P1) 🎯

- [X] T802 [P] [US1] Pruebas del controlador: escanear una y varias hojas, límite de páginas, agregar al final, cancelar, en frontend/test/state/scanner_flow_test.dart
- [X] T803 [US1] ImageOrigin.scanner, scanDocument y el origen en _addImages en frontend/lib/state/document_flow_controller.dart; conexión en frontend/lib/main.dart
- [X] T804 [US1] «Escanear hoja» en el inicio, «Escanear» al agregar página y textos en español e inglés; pruebas de pantalla

## Phase 3: User Story 2 - No disponible (Priority: P2)

- [X] T805 [P] [US2] Pruebas: escáner no disponible con la acción «Tomar fotografía» y fallo que conserva todo
- [X] T806 [US2] scannerUnavailable y scannerFailed, StatusAction.takePhoto y el aviso con acción en el inicio

## Phase 4: User Story 3 - Reglas de imagen (Priority: P3)

- [X] T807 [P] [US3] Pruebas: hoja no válida entre válidas y «Escanear de nuevo» para reemplazar

## Phase 5: Polish

- [X] T808 Recorrido de accesibilidad de 006 e inglés de 008 con «Escanear hoja»; quickstart.md, README.md y MAPA_DEL_CODIGO.md
- [ ] T809 Formateador, analizador, todas las pruebas, compilación de la versión final y recorrido en el emulador con el escáner real; registro de verificación al final de este archivo (parcial: falta escanear una hoja en un teléfono; ver el registro)

## Dependencies & Execution Order

Base → US1 → US2 → US3 → Polish.

## Registro de verificación (T808 y T809, 2026-11-06)

Constitución §6, Entrega: verificaciones ejecutadas, resultados y limitaciones.

| Verificación | Comando o entorno | Resultado |
|--------------|-------------------|-----------|
| Formato y analizador de la app | `dart format` y `flutter analyze` (incluye `integration_test`) | Sin problemas |
| Pruebas del backend | `pytest` y `ruff` | 155 superadas; sin problemas (009 a 012 no cambian la API) |
| Pruebas de la app | `flutter test` | 337 superadas en total, 9 omitidas (contrato). De 009: 12 en `scanner_flow_test.dart` |
| Accesibilidad (006) e inglés (008) | `accessibility_test.dart`, `language_test.dart` | Los recorridos de 006 y 008 pasan por el inicio con «Escanear hoja». Prueba nueva en `language_test.dart`: el aviso «escáner no disponible» con «Take photo», en inglés y con las guías de toque, al 100 % y al 200 % [SC-904] |
| Versión final | `flutter build apk --release` (x86_64, demostración) | Compila: 20,0 MB. Lo que agrega al APK, en R7 |
| Emulador (Android 16 con Google Play) | Versión final | Ver detalle abajo |

**La compilación de la versión final** falló dos veces por el entorno, no por el código:
- sin DNS hacia `repo.maven.apache.org`, no se descargó una biblioteca (guava);
- el proceso de Gradle se cerró por falta de memoria.

Pasó al repetirla con el emulador cerrado y `gradlew --stop`.

**Recorrido en el emulador**:
- El inicio muestra «Escanear hoja» primero, con «Detecta los bordes y endereza la hoja
  (recomendado)» [ED-H1-E1].
- Al tocarla, la app abre el escáner de Google Play. En este emulador, Google Play intentó
  descargar el módulo del escáner y mostró dos veces «Something went wrong / Try again
  later».
- Al cancelar, la app volvió al inicio sin cambios [ED-H1-E5].

**Limitaciones**:
- **No se pudo escanear una hoja real**: el módulo del escáner no se descargó en el
  emulador. Una hoja y varias, el límite de 10, «Agregar página > Escanear» y «Escanear de
  nuevo» están cubiertos con el escáner falso de las pruebas, no en un teléfono.
- Falta repetirlo en un teléfono con Google Play ([quickstart.md](quickstart.md), §2).
- Los supuestos 1 a 3 siguen pendientes de validación (CHK908).
