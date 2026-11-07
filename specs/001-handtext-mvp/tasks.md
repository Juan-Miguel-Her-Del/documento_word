---

description: "Lista de tareas de implementación del MVP de HandText AI"
---

# Tasks: HandText AI — MVP

**Input**: Design documents from `/specs/001-handtext-mvp/`

**Prerequisites**: [plan.md](plan.md), [spec.md](spec.md), [research.md](research.md),
[data-model.md](data-model.md), [contracts/api.md](contracts/api.md)

**Tests**: incluidas, porque la constitución §6 exige pruebas automatizadas de OCR,
exportación, permisos e integraciones, con casos satisfactorios y de fallo.

**Organization**: tareas agrupadas por historia de usuario del spec (US1 = Historia 1, etc.).
Cada archivo de código indica en su cabecera las tareas que implementa.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: puede hacerse en paralelo (archivos distintos, sin dependencias pendientes)
- **[Story]**: historia a la que pertenece (US1, US2, US3)

---

## Phase 1: Setup (Shared Infrastructure)

- [X] T001 Crear el proyecto del backend y la configuración de ruff y pytest en backend/pyproject.toml
- [X] T002 [P] Fijar las dependencias exactas en backend/requirements.txt y backend/requirements-dev.txt
- [X] T003 [P] Crear la app Flutter solo para Android y declarar sus dependencias en frontend/pubspec.yaml (analizador: frontend/analysis_options.yaml)
- [X] T004 [P] Añadir los patrones de Python, entornos y secretos a .gitignore

---

## Phase 2: Foundational (Blocking Prerequisites)

- [X] T005 Configuración del backend (límites del spec, idiomas, tiempos y clave por variable de entorno) en backend/app/config.py
- [X] T006 Catálogo de errores con código, mensaje y request_id, y sus manejadores, en backend/app/errors.py
- [X] T007 Fábrica de la API, middleware de request_id y registros sin contenido en backend/app/main.py
- [X] T008 [P] Modelos de entrada y salida de la API en backend/app/schemas.py
- [X] T009 [P] Lectura del cuerpo con límite de tamaño en backend/app/api/request_body.py
- [X] T010 [P] Utilidades de prueba (imágenes sintéticas y OCR falso) en backend/tests/conftest.py
- [X] T011 [P] Pruebas del formato de errores y de la privacidad de los registros en backend/tests/test_errors_and_privacy.py
- [X] T012 [P] Configuración de la app (URL del backend, tiempos y límites) en frontend/lib/config/app_config.dart
- [X] T013 [P] Tema centralizado en frontend/lib/theme/app_theme.dart
- [X] T014 [P] Textos de la interfaz en español en frontend/lib/presentation/strings.dart
- [X] T015 [P] Modelos de la app en frontend/lib/models/ (app_failure.dart, operation_status.dart, image_format.dart, export_format.dart, picked_image.dart, recognition_result.dart)
- [X] T016 Manifiestos Android (Internet, sin copias de seguridad y HTTP solo en debug) en frontend/android/app/src/main/AndroidManifest.xml, frontend/android/app/src/main/res/xml/data_extraction_rules.xml y frontend/android/app/src/debug/AndroidManifest.xml

**Checkpoint**: base lista para las historias.

---

## Phase 3: User Story 1 - Digitalizar una imagen guardada y exportarla a Word (Priority: P1) 🎯 MVP

**Goal**: imagen de la galería → autorización → reconocimiento → edición → archivo .docx.

**Independent Test**: con una imagen sintética, reconocer, editar y exportar a .docx; abrir
el archivo y compararlo con el texto del editor.

### Tests for User Story 1

- [X] T017 [P] [US1] Validación de imágenes (formatos por contenido, 10 MB, 600–10 000 px) en backend/tests/test_image_validation.py
- [X] T018 [P] [US1] Preparación de la copia para el OCR (original intacto, orientación, sin EXIF) en backend/tests/test_image_preparation.py
- [X] T019 [P] [US1] Adaptador de Google Cloud Vision con transporte simulado en backend/tests/test_google_vision_provider.py
- [X] T020 [P] [US1] API de reconocimiento (texto, sin texto, límites, fallos del proveedor) en backend/tests/test_recognitions_api.py
- [X] T021 [P] [US1] Exportación Word (contenido, párrafos, caracteres, texto vacío) en backend/tests/test_exports_docx.py
- [X] T022 [P] [US1] Reglas de imagen de la app en frontend/test/services/image_rules_test.dart
- [X] T023 [P] [US1] Cliente HTTP y traducción de errores en frontend/test/services/handtext_api_client_test.dart
- [X] T024 [P] [US1] Borrador y copias de trabajo en frontend/test/services/storage_test.dart
- [X] T025 [P] [US1] Controlador del flujo (autorización, duplicados, fallos y borrador) en frontend/test/state/document_flow_controller_test.dart
- [X] T026 [P] [US1] Pantallas y diálogos del flujo en frontend/test/presentation/flow_screen_test.dart

