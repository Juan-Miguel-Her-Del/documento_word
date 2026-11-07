# Mapa del código — HandText AI

Sirve para responder en segundos «¿dónde está el código de…?». Relaciona cada parte de los
specs ([001 — MVP](specs/001-handtext-mvp/spec.md) y
[002 — cuentas y diseño Aurora](specs/002-cuentas-de-usuario/spec.md) y
[003 — palabras dudosas, recorte y compartir](specs/003-revision-recorte-compartir/spec.md) y
[004 — varias páginas](specs/004-varias-paginas/spec.md) y
[005 — ajustes y versión final](specs/005-ajustes-y-version-final/spec.md) y
[006 — primer uso y accesibilidad](specs/006-primer-uso-y-accesibilidad/spec.md) y
[007 — historial de documentos](specs/007-historial-de-documentos/spec.md) y
[008 — app en inglés](specs/008-idioma-ingles/spec.md),
[009 — escáner](specs/009-escaner-de-documentos/spec.md),
[010 — organizar documentos](specs/010-organizar-documentos/spec.md),
[011 — bloqueo con huella](specs/011-bloqueo-con-huella/spec.md) y
[012 — pruebas de punta a punta](specs/012-pruebas-de-punta-a-punta/spec.md))
y de la
[constitución](.specify/memory/constitution.md) con el código que la cumple y con la
prueba que lo verifica.

## Cómo buscar

1. **Etiquetas**: cada escenario tiene una etiqueta.
   - `[H1-E9]` = spec 001, Historia 1, escenario 9.
   - `[CU-H1-E2]` = spec 002 (Cuentas de Usuario), Historia 1, escenario 2.
   - `[EX-H1-E4]` = spec 003 (EXtras), Historia 1, escenario 4.
   - `[VP-H3-E2]` = spec 004 (Varias Páginas), Historia 3, escenario 2.
   - `[AV-H1-E2]` = spec 005 (Ajustes y Versión), Historia 1, escenario 2.
   - `[PA-H2-E3]` = spec 006 (Primer uso y Accesibilidad), Historia 2, escenario 3.
   - `[HD-H1-E2]` = spec 007 (Historial de Documentos), Historia 1, escenario 2.
   - `[IE-H1-E2]` = spec 008 (Idioma Inglés), Historia 1, escenario 2.
   - `[ED-…]` = 009 (Escáner de Documentos), `[OR-…]` = 010 (ORganizar),
     `[BL-…]` = 011 (BLoqueo) y `[PP-…]` = 012 (Punta a Punta).
   - `[SC-007]`, `[SC-201]` … `[SC-1201]` = criterios de éxito de 001 a 012.
2. En VS Code, pulse **Ctrl+Shift+F** y escriba la etiqueta (por ejemplo `CU-H1-E8`).
   Aparece en el código que la cumple y en la prueba que la verifica.
3. **Cabeceras**: cada archivo empieza con un comentario que dice qué hace, qué parte del
   spec cumple y qué tarea implementa (T0xx en 001, T1xx en 002, T2xx en 003, T3xx en
   004, T4xx en 005, T5xx en 006, T6xx en 007, T7xx en 008, T8xx en 009, T9xx en
   010, T10xx en 011 y T11xx en 012).

Los números de línea son orientativos: si el código cambia, la etiqueta sigue siendo la
referencia estable.

## Recorrido completo: de abrir la app a guardar el Word

1. **Arranque**: [main.dart](frontend/lib/main.dart) arma los servicios.
   [app.dart](frontend/lib/app.dart) inicia la sesión y
   [app_root.dart](frontend/lib/presentation/screens/app_root.dart) decide qué mostrar.
2. **Sin sesión**: bienvenida, ingreso y registro
   ([auth/](frontend/lib/presentation/screens/auth/)). El
   [controlador de sesión](frontend/lib/state/auth_controller.dart) llama a
   [`/auth/...`](backend/app/api/auth.py), que usa el
   [servicio de cuentas](backend/app/services/accounts/account_service.py) y
   [PostgreSQL](backend/app/persistence/postgres_store.py).
3. **Inicio**: [start_screen.dart](frontend/lib/presentation/screens/start_screen.dart),
   con el saludo y el menú de cuenta. «Elegir imagen guardada» llama a `pickFromGallery()`.
