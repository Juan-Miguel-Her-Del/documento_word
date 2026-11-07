---

description: "Tareas de la funcionalidad 003: revisión asistida, recorte y compartir"
---

# Tasks: Revisión asistida, recorte y compartir

**Input**: [plan.md](plan.md), [spec.md](spec.md), [research.md](research.md),
[data-model.md](data-model.md), [contracts/recognition-api.md](contracts/recognition-api.md)

**Tests**: incluidas, porque la constitución §6 exige pruebas de OCR, persistencia e
integraciones. Los identificadores siguen desde T201.

## Phase 1: Setup

- [X] T201 Dependencias image_cropper 12.2.1 y share_plus 12.0.2 en frontend/pubspec.yaml; UCropActivity en frontend/android/app/src/main/AndroidManifest.xml

## Phase 2: User Story 1 - Revisar las palabras dudosas (Priority: P1) 🎯

- [X] T202 [P] [US1] Pruebas de las posiciones y del adaptador en backend/tests/test_uncertain_words.py y backend/tests/test_google_vision_provider.py
- [X] T203 [US1] UncertainSpan y OcrResult.uncertain_spans en backend/app/services/ocr/base.py; umbral en backend/app/config.py
- [X] T204 [US1] Cálculo de posiciones en backend/app/services/ocr/uncertain_words.py y lectura de la seguridad en backend/app/services/ocr/google_vision.py
- [X] T205 [US1] Campo uncertain_words en backend/app/schemas.py y backend/app/api/recognitions.py, con su prueba en backend/tests/test_recognitions_api.py
- [X] T206 [P] [US1] Pruebas de conversión, validación y ajuste de marcas en frontend/test/services/uncertain_ranges_test.dart
- [X] T207 [US1] Conversión, validación y adjustRanges en frontend/lib/services/uncertain_ranges.dart; uncertainRanges en frontend/lib/models/recognition_result.dart y en el cliente de la API
- [X] T208 [US1] Borrador formato 2 en frontend/lib/services/draft_storage.dart, con pruebas en frontend/test/services/storage_test.dart
- [X] T209 [US1] Marcas en frontend/lib/state/document_flow_controller.dart (reconocer, editar, «Está bien», borrador), con pruebas del controlador
- [X] T210 [US1] ReviewTextController en frontend/lib/presentation/widgets/review_text_controller.dart y barra de revisión en frontend/lib/presentation/screens/editor_screen.dart, con pruebas de pantalla

## Phase 3: User Story 2 - Recortar y girar la imagen (Priority: P2)

- [X] T211 [US2] Servicio de recorte en frontend/lib/services/image_editor_service.dart (image_cropper con los colores Aurora)
- [X] T212 [US2] Recorte, validación y vuelta a la original en el controlador, con pruebas (servicio falso)
- [X] T213 [US2] Acciones «Recortar o girar» y «Usar la imagen original» en frontend/lib/presentation/screens/preview_screen.dart, con pruebas de pantalla

## Phase 4: User Story 3 - Compartir el documento (Priority: P3)

- [X] T214 [US3] Servicio de compartir en frontend/lib/services/share_service.dart (copia en handtext_share y share_plus)
- [X] T215 [US3] lastExport, acción «Compartir» y limpieza en el controlador y en frontend/lib/models/operation_status.dart, con pruebas (servicio falso)
- [X] T216 [US3] Botón «Compartir» en el aviso de éxito del editor, con prueba de pantalla

## Phase 5: Polish

- [X] T217 Conexión de los servicios reales en frontend/lib/main.dart y textos en frontend/lib/presentation/strings.dart
- [X] T218 Documentación: quickstart.md, README.md y MAPA_DEL_CODIGO.md
- [X] T219 Formateadores, analizadores, todas las pruebas, APK y recorrido en el emulador; registro de verificación al final de este archivo

## Dependencies & Execution Order

Setup → US1 → US2 → US3 → Polish. Las tres historias son independientes entre sí; US1
es la única que toca la API.

## Registro de verificación (T219, 2026-10-29)