### Implementation for User Story 1

- [X] T027 [US1] Validación de imágenes por contenido en backend/app/services/image_validation.py
- [X] T028 [US1] Preparación en memoria de la copia para el OCR en backend/app/services/image_preparation.py
- [X] T029 [US1] Contrato del proveedor de OCR y sus errores en backend/app/services/ocr/base.py
- [X] T030 [US1] Adaptador de Google Cloud Vision y su fábrica en backend/app/services/ocr/google_vision.py y backend/app/services/ocr/__init__.py
- [X] T031 [US1] Ruta POST /api/v1/recognitions en backend/app/api/recognitions.py
- [X] T032 [US1] Reglas del texto exportable (vacío, tamaño y caracteres XML) en backend/app/services/documents/text_rules.py
- [X] T033 [US1] Generador de Word en backend/app/services/documents/docx_builder.py
- [X] T034 [US1] Servicio de exportación y ruta POST /api/v1/exports en backend/app/services/documents/export_service.py y backend/app/api/exports.py
- [X] T035 [P] [US1] Reglas y lectura de dimensiones de imagen en frontend/lib/services/image_rules.dart
- [X] T036 [P] [US1] Copias de trabajo de imagen en frontend/lib/services/working_copy_service.dart
- [X] T037 [P] [US1] Borrador local en frontend/lib/services/draft_storage.dart
- [X] T038 [P] [US1] Cliente de la API en frontend/lib/services/handtext_api_client.dart
- [X] T039 [P] [US1] Guardado con el diálogo del sistema en frontend/lib/services/file_save_service.dart
- [X] T040 [P] [US1] Selección de imágenes de la galería en frontend/lib/services/image_source_service.dart
- [X] T041 [US1] Controlador del flujo en frontend/lib/state/document_flow_controller.dart
- [X] T042 [US1] Widgets de estado, autorización y confirmación en frontend/lib/presentation/widgets/ (status_message.dart, consent_dialog.dart, confirm_dialog.dart)
- [X] T043 [US1] Pantallas en frontend/lib/presentation/screens/ (flow_screen.dart, start_screen.dart, preview_screen.dart, editor_screen.dart)
- [X] T044 [US1] Arranque y composición de la app en frontend/lib/main.dart y frontend/lib/app.dart

**Checkpoint**: la Historia 1 funciona y se prueba por sí sola.

---

## Phase 4: User Story 2 - Capturar el documento con la cámara (Priority: P2)

**Goal**: fotografiar la hoja desde la app, con manejo del permiso de cámara.

**Independent Test**: capturar una hoja y llegar a la vista previa; repetir denegando el permiso.

- [X] T045 [P] [US2] Pruebas de captura y permisos en frontend/test/state/camera_flow_test.dart
- [X] T046 [US2] Servicio del permiso de cámara en frontend/lib/services/camera_permission_service.dart
- [X] T047 [US2] Captura con cámara en frontend/lib/services/image_source_service.dart y flujo «tomar fotografía» y «repetir captura» en frontend/lib/state/document_flow_controller.dart
- [X] T048 [US2] Permiso CAMERA en frontend/android/app/src/main/AndroidManifest.xml

**Checkpoint**: las Historias 1 y 2 funcionan de forma independiente.

---

## Phase 5: User Story 3 - Exportar el texto revisado a PDF (Priority: P3)

**Goal**: elegir PDF como formato de salida.

**Independent Test**: exportar un texto con tildes, ñ, ¿, ¡ y varias páginas, y compararlo.

- [X] T049 [P] [US3] Pruebas de PDF (caracteres, varias páginas, caracteres no representables) en backend/tests/test_exports_pdf.py
- [X] T050 [US3] Fuente DejaVu Sans y su licencia en backend/app/assets/fonts/
- [X] T051 [US3] Generador de PDF en backend/app/services/documents/pdf_builder.py
- [X] T052 [US3] Selector Word/PDF en frontend/lib/presentation/widgets/export_format_sheet.dart

**Checkpoint**: las tres historias funcionan.

---

## Phase 6: Polish & Cross-Cutting Concerns

- [X] T053 [P] Guía del repositorio en README.md
- [X] T054 [P] Mapa de requisitos → código → pruebas en MAPA_DEL_CODIGO.md
- [X] T055 [P] Guía de ejecución y validación en specs/001-handtext-mvp/quickstart.md
- [X] T056 Ejecutar formateadores, analizadores y todas las pruebas, y registrar los resultados al final de este archivo
- [X] T057 Compilar el APK de depuración con `flutter build apk --debug` en frontend/

## Phase 7: Medición de la calidad (SC-010, 2026-10-29; research.md, R15)