4. **Selección**: [document_flow_controller.dart:294](frontend/lib/state/document_flow_controller.dart#L294)
   (`_pickImage`).
   - Pide el permiso de cámara, si hace falta.
   - Crea una [copia de trabajo](frontend/lib/services/working_copy_service.dart).
   - La [valida](frontend/lib/services/image_rules.dart).
5. **Vista previa**: [preview_screen.dart](frontend/lib/presentation/screens/preview_screen.dart).
   Pide la [autorización](frontend/lib/presentation/widgets/consent_dialog.dart) y llama
   a `recognize()`.
6. **Envío con sesión**: [handtext_api_client.dart:59](frontend/lib/services/handtext_api_client.dart#L59)
   llama a `POST /api/v1/recognitions` con `Authorization: Bearer`. En el servidor,
   [recognitions.py:58](backend/app/api/recognitions.py#L58) exige la sesión,
   [valida](backend/app/services/image_validation.py) y
   [prepara](backend/app/services/image_preparation.py) la imagen, y llama a
   [Google Cloud Vision](backend/app/services/ocr/google_vision.py).
7. **Editor**: [editor_screen.dart](frontend/lib/presentation/screens/editor_screen.dart).
   El borrador se guarda en el [archivo de esa cuenta](frontend/lib/services/draft_storage.dart).
8. **Exportación**:
   - [export()](frontend/lib/state/document_flow_controller.dart#L684) llama a
     [`/api/v1/exports`](backend/app/api/exports.py).
   - [export_service.py](backend/app/services/documents/export_service.py) elige
     [Word](backend/app/services/documents/docx_builder.py) o
     [PDF](backend/app/services/documents/pdf_builder.py).
   - El archivo se guarda con el [diálogo de Android](frontend/lib/services/file_save_service.dart).

## Spec 001 — MVP

### Historia 1 — Imagen guardada → Word (P1)

| Escenario | Qué pide el spec | Código | Prueba |
|-----------|------------------|--------|--------|
| H1-E1 | Rechazar imágenes inválidas indicando el motivo | App: [image_rules.dart:62](frontend/lib/services/image_rules.dart#L62). API: [image_validation.py:54](backend/app/services/image_validation.py#L54) | [image_rules_test.dart](frontend/test/services/image_rules_test.dart), [test_image_validation.py](backend/tests/test_image_validation.py) |
| H1-E2 | Vista previa: aceptar, reemplazar o cancelar | [preview_screen.dart](frontend/lib/presentation/screens/preview_screen.dart); `replaceImage` [L289](frontend/lib/state/document_flow_controller.dart#L289) y `cancelPreview` [L457](frontend/lib/state/document_flow_controller.dart#L457) | [document_flow_controller_test.dart](frontend/test/state/document_flow_controller_test.dart) |
| H1-E3 | Informar el envío y pedir autorización | [consent_dialog.dart:15](frontend/lib/presentation/widgets/consent_dialog.dart#L15); [preview_screen.dart:42](frontend/lib/presentation/screens/preview_screen.dart#L42) | [flow_screen_test.dart](frontend/test/presentation/flow_screen_test.dart) |
| H1-E4 | Sin autorización no se envía nada | [document_flow_controller.dart:530](frontend/lib/state/document_flow_controller.dart#L530) | controlador y pantallas |
| H1-E5 | Mostrar el proceso y no duplicar operaciones | `isBusy` [L217](frontend/lib/state/document_flow_controller.dart#L217) y botones inactivos | controlador |
| H1-E6 | Texto en el editor con advertencia | [document_flow_controller.dart:575](frontend/lib/state/document_flow_controller.dart#L575); [editor_screen.dart:472](frontend/lib/presentation/screens/editor_screen.dart#L472) | controlador y pantallas |
| H1-E7 | Sin texto: aviso y otra imagen | API: [recognitions.py:84](backend/app/api/recognitions.py#L84). App: [L561](frontend/lib/state/document_flow_controller.dart#L561) | [test_recognitions_api.py](backend/tests/test_recognitions_api.py), controlador |
| H1-E8 | Distinguir conexión, tiempo y error del servicio; reintentar | [google_vision.py:61](backend/app/services/ocr/google_vision.py#L61); [api_errors.dart:39](frontend/lib/services/api_errors.dart#L39); [L585](frontend/lib/state/document_flow_controller.dart#L585) | [test_google_vision_provider.py](backend/tests/test_google_vision_provider.py), [handtext_api_client_test.dart](frontend/test/services/handtext_api_client_test.dart) |
| H1-E9 | Exportar el texto actual del editor | [document_flow_controller.dart:684](frontend/lib/state/document_flow_controller.dart#L684) | controlador y pantallas |
| H1-E10 | No exportar texto vacío | App: [L690](frontend/lib/state/document_flow_controller.dart#L690). API: [text_rules.py:29](backend/app/services/documents/text_rules.py#L29) | controlador y [test_exports_docx.py](backend/tests/test_exports_docx.py) |
| H1-E11 | No sobrescribir sin confirmación | [file_save_service.dart:40](frontend/lib/services/file_save_service.dart#L40) (diálogo de Android) | manual ([quickstart 001](specs/001-handtext-mvp/quickstart.md), §5) |
| H1-E12 | Un fallo no es éxito y no borra el texto | [document_flow_controller.dart:746](frontend/lib/state/document_flow_controller.dart#L746) | controlador |
| H1-E13 | Otra imagen con confirmación; un fallo conserva las correcciones | [editor_screen.dart:132](frontend/lib/presentation/screens/editor_screen.dart#L132); [L648](frontend/lib/state/document_flow_controller.dart#L648) | controlador y pantallas |
| H1-E14 | El original no se modifica | [working_copy_service.dart:45](frontend/lib/services/working_copy_service.dart#L45); [image_preparation.py:27](backend/app/services/image_preparation.py#L27) | [storage_test.dart](frontend/test/services/storage_test.dart), [test_image_preparation.py](backend/tests/test_image_preparation.py) |
| H1-E15 | Recuperar el texto si Android cierra la app | [initialize L235](frontend/lib/state/document_flow_controller.dart#L235); [flow_screen.dart:48](frontend/lib/presentation/screens/flow_screen.dart#L48) | controlador, pantallas y almacenamiento |
| H1-E16 | Eliminar el borrador tras exportar | [document_flow_controller.dart:734](frontend/lib/state/document_flow_controller.dart#L734) | controlador |
| H1-E17 | Descartar con confirmación | [editor_screen.dart:142](frontend/lib/presentation/screens/editor_screen.dart#L142); [L665](frontend/lib/state/document_flow_controller.dart#L665) | controlador y pantallas |

### Historias 2 y 3 — Cámara (P2) y PDF (P3)

| Escenario | Qué pide el spec | Código | Prueba |
|-----------|------------------|--------|--------|
| H2-E1 / H2-E2 | Pedir el permiso de cámara; si se niega, explicar y volver | [camera_permission_service.dart:22](frontend/lib/services/camera_permission_service.dart#L22); [document_flow_controller.dart:313](frontend/lib/state/document_flow_controller.dart#L313) | [camera_flow_test.dart](frontend/test/state/camera_flow_test.dart) |
| H2-E3 / H2-E4 | Repetir la captura; continuar con el flujo | `replaceImage` [L289](frontend/lib/state/document_flow_controller.dart#L289) | cámara |
| H2-E5 | Sin texto: repetir la captura | [L561](frontend/lib/state/document_flow_controller.dart#L561) | cámara |
| H3-E1 | Elegir entre Word y PDF | [export_format_sheet.dart:12](frontend/lib/presentation/widgets/export_format_sheet.dart#L12) | pantallas |
| H3-E2 | PDF real, completo y con todos los caracteres | [pdf_builder.py:50](backend/app/services/documents/pdf_builder.py#L50) | [test_exports_pdf.py](backend/tests/test_exports_pdf.py) |

### Criterios de éxito de 001

| Criterio | Código | Prueba |
|----------|--------|--------|
| SC-001 Formato real = extensión | [export_service.py:43](backend/app/services/documents/export_service.py#L43); [export_format.dart:50](frontend/lib/models/export_format.dart#L50) | exportación y [api_contract_test.dart](frontend/test/integration/api_contract_test.dart) |
| SC-002 Orden, caracteres y párrafos | [text_rules.py:39](backend/app/services/documents/text_rules.py#L39); [docx_builder.py:26](backend/app/services/documents/docx_builder.py#L26) | exportación Word y PDF |
| SC-003 Un fallo nunca es éxito | controlador; [errors.py](backend/app/errors.py) | controlador, [test_errors_and_privacy.py](backend/tests/test_errors_and_privacy.py) |
| SC-004 Nada sale sin autorización | [document_flow_controller.dart:530](frontend/lib/state/document_flow_controller.dart#L530) | controlador y pantallas |
| SC-005 Registros sin contenido ni credenciales | [main.py:112](backend/app/main.py#L112); [errors.py:163](backend/app/errors.py#L163); [google_vision.py:72](backend/app/services/ocr/google_vision.py#L72) | [test_errors_and_privacy.py](backend/tests/test_errors_and_privacy.py) |
| SC-006 El original queda idéntico | copias de trabajo y preparación en memoria | almacenamiento y preparación |
| SC-007 No exportar texto vacío | [L690](frontend/lib/state/document_flow_controller.dart#L690); [text_rules.py:29](backend/app/services/documents/text_rules.py#L29) | controlador y exportación |
| SC-008 Una sola operación a la vez | `isBusy` [L217](frontend/lib/state/document_flow_controller.dart#L217) | controlador |
| SC-009 ≤ 60 s | [app_config.dart](frontend/lib/config/app_config.dart); [config.py](backend/app/config.py) | cliente HTTP y proveedor |
| SC-010 Calidad mínima | **Pendiente de definición** | — |
| SC-011 Sin borrador tras exportar o descartar | [L734](frontend/lib/state/document_flow_controller.dart#L734) | controlador y pantallas |

## Spec 002 — Cuentas de usuario y diseño Aurora

### Historia 1 — Crear una cuenta e ingresar (P1)

| Escenario | Qué pide el spec | Código | Prueba |
|-----------|------------------|--------|--------|
| CU-H1-E1 | Bienvenida sin sesión | [welcome_screen.dart:26](frontend/lib/presentation/screens/auth/welcome_screen.dart#L26); [app_root.dart](frontend/lib/presentation/screens/app_root.dart) | [auth_screens_test.dart](frontend/test/presentation/auth_screens_test.dart) |
| CU-H1-E2 | Registrarse e ingresar | API: [account_service.py:50](backend/app/services/accounts/account_service.py#L50), [auth.py:103](backend/app/api/auth.py#L103). App: [register_screen.dart:54](frontend/lib/presentation/screens/auth/register_screen.dart#L54), [auth_controller.dart:89](frontend/lib/state/auth_controller.dart#L89) | [test_auth_api.py](backend/tests/test_auth_api.py), pantallas |
| CU-H1-E3 | Correo único sin distinguir mayúsculas | `UNIQUE` en [0001_users_and_sessions.sql](db/migrations/0001_users_and_sessions.sql); [postgres_store.py:69](backend/app/persistence/postgres_store.py#L69); [rules.py](backend/app/services/accounts/rules.py) | [test_user_store.py](backend/tests/test_user_store.py), [test_account_service.py](backend/tests/test_account_service.py) |
| CU-H1-E4 | Reglas de nombre, correo y contraseña | API: [rules.py:29](backend/app/services/accounts/rules.py#L29). App: [account_rules.dart:22](frontend/lib/services/account_rules.dart#L22) | [account_rules_test.dart](frontend/test/services/account_rules_test.dart), servicio |
| CU-H1-E5 | Autorización de datos obligatoria | [register_screen.dart:155](frontend/lib/presentation/screens/auth/register_screen.dart#L155); [account_service.py:50](backend/app/services/accounts/account_service.py#L50) | servicio, API y pantallas |
| CU-H1-E6 | Ingresar y saludar por el nombre | [account_service.py:71](backend/app/services/accounts/account_service.py#L71); [login_screen.dart:49](frontend/lib/presentation/screens/auth/login_screen.dart#L49); [start_screen.dart](frontend/lib/presentation/screens/start_screen.dart) | servicio y pantallas |
| CU-H1-E7 | Mismo mensaje para correo inexistente y contraseña mala | [account_service.py:71](backend/app/services/accounts/account_service.py#L71) (`verify_dummy` en [passwords.py:33](backend/app/services/accounts/passwords.py#L33)) | servicio y API |
| CU-H1-E8 | Bloqueo de 15 minutos tras 5 fallos | [account_service.py:71](backend/app/services/accounts/account_service.py#L71); [postgres_store.py:91](backend/app/persistence/postgres_store.py#L91); [config.py:47](backend/app/config.py#L47) | servicio (reloj falso), almacén y API |
| CU-H1-E9 | La sesión sigue abierta al volver | [session_store.dart:31](frontend/lib/services/session_store.dart#L31) (Android Keystore); [auth_controller.dart:54](frontend/lib/state/auth_controller.dart#L54); [auth.py:147](backend/app/api/auth.py#L147) | [auth_controller_test.dart](frontend/test/state/auth_controller_test.dart), pantallas |

### Historia 2 — Cerrar sesión y eliminar la cuenta (P2)

| Escenario | Qué pide el spec | Código | Prueba |
|-----------|------------------|--------|--------|
| CU-H2-E1 | Cerrar sesión (también en el servidor) | [auth_controller.dart:134](frontend/lib/state/auth_controller.dart#L134); [auth.py:139](backend/app/api/auth.py#L139) | controlador y API |
| CU-H2-E2 | Confirmar si hay texto sin exportar | [account_menu.dart:34](frontend/lib/presentation/widgets/account_menu.dart#L34); [clearLocalData L875](frontend/lib/state/document_flow_controller.dart#L875) | pantallas |
| CU-H2-E3 | Eliminar la cuenta con contraseña | [account_menu.dart:48](frontend/lib/presentation/widgets/account_menu.dart#L48); [auth_controller.dart:160](frontend/lib/state/auth_controller.dart#L160); [auth.py:158](backend/app/api/auth.py#L158); [postgres_store.py:139](backend/app/persistence/postgres_store.py#L139) | API, controlador y pantallas |
| CU-H2-E4 | Contraseña incorrecta: la cuenta se conserva | [account_service.py:104](backend/app/services/accounts/account_service.py#L104) | servicio, API y pantallas |
| CU-H2-E5 | Sesión vencida: ingresar de nuevo sin perder el texto | [auth.py:56](backend/app/api/auth.py#L56) (`require_user`); [L897](frontend/lib/state/document_flow_controller.dart#L897); [auth_controller.dart:188](frontend/lib/state/auth_controller.dart#L188) | API, controladores y pantallas |
| CU-H2-E6 | Nadie ve el borrador de otra persona | [draft_storage.dart:30](frontend/lib/services/draft_storage.dart#L30); [main.dart:102](frontend/lib/main.dart#L102); `SignedInScope` en [app_root.dart:74](frontend/lib/presentation/screens/app_root.dart#L74) | [storage_test.dart](frontend/test/services/storage_test.dart) |

### Historia 3 — Diseño Aurora (P3)

| Escenario | Qué pide el spec | Código | Prueba |
|-----------|------------------|--------|--------|
| CU-H3-E1 | Identidad visual común (paleta «azul corporativo») | Colores [aurora.dart:13](frontend/lib/theme/aurora.dart#L13); temas [app_theme.dart](frontend/lib/theme/app_theme.dart); [fondo](frontend/lib/presentation/widgets/aurora_background.dart), [tarjeta](frontend/lib/presentation/widgets/surface_card.dart), [botón](frontend/lib/presentation/widgets/primary_button.dart), [título](frontend/lib/presentation/widgets/brand_title.dart) y [logo-escáner](frontend/lib/presentation/widgets/scanner_logo.dart); arranque de Android en [colors.xml](frontend/android/app/src/main/res/values/colors.xml) | pantallas; recorrido en el emulador |
| CU-H3-E2 | Animación de escaneo mientras se reconoce | [scan_overlay.dart:11](frontend/lib/presentation/widgets/scan_overlay.dart#L11); [preview_screen.dart:200](frontend/lib/presentation/screens/preview_screen.dart#L200) | recorrido en el emulador |
| CU-H3-E3 | Respetar «quitar animaciones» | [motion.dart:10](frontend/lib/presentation/widgets/motion.dart#L10); [scanner_logo.dart:36](frontend/lib/presentation/widgets/scanner_logo.dart#L36), [scan_overlay.dart:28](frontend/lib/presentation/widgets/scan_overlay.dart#L28) | todas las pruebas de pantallas usan esa preferencia ([app_tester.dart](frontend/test/support/app_tester.dart)) |
| CU-H3-E4 | Modo oscuro | [app.dart:82](frontend/lib/app.dart#L82); [app_theme.dart](frontend/lib/theme/app_theme.dart) | manual ([quickstart 002](specs/002-cuentas-de-usuario/quickstart.md)) |

### Criterios de éxito de 002

| Criterio | Código | Prueba |
|----------|--------|--------|
| SC-201 Nada en texto plano | [passwords.py](backend/app/services/accounts/passwords.py) (Argon2id); [tokens.py:18](backend/app/services/accounts/tokens.py#L18) (SHA-256) | `test_database_never_stores_plain_passwords_or_tokens` en [test_user_store.py](backend/tests/test_user_store.py) |
| SC-202 Sin sesión no se reconoce ni exporta | `CurrentUser` en [recognitions.py:58](backend/app/api/recognitions.py#L58) y [exports.py](backend/app/api/exports.py); token en [main.dart:74](frontend/lib/main.dart#L74) | [test_auth_api.py](backend/tests/test_auth_api.py), contrato |
| SC-203 Mensaje idéntico | [errors.py:67](backend/app/errors.py#L67) (`INVALID_CREDENTIALS`) | servicio y API |
| SC-204 Bloqueo efectivo | [account_service.py:71](backend/app/services/accounts/account_service.py#L71) | servicio y API |
| SC-205 Nada queda al eliminar | `ON DELETE CASCADE` en [0001_users_and_sessions.sql](db/migrations/0001_users_and_sessions.sql) | almacén (PostgreSQL real) y API |
| SC-206 Borrador por persona | [draft_storage.dart:30](frontend/lib/services/draft_storage.dart#L30) | almacenamiento |
| SC-207 Animaciones reducidas | [motion.dart](frontend/lib/presentation/widgets/motion.dart) | pruebas de pantallas |
| SC-208 Contraste mínimo | Pares de colores en [aurora.dart](frontend/lib/theme/aurora.dart) | [aurora_contrast_test.dart](frontend/test/theme/aurora_contrast_test.dart) |

## Spec 003 — Palabras dudosas, recorte y compartir

### Historia 1 — Revisar las palabras dudosas (P1)

| Escenario | Qué exige | Código | Prueba |
|-----------|-----------|--------|--------|
| EX-H1-E1 / E2 | Marcar las palabras con seguridad menor al 80 % (no los signos sueltos) | API: [google_vision.py:131](backend/app/services/ocr/google_vision.py#L131) (lee la seguridad), [uncertain_words.py:20](backend/app/services/ocr/uncertain_words.py#L20) (posiciones), [recognitions.py:87](backend/app/api/recognitions.py#L87); umbral en [config.py:39](backend/app/config.py#L39). App: [uncertain_ranges.dart:18](frontend/lib/services/uncertain_ranges.dart#L18), [review_text_controller.dart:14](frontend/lib/presentation/widgets/review_text_controller.dart#L14) | [test_uncertain_words.py](backend/tests/test_uncertain_words.py), [test_google_vision_provider.py](backend/tests/test_google_vision_provider.py), [uncertain_ranges_test.dart](frontend/test/services/uncertain_ranges_test.dart) |
| EX-H1-E3 | «Siguiente» recorre las palabras | [editor_screen.dart:97](frontend/lib/presentation/screens/editor_screen.dart#L97); barra en [editor_screen.dart:392](frontend/lib/presentation/screens/editor_screen.dart#L392) | [extras_screens_test.dart](frontend/test/presentation/extras_screens_test.dart) |
| EX-H1-E4 | Corregir una palabra quita su marca; las demás se mueven con su palabra | [uncertain_ranges.dart:66](frontend/lib/services/uncertain_ranges.dart#L66) (`adjustRanges`); [document_flow_controller.dart:613](frontend/lib/state/document_flow_controller.dart#L613) | [uncertain_ranges_test.dart](frontend/test/services/uncertain_ranges_test.dart) (incluye 10 000 ediciones al azar), [extras_flow_test.dart](frontend/test/state/extras_flow_test.dart) |
| EX-H1-E5 | «Está bien» quita la marca sin cambiar el texto | [document_flow_controller.dart:635](frontend/lib/state/document_flow_controller.dart#L635) | controlador y pantallas |
| EX-H1-E6 | Las marcas no se exportan | [document_flow_controller.dart:704](frontend/lib/state/document_flow_controller.dart#L704) | [extras_flow_test.dart](frontend/test/state/extras_flow_test.dart) |
| EX-H1-E7 | El borrador guarda y recupera las marcas | [draft_storage.dart:60](frontend/lib/services/draft_storage.dart#L60) (formato 2); [document_flow_controller.dart:254](frontend/lib/state/document_flow_controller.dart#L254) | [storage_test.dart](frontend/test/services/storage_test.dart), controlador |

### Historia 2 — Recortar y girar la imagen (P2)

| Escenario | Qué exige | Código | Prueba |
|-----------|-----------|--------|--------|
| EX-H2-E1 | «Recortar o girar» abre el editor | [preview_screen.dart:284](frontend/lib/presentation/screens/preview_screen.dart#L284); uCrop en [image_editor_service.dart:29](frontend/lib/services/image_editor_service.dart#L29) | pantallas; recorrido en el emulador |
| EX-H2-E2 / E3 / E4 | Usar el recorte, cancelar sin cambios y rechazar uno de menos de 600 px | [document_flow_controller.dart:470](frontend/lib/state/document_flow_controller.dart#L470) | [extras_flow_test.dart](frontend/test/state/extras_flow_test.dart) |
| EX-H2-E5 | Volver a la imagen original | [document_flow_controller.dart:509](frontend/lib/state/document_flow_controller.dart#L509); botón en [preview_screen.dart:309](frontend/lib/presentation/screens/preview_screen.dart#L309) | controlador y pantallas |
| EX-H2-E6 / E7 | Se envía el recorte; el original no cambia | Ruta de la copia de trabajo en [image_editor_service.dart:29](frontend/lib/services/image_editor_service.dart#L29); [document_flow_controller.dart:909](frontend/lib/state/document_flow_controller.dart#L909) | controlador; MD5 de la galería en el recorrido |

### Historia 3 — Compartir el documento (P3)

| Escenario | Qué exige | Código | Prueba |
|-----------|-----------|--------|--------|
| EX-H3-E1 / E4 | «Compartir» solo después de guardar | [document_flow_controller.dart:715](frontend/lib/state/document_flow_controller.dart#L715); botón en [editor_screen.dart:286](frontend/lib/presentation/screens/editor_screen.dart#L286) | controlador y pantallas |
| EX-H3-E2 / E3 | Abrir el selector de Android con el mismo archivo y poder repetir | [document_flow_controller.dart:795](frontend/lib/state/document_flow_controller.dart#L795); [share_service.dart:54](frontend/lib/services/share_service.dart#L54) | [extras_flow_test.dart](frontend/test/state/extras_flow_test.dart) |
| EX-H3-E5 | Borrar las copias temporales (la propia y la de share_plus) | [share_service.dart:80](frontend/lib/services/share_service.dart#L80) | [storage_test.dart](frontend/test/services/storage_test.dart) |
| EX-H3-E6 | Después de editar no se comparte el archivo viejo | [document_flow_controller.dart:613](frontend/lib/state/document_flow_controller.dart#L613) | controlador |

### Criterios de éxito de 003

| Criterio | Dónde se cumple | Cómo se verifica |
|----------|-----------------|------------------|
| SC-301 Se marcan exactamente las palabras dudosas | [uncertain_words.py](backend/app/services/ocr/uncertain_words.py) | [test_uncertain_words.py](backend/tests/test_uncertain_words.py) |
| SC-302 Cada marca sigue sobre su palabra | [uncertain_ranges.dart](frontend/lib/services/uncertain_ranges.dart) | prueba de 10 000 ediciones al azar |
| SC-303 El archivo exportado no lleva marcas | [document_flow_controller.dart:704](frontend/lib/state/document_flow_controller.dart#L704) | controlador |
| SC-304 Recortar no toca el original ni deja copias | [document_flow_controller.dart:909](frontend/lib/state/document_flow_controller.dart#L909) | controlador; recorrido (MD5 y caché vacía al cerrar sesión) |
| SC-305 Se comparte el mismo archivo | [share_service.dart](frontend/lib/services/share_service.dart) | controlador; recorrido (MD5 idéntico) |
| SC-306 Marcas legibles sin depender del color | [aurora.dart:66](frontend/lib/theme/aurora.dart#L66) | [aurora_contrast_test.dart](frontend/test/theme/aurora_contrast_test.dart) |

## Spec 004 — Varias páginas por documento

### Historia 1 — Digitalizar varias hojas en un documento (P1)

| Escenario | Qué exige | Código | Prueba |
|-----------|-----------|--------|--------|
| VP-H1-E1 | Elegir varias imágenes de la galería | [document_flow_controller.dart:270](frontend/lib/state/document_flow_controller.dart#L270); [image_source_service.dart:44](frontend/lib/services/image_source_service.dart#L44); miniaturas en [page_strip.dart:15](frontend/lib/presentation/widgets/page_strip.dart#L15) | [pages_flow_test.dart](frontend/test/state/pages_flow_test.dart), [pages_screen_test.dart](frontend/test/presentation/pages_screen_test.dart) |
| VP-H1-E2 | «Agregar página» desde la cámara o la galería | [document_flow_controller.dart:284](frontend/lib/state/document_flow_controller.dart#L284); hoja en [preview_screen.dart:50](frontend/lib/presentation/screens/preview_screen.dart#L50) | controlador y pantallas |
| VP-H1-E3 | Una autorización que dice cuántas imágenes | [consent_dialog.dart:15](frontend/lib/presentation/widgets/consent_dialog.dart#L15) | [pages_screen_test.dart](frontend/test/presentation/pages_screen_test.dart) |
| VP-H1-E4 / E5 | Reconocer en orden, con avance, y unir el texto | [document_flow_controller.dart:539](frontend/lib/state/document_flow_controller.dart#L539); [page_join.dart:35](frontend/lib/services/page_join.dart#L35) | [pages_flow_test.dart](frontend/test/state/pages_flow_test.dart), [page_join_test.dart](frontend/test/services/page_join_test.dart) |
| VP-H1-E6 | Máximo 10 páginas | [app_config.dart:44](frontend/lib/config/app_config.dart#L44); [document_flow_controller.dart:304](frontend/lib/state/document_flow_controller.dart#L304) | controlador |
| VP-H1-E7 | Una imagen inválida no se agrega; las demás sí | [document_flow_controller.dart:294](frontend/lib/state/document_flow_controller.dart#L294) | controlador |

### Historia 2 — Organizar las páginas (P2)

| Escenario | Qué exige | Código | Prueba |
|-----------|-----------|--------|--------|
| VP-H2-E1 | Elegir una página | [document_flow_controller.dart:426](frontend/lib/state/document_flow_controller.dart#L426) | controlador y pantallas |
| VP-H2-E2 | Moverla antes o después | [document_flow_controller.dart:434](frontend/lib/state/document_flow_controller.dart#L434); botones en [preview_screen.dart:136](frontend/lib/presentation/screens/preview_screen.dart#L136) | controlador y pantallas |
| VP-H2-E3 / E5 | Quitarla (no con una sola página) | [document_flow_controller.dart:446](frontend/lib/state/document_flow_controller.dart#L446) | controlador y pantallas |
| VP-H2-E4 | Recortar o reemplazar solo la página elegida | `editImage` y `replaceImage` del controlador | controlador |

### Historia 3 — Fallos de una página (P3)

| Escenario | Qué exige | Código | Prueba |
|-----------|-----------|--------|--------|
| VP-H3-E1 | Decir qué página falló | [document_flow_controller.dart:593](frontend/lib/state/document_flow_controller.dart#L593) | [pages_flow_test.dart](frontend/test/state/pages_flow_test.dart) |
| VP-H3-E2 / E3 | Reintentar sin reenviar lo reconocido | [document_flow_controller.dart:543](frontend/lib/state/document_flow_controller.dart#L543) | controlador |
| VP-H3-E4 / E5 | Páginas sin texto | [page_join.dart:35](frontend/lib/services/page_join.dart#L35); [document_flow_controller.dart:559](frontend/lib/state/document_flow_controller.dart#L559) | `joinPages` y controlador |

### Criterios de éxito de 004

| Criterio | Dónde se cumple | Cómo se verifica |
|----------|-----------------|------------------|
| SC-401 Todas las páginas, en orden | [page_join.dart](frontend/lib/services/page_join.dart) | [page_join_test.dart](frontend/test/services/page_join_test.dart) |
| SC-402 Sin reenvíos | [document_flow_controller.dart:543](frontend/lib/state/document_flow_controller.dart#L543) | controlador |
| SC-403 Máximo 10 y sin copias | [document_flow_controller.dart:919](frontend/lib/state/document_flow_controller.dart#L919) | controlador; recorrido (copias 3 → 2 → 0) |
| SC-404 Marcas en su lugar | [page_join.dart](frontend/lib/services/page_join.dart) | `joinPages` y controlador |
| SC-405 60 s por página | Una solicitud por página (R3 de 004) | contrato de 001 |

## Medición de la calidad (SC-010 de 001) e ícono (002)

| Qué | Dónde | Prueba |
|-----|-------|--------|
| CER y WER con Levenshtein | [measure_ocr_quality.py:62](backend/tools/measure_ocr_quality.py#L62); por hoja en [measure_ocr_quality.py:139](backend/tools/measure_ocr_quality.py#L139) | [test_ocr_quality.py](backend/tests/test_ocr_quality.py) |
| Informe sin texto (privacidad) | [measure_ocr_quality.py:207](backend/tools/measure_ocr_quality.py#L207) | [test_ocr_quality.py](backend/tests/test_ocr_quality.py) |
| Sin `--acepto-enviar` no se envía nada | [measure_ocr_quality.py:268](backend/tools/measure_ocr_quality.py#L268) | [test_ocr_quality.py](backend/tests/test_ocr_quality.py) |
| Guía de la clave de Google | [quickstart de 001, §6](specs/001-handtext-mvp/quickstart.md) | — |
| Ícono de la app (logo-escáner) | Generador [generate_launcher_icon.py](frontend/tool/generate_launcher_icon.py); [ic_launcher.xml](frontend/android/app/src/main/res/mipmap-anydpi-v26/ic_launcher.xml) | recorrido en el emulador |

## Spec 005 — Ajustes, «Acerca de» y versión final

| Escenario | Qué exige | Código | Prueba |
|-----------|-----------|--------|--------|
| AV-H1-E1 | «Ajustes» y «Acerca de» en el menú de cuenta | [account_menu.dart:84](frontend/lib/presentation/widgets/account_menu.dart#L84) | [settings_screens_test.dart](frontend/test/presentation/settings_screens_test.dart) |
| AV-H1-E2 / E3 | Tema automático, claro u oscuro | [settings_screen.dart:25](frontend/lib/presentation/screens/settings_screen.dart#L25); [app.dart:82](frontend/lib/app.dart#L82) | pantallas |
| AV-H1-E4 | Letra del editor | [settings_screen.dart:304](frontend/lib/presentation/screens/settings_screen.dart#L304) (`editorTextStyle`) | pantallas |
| AV-H1-E5 / E6 | Ajustes guardados; valores por omisión si faltan | [settings_store.dart:63](frontend/lib/services/settings_store.dart#L63); [settings_store.dart:35](frontend/lib/services/settings_store.dart#L35); [settings_controller.dart:14](frontend/lib/state/settings_controller.dart#L14) | [settings_test.dart](frontend/test/state/settings_test.dart) |
| AV-H2-E1 | «Acerca de» sin sesión | [welcome_screen.dart:111](frontend/lib/presentation/screens/auth/welcome_screen.dart#L111) | pantallas |
| AV-H2-E2 | Logo, nombre y versión | [about_screen.dart:18](frontend/lib/presentation/screens/about_screen.dart#L18); [app_config.dart:12](frontend/lib/config/app_config.dart#L12) | [settings_test.dart](frontend/test/state/settings_test.dart) (contra pubspec.yaml) |
| AV-H2-E3 | Privacidad | [privacy_screen.dart:15](frontend/lib/presentation/screens/privacy_screen.dart#L15); textos en [strings_es.dart:136](frontend/lib/presentation/strings_es.dart#L136) | pantallas |
| AV-H2-E4 | Licencias, con Poppins | [font_licenses.dart:14](frontend/lib/presentation/font_licenses.dart#L14) | [settings_test.dart](frontend/test/state/settings_test.dart) |
| AV-H3-E1 | Firma con la clave del proyecto | [build.gradle.kts:23](frontend/android/app/build.gradle.kts#L23); [build.gradle.kts:76](frontend/android/app/build.gradle.kts#L76) | `apksigner verify` (registro de 005) |
| AV-H3-E2 / E3 | Solo HTTPS, salvo la demostración | [build.gradle.kts:86](frontend/android/app/build.gradle.kts#L86); [AndroidManifest.xml](frontend/android/app/src/main/AndroidManifest.xml) | `aapt2 dump` (registro de 005) |

## Spec 006 — Primer uso y accesibilidad

| Escenario | Qué exige | Código | Prueba |
|-----------|-----------|--------|--------|
| PA-H1-E1 / E4 | Consejos solo la primera vez en el teléfono | [app_root.dart:110](frontend/lib/presentation/screens/app_root.dart#L110); `tipsSeen` en [settings_store.dart:56](frontend/lib/services/settings_store.dart#L56) | [tips_screen_test.dart](frontend/test/presentation/tips_screen_test.dart); [settings_test.dart](frontend/test/state/settings_test.dart) |
| PA-H1-E2 | «Siguiente» y «Empezar» | [tips_screen.dart:64](frontend/lib/presentation/screens/tips_screen.dart#L64) | [tips_screen_test.dart](frontend/test/presentation/tips_screen_test.dart) |
| PA-H1-E3 | «Saltar» y el botón atrás | [tips_screen.dart:109](frontend/lib/presentation/screens/tips_screen.dart#L109); [app_root.dart:123](frontend/lib/presentation/screens/app_root.dart#L123) | [tips_screen_test.dart](frontend/test/presentation/tips_screen_test.dart) |
| PA-H1-E5 | Abrirlos desde el inicio y Ajustes | [tips_screen.dart:40](frontend/lib/presentation/screens/tips_screen.dart#L40); [start_screen.dart:147](frontend/lib/presentation/screens/start_screen.dart#L147); [settings_screen.dart:142](frontend/lib/presentation/screens/settings_screen.dart#L142) | [tips_screen_test.dart](frontend/test/presentation/tips_screen_test.dart) |
| PA-H2-E1 | Todo lo tocable tiene nombre; el avatar se lee «Cuenta» | [account_menu.dart:180](frontend/lib/presentation/widgets/account_menu.dart#L180) | [accessibility_test.dart](frontend/test/presentation/accessibility_test.dart) |
| PA-H2-E2 | Los avisos de estado se leen solos | [status_banner.dart:78](frontend/lib/presentation/widgets/status_banner.dart#L78) (desde 001) | [accessibility_test.dart](frontend/test/presentation/accessibility_test.dart) |
| PA-H2-E3 | «Siguiente» hace leer la palabra dudosa | [editor_screen.dart:111](frontend/lib/presentation/screens/editor_screen.dart#L111) | [accessibility_test.dart](frontend/test/presentation/accessibility_test.dart) |
| PA-H2-E4 | TalkBack lee «Consejo 2 de 4» y omite los dibujos | [tips_screen.dart:78](frontend/lib/presentation/screens/tips_screen.dart#L78) | [tips_screen_test.dart](frontend/test/presentation/tips_screen_test.dart) |
| PA-H2-E5 | Títulos como encabezados | [aurora_header.dart:34](frontend/lib/presentation/widgets/aurora_header.dart#L34); etiqueta `PA-H2-E5` en cada pantalla | [accessibility_test.dart](frontend/test/presentation/accessibility_test.dart) |
| PA-H3-E1 / E3 | Sin desbordes al 200 % y botones de 48 dp | [account_menu.dart:170](frontend/lib/presentation/widgets/account_menu.dart#L170); [account_menu.dart:223](frontend/lib/presentation/widgets/account_menu.dart#L223); [export_format_sheet.dart:16](frontend/lib/presentation/widgets/export_format_sheet.dart#L16) | [accessibility_test.dart](frontend/test/presentation/accessibility_test.dart) (todas las pantallas, al 100 % y al 200 %) |
| PA-H3-E1 | Opciones de Ajustes una debajo de otra si no caben | [settings_screen.dart:164](frontend/lib/presentation/screens/settings_screen.dart#L164) | [settings_screens_test.dart](frontend/test/presentation/settings_screens_test.dart) (con Poppins) |
| PA-H3-E2 | El editor conserva el texto con la letra grande | [editor_screen.dart:270](frontend/lib/presentation/screens/editor_screen.dart#L270); [editor_screen.dart:205](frontend/lib/presentation/screens/editor_screen.dart#L205) | [accessibility_test.dart](frontend/test/presentation/accessibility_test.dart) |

## Spec 007 — Historial de documentos

| Escenario | Qué exige | Código | Prueba |
|-----------|-----------|--------|--------|
| HD-H1-E1 / E3 | Solo un guardado correcto llega al historial | [document_flow_controller.dart:725](frontend/lib/state/document_flow_controller.dart#L725); [document_history.dart:52](frontend/lib/state/document_history.dart#L52) | [history_flow_test.dart](frontend/test/state/history_flow_test.dart) |
| HD-H1-E2 / H2-E3 | Volver a guardar actualiza la misma entrada | [document_history.dart:65](frontend/lib/state/document_history.dart#L65) | [history_flow_test.dart](frontend/test/state/history_flow_test.dart); [history_store_test.dart](frontend/test/services/history_store_test.dart) |
| HD-H1-E4 | «Mis documentos» desde el inicio; mensaje si está vacío | [start_screen.dart:153](frontend/lib/presentation/screens/start_screen.dart#L153); [history_screen.dart:29](frontend/lib/presentation/screens/history_screen.dart#L29) | [history_screen_test.dart](frontend/test/presentation/history_screen_test.dart) |
| HD-H1-E5 | Se conserva al cerrar la app y al cerrar sesión | [document_flow_controller.dart:243](frontend/lib/state/document_flow_controller.dart#L243); [history_store.dart:88](frontend/lib/services/history_store.dart#L88) | [history_store_test.dart](frontend/test/services/history_store_test.dart); [history_screen_test.dart](frontend/test/presentation/history_screen_test.dart) |
| HD-H1-E6 | Otra cuenta no lo ve | [history_store.dart:19](frontend/lib/services/history_store.dart#L19); [main.dart:115](frontend/lib/main.dart#L115) | [history_store_test.dart](frontend/test/services/history_store_test.dart) |
| HD-H2-E1 | Abrir un documento en el editor | [document_flow_controller.dart:774](frontend/lib/state/document_flow_controller.dart#L774); [history_screen.dart:55](frontend/lib/presentation/screens/history_screen.dart#L55) | [history_flow_test.dart](frontend/test/state/history_flow_test.dart); [history_screen_test.dart](frontend/test/presentation/history_screen_test.dart) |
| HD-H2-E2 | Confirmar si hay cambios sin exportar | [history_screen.dart:56](frontend/lib/presentation/screens/history_screen.dart#L56) | [history_screen_test.dart](frontend/test/presentation/history_screen_test.dart) |
| HD-H2-E4 | El borrador sigue unido a su entrada | [draft_storage.dart:55](frontend/lib/services/draft_storage.dart#L55); [document_flow_controller.dart:256](frontend/lib/state/document_flow_controller.dart#L256) | [history_flow_test.dart](frontend/test/state/history_flow_test.dart) |
| HD-H3-E1 / E2 / E3 | Eliminar uno o todos, con confirmación | [history_screen.dart:70](frontend/lib/presentation/screens/history_screen.dart#L70); [history_screen.dart:91](frontend/lib/presentation/screens/history_screen.dart#L91) | [history_screen_test.dart](frontend/test/presentation/history_screen_test.dart) |
| HD-H3-E4 | Eliminar la cuenta borra el historial | [account_menu.dart:56](frontend/lib/presentation/widgets/account_menu.dart#L56); [document_flow_controller.dart:887](frontend/lib/state/document_flow_controller.dart#L887) | [history_flow_test.dart](frontend/test/state/history_flow_test.dart); [history_screen_test.dart](frontend/test/presentation/history_screen_test.dart) |
| Límite y título | 50 documentos; primera línea, hasta 60 caracteres | [app_config.dart:47](frontend/lib/config/app_config.dart#L47); [history_entry.dart:80](frontend/lib/models/history_entry.dart#L80) | [history_store_test.dart](frontend/test/services/history_store_test.dart) |

## Spec 008 — App en inglés

| Escenario | Qué exige | Código | Prueba |
|-----------|-----------|--------|--------|
| SC-801 | Todo texto tiene su traducción (si falta, no compila) | Lista: [strings.dart:27](frontend/lib/presentation/strings.dart#L27); [strings_es.dart:14](frontend/lib/presentation/strings_es.dart#L14); [strings_en.dart:15](frontend/lib/presentation/strings_en.dart#L15) | compilación |
| IE-H1-E1 / E5 | Español al instalar y con ajustes anteriores | [app_settings.dart:30](frontend/lib/models/app_settings.dart#L30); [settings_store.dart:57](frontend/lib/services/settings_store.dart#L57) | [settings_test.dart](frontend/test/state/settings_test.dart); [language_test.dart](frontend/test/presentation/language_test.dart) |
| IE-H1-E2 | Elegir el idioma en Ajustes o en la bienvenida; cambia al instante | [settings_screen.dart:47](frontend/lib/presentation/screens/settings_screen.dart#L47); [language_sheet.dart:23](frontend/lib/presentation/widgets/language_sheet.dart#L23); [app.dart:88](frontend/lib/app.dart#L88) | [language_test.dart](frontend/test/presentation/language_test.dart) |
| IE-H1-E3 | «Automático»: inglés solo si el teléfono está en inglés | [app.dart:100](frontend/lib/app.dart#L100) | [language_test.dart](frontend/test/presentation/language_test.dart) |
| IE-H1-E4 | Se conserva al abrir la app | [settings_controller.dart:46](frontend/lib/state/settings_controller.dart#L46) | [settings_test.dart](frontend/test/state/settings_test.dart); [language_test.dart](frontend/test/presentation/language_test.dart) |
| IE-H2-E1 / E5 | Ninguna pantalla en español, también al 200 % | `context.strings` en cada pantalla; [strings.dart:45](frontend/lib/presentation/strings.dart#L45) | [language_test.dart](frontend/test/presentation/language_test.dart) (frases del español y letras ¿¡áéíóúñ) |
| IE-H2-E2 | Fallos explicados en inglés; el detalle en español de la API no se muestra | [strings_en.dart:703](frontend/lib/presentation/strings_en.dart#L703) | [language_test.dart](frontend/test/presentation/language_test.dart) |
| IE-H2-E3 | Títulos del diálogo para guardar y del recorte | [strings.dart:41](frontend/lib/presentation/strings.dart#L41); [main.dart:97](frontend/lib/main.dart#L97) | [language_test.dart](frontend/test/presentation/language_test.dart) |
| IE-H2-E4 | Fechas y tamaños en el formato de cada idioma | [strings_en.dart:297](frontend/lib/presentation/strings_en.dart#L297); [strings_en.dart:419](frontend/lib/presentation/strings_en.dart#L419) | [language_test.dart](frontend/test/presentation/language_test.dart) |
| IE-H3-E1 / E2 | El texto de la persona no cambia | Solo cambian los textos de la interfaz; el controlador no depende del idioma | [language_test.dart](frontend/test/presentation/language_test.dart) |

## Spec 009 — Escáner de documentos

| Escenario | Qué exige | Código | Prueba |
|-----------|-----------|--------|--------|
| ED-H1-E1 | «Escanear hoja», la primera opción del inicio | [start_screen.dart:118](frontend/lib/presentation/screens/start_screen.dart#L118) | [scanner_flow_test.dart](frontend/test/state/scanner_flow_test.dart) |
| ED-H1-E2 / E3 | Una o varias hojas, sin pasar de 10 | [document_flow_controller.dart:280](frontend/lib/state/document_flow_controller.dart#L280); [document_flow_controller.dart:334](frontend/lib/state/document_flow_controller.dart#L334) | [scanner_flow_test.dart](frontend/test/state/scanner_flow_test.dart) |
| ED-H1-E4 | «Escanear» al agregar página | [preview_screen.dart:58](frontend/lib/presentation/screens/preview_screen.dart#L58) | [scanner_flow_test.dart](frontend/test/state/scanner_flow_test.dart) |
| ED-H1-E5 / SC-903 | Cancelar no cambia nada | [document_scanner_service.dart:59](frontend/lib/services/document_scanner_service.dart#L59) | [scanner_flow_test.dart](frontend/test/state/scanner_flow_test.dart) |
| ED-H2-E1 / SC-904 | Sin escáner: aviso con «Tomar fotografía» | [document_flow_controller.dart:384](frontend/lib/state/document_flow_controller.dart#L384); [start_screen.dart:109](frontend/lib/presentation/screens/start_screen.dart#L109) | [scanner_flow_test.dart](frontend/test/state/scanner_flow_test.dart) |
| ED-H3-E1 | Copias de trabajo; los archivos del escáner se borran | [document_scanner_service.dart:55](frontend/lib/services/document_scanner_service.dart#L55) | [scanner_flow_test.dart](frontend/test/state/scanner_flow_test.dart) |
| R2 | Sin limpieza automática que borre trazos | [document_scanner_service.dart:39](frontend/lib/services/document_scanner_service.dart#L39) | revisión |

## Spec 010 — Organizar documentos

| Escenario | Qué exige | Código | Prueba |
|-----------|-----------|--------|--------|
| OR-H1-E1 a E3 / SC-1001 | El título como nombre del archivo, limpio y corto | [document_flow_controller.dart:73](frontend/lib/state/document_flow_controller.dart#L73); [document_flow_controller.dart:90](frontend/lib/state/document_flow_controller.dart#L90) | [file_name_test.dart](frontend/test/services/file_name_test.dart) |
| OR-H1-E4 | El nombre dado en Mis documentos | [document_flow_controller.dart:764](frontend/lib/state/document_flow_controller.dart#L764) | [organize_test.dart](frontend/test/presentation/organize_test.dart) |
| OR-H2-E1 / E2 / SC-1002 | «Copiar todo el texto», solo si hay texto | [editor_screen.dart:155](frontend/lib/presentation/screens/editor_screen.dart#L155) | [organize_test.dart](frontend/test/presentation/organize_test.dart) |
| OR-H3-E1 / E2 / SC-1003 | Buscar sin tildes ni mayúsculas | [history_entry.dart:51](frontend/lib/models/history_entry.dart#L51); [history_entry.dart:66](frontend/lib/models/history_entry.dart#L66); [history_screen.dart:129](frontend/lib/presentation/screens/history_screen.dart#L129) | [organize_test.dart](frontend/test/presentation/organize_test.dart) |
| OR-H3-E3 / E4 / SC-1004 | Renombrar; el nombre se conserva al volver a guardar | [document_history.dart:80](frontend/lib/state/document_history.dart#L80); [document_history.dart:60](frontend/lib/state/document_history.dart#L60); [history_screen.dart:261](frontend/lib/presentation/screens/history_screen.dart#L261) | [organize_test.dart](frontend/test/presentation/organize_test.dart) |

## Spec 011 — Bloqueo con huella o rostro

| Escenario | Qué exige | Código | Prueba |
|-----------|-----------|--------|--------|
| BL-H1-E1 / SC-1104 | Apagado por omisión | [app_settings.dart:31](frontend/lib/models/app_settings.dart#L31) | [app_lock_test.dart](frontend/test/presentation/app_lock_test.dart) |
| BL-H1-E2 / E3 | Activarlo solo con una verificación correcta | [app_lock_controller.dart:109](frontend/lib/state/app_lock_controller.dart#L109) | [app_lock_test.dart](frontend/test/presentation/app_lock_test.dart) |
| BL-H1-E4 | Teléfono sin cómo verificar | [settings_screen.dart:249](frontend/lib/presentation/screens/settings_screen.dart#L249); [device_authenticator.dart:29](frontend/lib/services/device_authenticator.dart#L29) | [app_lock_test.dart](frontend/test/presentation/app_lock_test.dart) |
| BL-H2-E1 / SC-1101 | Abre bloqueada y no se ve ningún documento | [lock_screen.dart:35](frontend/lib/presentation/screens/lock_screen.dart#L35); [app.dart:107](frontend/lib/app.dart#L107) | [app_lock_test.dart](frontend/test/presentation/app_lock_test.dart) |
| BL-H2-E2 / E3 / SC-1102 / SC-1103 | Desbloquear conserva todo; cancelar sigue bloqueada | [app_lock_controller.dart:94](frontend/lib/state/app_lock_controller.dart#L94) | [app_lock_test.dart](frontend/test/presentation/app_lock_test.dart) |
| BL-H2-E4 | Más de 1 minuto en segundo plano | [app_lock_controller.dart:75](frontend/lib/state/app_lock_controller.dart#L75) | [app_lock_test.dart](frontend/test/presentation/app_lock_test.dart) |
| BL-H2-E5 | Sin sesión no se bloquea | [app_lock_controller.dart:68](frontend/lib/state/app_lock_controller.dart#L68) | [app_lock_test.dart](frontend/test/presentation/app_lock_test.dart) |
| BL-H3-E1 | Desactivarlo | [app_lock_controller.dart:122](frontend/lib/state/app_lock_controller.dart#L122) | [app_lock_test.dart](frontend/test/presentation/app_lock_test.dart) |
| R1 | FragmentActivity y temas AppCompat para local_auth | [MainActivity.kt](frontend/android/app/src/main/kotlin/com/handtextai/handtext_ai/MainActivity.kt); [styles.xml](frontend/android/app/src/main/res/values/styles.xml) | recorrido en el emulador |

## Spec 012 — Pruebas de punta a punta

| Escenario | Qué exige | Código | Prueba |
|-----------|-----------|--------|--------|
| PP-H1-E1 a E4, PP-H2-E1 | De la cuenta al Word real, y volver a encontrarlo | [flujo_completo_test.dart](frontend/integration_test/flujo_completo_test.dart) | se ejecuta en el emulador ([quickstart](specs/012-pruebas-de-punta-a-punta/quickstart.md)) |
| SC-1202 | El archivo es un .docx real con el texto corregido | [flujo_completo_test.dart:305](frontend/integration_test/flujo_completo_test.dart#L305) | la misma |

## Constitución → código

| Regla | Dónde se cumple |
|-------|-----------------|
| §2 Secretos solo en el backend | `HANDTEXT_GOOGLE_VISION_API_KEY` y `HANDTEXT_DATABASE_URL` en [config.py:61](backend/app/config.py#L61) |
| §2 PostgreSQL con consultas parametrizadas | [postgres_store.py:35](backend/app/persistence/postgres_store.py#L35); migraciones SQL en [db/](db/) |
| §2 OCR encapsulado | Contrato [base.py:60](backend/app/services/ocr/base.py#L60); [google_vision.py](backend/app/services/ocr/google_vision.py) |
| §2 Generación de archivos como servicio | [backend/app/services/documents/](backend/app/services/documents/) |
| §3 Acceso: autenticar cada solicitud | `require_user` en [auth.py:56](backend/app/api/auth.py#L56) |
| §3 Privacidad | Argon2id, tokens con hash, almacenamiento seguro, sin copias de seguridad ([AndroidManifest.xml](frontend/android/app/src/main/AndroidManifest.xml)) |
| §4 Capas separadas | App: `models/`, `services/`, `state/`, `presentation/` y `theme/`. API: `api/`, `services/` y `persistence/` |
| §5 Errores con código, mensaje y request_id | [errors.py:67](backend/app/errors.py#L67); [contracts](specs/001-handtext-mvp/contracts/api.md) |
| §5 Mensajes claros, en español e inglés | Lista en [strings.dart](frontend/lib/presentation/strings.dart); textos en [strings_es.dart](frontend/lib/presentation/strings_es.dart) y [strings_en.dart](frontend/lib/presentation/strings_en.dart) |
| §6 Pruebas automatizadas | [backend/tests/](backend/tests/) y [frontend/test/](frontend/test/) |

## Preguntas rápidas

- **¿Dónde se valida el usuario y la contraseña?**
  - El ingreso está en `login` de
    [account_service.py:71](backend/app/services/accounts/account_service.py#L71).
  - La contraseña se compara con Argon2id en
    [passwords.py](backend/app/services/accounts/passwords.py).
- **¿Cómo se guardan las contraseñas?**
  - Solo como hash Argon2id, nunca en texto plano.
  - Los tokens se guardan como SHA-256 ([tokens.py](backend/app/services/accounts/tokens.py)).
- **¿Dónde se protege la API?**
  - Con `require_user` / `CurrentUser` en [auth.py:56](backend/app/api/auth.py#L56).
  - Sin token válido, la respuesta es 401.
- **¿Dónde guarda la app la sesión?**
  - En el almacenamiento seguro de Android (Keystore):
    [session_store.dart](frontend/lib/services/session_store.dart).
- **¿Dónde están las tablas?**
  - En [db/migrations/0001_users_and_sessions.sql](db/migrations/0001_users_and_sessions.sql).
- **¿Dónde se llama a la inteligencia artificial?**
  - En `recognize` de [google_vision.py:61](backend/app/services/ocr/google_vision.py#L61).
- **¿Dónde se define el diseño?**
  - En [aurora.dart](frontend/lib/theme/aurora.dart) (colores de la paleta «azul corporativo»).
  - En [app_theme.dart](frontend/lib/theme/app_theme.dart) (temas).
  - En los widgets de [presentation/widgets/](frontend/lib/presentation/widgets/).
- **¿Cómo se hizo el logo animado?**
  - Con `CustomPainter`, sin imágenes:
    [scanner_logo.dart:63](frontend/lib/presentation/widgets/scanner_logo.dart#L63).
- **¿Dónde se genera el Word?**
  - En [docx_builder.py:26](backend/app/services/documents/docx_builder.py#L26).
- **¿Y el PDF?**
  - En [pdf_builder.py:50](backend/app/services/documents/pdf_builder.py#L50).
- **¿Cómo se evita enviar dos veces?**
  - Con `isBusy` en los dos controladores.
  - Con los botones desactivados mientras hay una operación en curso.
- **¿Dónde están todos los textos?**
  - La lista, en [strings.dart](frontend/lib/presentation/strings.dart).
  - En español, en [strings_es.dart](frontend/lib/presentation/strings_es.dart).
  - En inglés, en [strings_en.dart](frontend/lib/presentation/strings_en.dart) (spec 008).