Constitución §6, Entrega: verificaciones ejecutadas, resultados y limitaciones.

| Verificación | Comando | Resultado |
|--------------|---------|-----------|
| Estilo del backend | `ruff format --check .` y `ruff check .` | Sin problemas |
| Pruebas del backend | `pytest` | 145 superadas (17 nuevas: posiciones, adaptador de Vision y API) |
| Formato y analizador de la app | `dart format` y `flutter analyze` | Sin problemas |
| Pruebas de la app | `flutter test` | 184 superadas (47 nuevas); 9 omitidas (contrato, requieren `HANDTEXT_API_URL`) |
| Compilación Android | `flutter build apk --debug` | `app-debug.apk` generado con image_cropper y share_plus |
| Recorrido en el emulador (Android 16, API 36) | APK instalado, API con PostgreSQL temporal | Ver detalle abajo |

**Recorrido en el emulador**:
- **Palabras dudosas**: un borrador en formato 2 con 3 marcas se recuperó con las 3
  palabras resaltadas (fondo ámbar y subrayado ondulado) y la barra «3 palabras para
  revisar» [EX-H1-E1] [EX-H1-E7].
  - «Siguiente» seleccionó «célula» [EX-H1-E3].
  - «Está bien» quitó su marca, el contador bajó a 2 y el texto no cambió [EX-H1-E5].
- **Borrador anterior**: un borrador de texto plano (formato 1) se recuperó sin marcas y
  sin barra de revisión [EX-H1-E9].
- **Recorte**:
  - «Recortar o girar» abrió uCrop con la barra azul marino y el título «Recortar y
    girar» [EX-H2-E1].
  - Un giro de 90° con recorte dejó un JPEG de 900 × 675 px y 21 KB [EX-H2-E2].
  - «Usar la imagen original» volvió a 1200 × 900 px [EX-H2-E5].
  - Salir del editor con el gesto «atrás» no cambió la imagen [EX-H2-E3].
  - La foto de la galería conservó el mismo MD5 [EX-H2-E7].
- **Compartir**:
  - Después de guardar el PDF, el aviso ofreció «Compartir», que abrió el selector de
    Android con `HandText_20261029_0358.pdf` [EX-H3-E1] [EX-H3-E2].
  - El archivo compartido y el guardado en Descargas tienen el mismo MD5 [SC-305].
- **Limpieza**: al cerrar sesión no quedó nada en la caché ni en los archivos privados:
  ni copias de trabajo, ni copias para compartir, ni borrador [EX-H3-E5] [SC-304].

**Incidencias resueltas durante la verificación**:
- *Copia de share_plus*: share_plus guarda su propia copia del archivo en
  `<caché>/share_plus/` hasta el próximo envío. La limpieza solo borraba la carpeta propia.
  Ahora `purge` borra las dos y la copia propia se borra al cerrar el selector. Hay una
  prueba de regresión en `storage_test.dart` y la R8 de research.md quedó actualizada.
- *«Usar la imagen original» en tres líneas*: compartía la fila con un `Spacer`. Ahora
  ocupa todo el espacio libre y cabe en una línea.
- *Compilación*: la primera compilación falló porque no se pudo resolver `jitpack.io`
  (red intermitente, el mismo caso de 001). Al repetirla funcionó.

**Limitaciones**:
- Sin clave de Google Cloud Vision, las marcas de un reconocimiento real no se vieron en
  el emulador. La lectura de la seguridad y las posiciones están probadas con respuestas
  simuladas de Vision, y la pantalla, con un borrador real.
- uCrop muestra algunos textos del sistema en inglés («Crop», «Rotate»), como prevé el
  supuesto 3 del spec.
- image_picker (001) deja una carpeta vacía en la caché por cada selección. No contiene
  datos.
- Al seleccionar la última palabra de una línea, Android pinta la selección hasta el
  borde; la selección real es solo la palabra (comprobado con «Está bien»).
- Siguen pendientes CHK309 (supuestos) y CHK310 (aprobación del alcance).