- [X] T058 [P] Pruebas de las métricas y del informe en backend/tests/test_ocr_quality.py
- [X] T059 Herramienta backend/tools/measure_ocr_quality.py (CER, WER, marcas e informe sin texto)
- [X] T060 Guía de la clave de Google y de la medición en specs/001-handtext-mvp/quickstart.md
- [ ] T061 Medir con al menos 10 hojas reales y anotar el resultado en este archivo (requiere la clave de Google y las hojas del responsable)

---

## Dependencies & Execution Order

- **Setup (fase 1)** → **Foundational (fase 2)** → historias en orden de prioridad.
- **US2** reutiliza la vista previa y el controlador de US1; añade cámara y permisos.
- **US3** reutiliza la ruta de exportación de US1; añade el generador de PDF y el selector.
- Dentro de cada historia: pruebas → servicios del backend → servicios de la app →
  controlador → pantallas.

## Parallel Example: User Story 1

```text
T017, T018, T019, T020 y T021 (pruebas del backend) en paralelo.
T035, T036, T037, T038, T039 y T040 (servicios de la app) en paralelo.
```

## Implementation Strategy

1. Fases 1 y 2, luego la Historia 1 completa: es el MVP demostrable con Word.
2. La Historia 2 añade la cámara sin cambiar el resto del flujo.
3. La Historia 3 añade PDF reutilizando la exportación.
4. Pulido: documentación, mapa del código y verificación completa.

---

## Registro de verificación (T056 y T057, 2026-10-27)

Constitución §6, Entrega: verificaciones ejecutadas, resultados y limitaciones.

| Verificación | Comando | Resultado |
|--------------|---------|-----------|
| Estilo del backend | `ruff format --check .` y `ruff check .` | Sin problemas |
| Pruebas del backend | `pytest` | 75 superadas |
| Analizador de la app | `flutter analyze` | Sin problemas |
| Pruebas de la app | `flutter test` | 75 superadas; 6 omitidas (las de contrato, que requieren `HANDTEXT_API_URL`) |
| Contrato app ↔ API real | `flutter test test/integration` con Uvicorn en marcha | 6 superadas |
| Compilación Android | `flutter build apk --debug` | `app-debug.apk` generado |
| Prueba en emulador (Android 16, API 36) | APK instalado y recorrido manual con `adb` | Ver detalle abajo |

**Recorrido en el emulador**:
- La app arranca en español.
- El selector de fotos de Android funciona sin permisos de almacenamiento.
- La vista previa muestra «JPEG · 1200 × 900 px · 36 KB».
- Aparece el diálogo de autorización (H1-E3).
- Sin clave de Google, la API responde 503 y la app muestra «El servicio de reconocimiento no está disponible…» con «Reintentar» (H1-E8).
- Tras un cierre forzado, el editor recupera el borrador (H1-E15).
- La exportación a Word por el diálogo «Guardar como» deja `Descargas/HandText_20261028_0226.docx`, cuyo contenido coincide exactamente con el texto, incluidos tildes, ñ, ¿, ¡ y —, y respeta los párrafos (SC-002).
- Después, el borrador se elimina (H1-E16).

**Incidencias resueltas durante la verificación**:
- *Orden de comprobaciones en la API*: respondía 503 (sin clave) antes de validar la
  imagen. Ahora valida primero, para que el usuario sepa siempre si el problema es su
  imagen. Hay una prueba de regresión en `test_recognitions_api.py`.
- *Compilación Android*: `permission_handler` 13.0.2 incorpora `permission_handler_android`
  14.1.0, que exige el Android Gradle Plugin 9. Se fijó `permission_handler` 12.0.1
  (implementación Android 13.0.1), con la misma API.

**Limitaciones**:
- No se probó contra Google Cloud Vision real porque no hay una clave configurada en este
  equipo. La calidad del reconocimiento (SC-010) y su evidencia siguen pendientes
  (CHK012).
- Quedan para la validación manual de [quickstart.md](quickstart.md) (§5): la
  sobrescritura en el diálogo de guardado (H1-E11), la cámara real (Historia 2) y el
  tiempo de 60 s con una red real (SC-009).
- En el emulador de depuración, con 2 GB de RAM, la app tardó unos 33 s en abrirse. Ese
  tiempo no representa el de una compilación release.

## Registro de verificación de la fase 7 (T058 a T060, 2026-10-29)

- `pytest`: 10 pruebas nuevas de `test_ocr_quality.py` superadas, entre ellas:
  - métricas;
  - alineación de palabras;
  - informe sin texto;
  - consentimiento obligatorio.

  Backend completo: 155 superadas. `ruff` sin problemas.
- Se ejecutó la herramienta sin `--acepto-enviar` y sin clave: explica qué falta y no
  envía nada.
- **T061 sigue pendiente**: necesita la clave de Google y al menos 10 hojas reales del
  responsable del proyecto. Guía en [quickstart.md](quickstart.md), §6.
