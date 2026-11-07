---

description: "Tareas de la funcionalidad 005: ajustes, «Acerca de» y versión final"
---

# Tasks: Ajustes, «Acerca de» y versión final

**Input**: [plan.md](plan.md), [spec.md](spec.md), [research.md](research.md)

**Tests**: incluidas (constitución §6). Los identificadores siguen desde T401.

## Phase 1: User Story 1 - Ajustar la app (Priority: P1) 🎯

- [X] T401 [P] [US1] Pruebas del almacén y del controlador de ajustes en frontend/test/state/settings_test.dart
- [X] T402 [US1] AppSettings en frontend/lib/models/app_settings.dart, almacén en frontend/lib/services/settings_store.dart y controlador en frontend/lib/state/settings_controller.dart
- [X] T403 [US1] SettingsScope, themeMode en frontend/lib/app.dart y conexión en frontend/lib/main.dart
- [X] T404 [US1] Pantalla de Ajustes en frontend/lib/presentation/screens/settings_screen.dart y tamaño de letra en el editor
- [X] T405 [US1] «Ajustes» y «Acerca de» en el menú de cuenta (frontend/lib/presentation/widgets/account_menu.dart), con pruebas de pantalla

## Phase 2: User Story 2 - Conocer la app (Priority: P2)

- [X] T406 [P] [US2] Prueba de la versión contra pubspec.yaml y pruebas de pantalla de «Acerca de»
- [X] T407 [US2] appVersion y appBuild en frontend/lib/config/app_config.dart; pantallas «Acerca de» y Privacidad; licencia de Poppins registrada en frontend/lib/main.dart
- [X] T408 [US2] Enlace «Privacidad y acerca de» en la bienvenida

## Phase 3: User Story 3 - Versión final (Priority: P3)

- [X] T409 [US3] Firma con key.properties y HTTP según el tipo de compilación en frontend/android/app/build.gradle.kts y en el manifiesto
- [X] T410 [US3] Clave del proyecto fuera del repositorio (%USERPROFILE%\.handtext) y key.properties local; comprobar que git no los ve
- [X] T411 [US3] Compilar la versión final por procesador, instalarla y medir el arranque (SC-504)

## Phase 4: Polish

- [X] T412 Documentación: quickstart.md, README.md y MAPA_DEL_CODIGO.md
- [X] T413 Formateadores, analizadores, todas las pruebas y recorrido en el emulador; registro de verificación al final de este archivo

## Dependencies & Execution Order

US1 → US2 → US3 → Polish. US3 no depende de US1 ni de US2.

## Registro de verificación (T413, 2026-10-29)

Constitución §6, Entrega: verificaciones ejecutadas, resultados y limitaciones.

| Verificación | Comando | Resultado |
|--------------|---------|-----------|
| Formato y analizador de la app | `dart format` y `flutter analyze` | Sin problemas |
| Pruebas de la app | `flutter test` | 225 superadas (10 nuevas de 005); 9 omitidas (contrato) |
| Pruebas del backend | `pytest` | 155 superadas (005 no cambia la API) |
| Versión final normal | `flutter build apk --release --split-per-abi` | 3 APK firmados con `CN=HandText AI` (`apksigner verify`) y `usesCleartextTraffic=false` [SC-506] |
| Versión de demostración | Lo mismo, con `-P permitirHttpLocal=true` | `usesCleartextTraffic=true`; registro e ingreso con la API local funcionan [AV-H3-E3] |
| Clave fuera del repositorio | `git check-ignore` y `git add --dry-run` | Ningún archivo de firma se subiría [SC-505] |
| Recorrido en el emulador (Android 16, API 36) | APK release x86_64 | Ver detalle abajo |

**Tamaño**:

| APK | Tamaño |
|-----|--------|
| arm64-v8a (teléfonos actuales) | 18,2 MB |
| armeabi-v7a | 15,9 MB |
| x86_64 (emulador) | 19,3 MB |
| Debug, como referencia | 168 MB |

**Arranque en frío** (`adb shell am start -W`, TotalTime) [SC-504]:
- **Arranques habituales**: 3,5; 1,7; 1,7; 1,6 y 1,6 s, más 1,9 y 1,6 s en una serie
  anterior. Mediana de 1,7 s.
- **Primer arranque después de instalar o actualizar**: 5,2 s y 5,8 s, porque Android
  optimiza la app una sola vez.
- **Debug, como referencia**: en 001 tardó unos 33 s.

**Recorrido**:
- La bienvenida muestra «Privacidad y acerca de» [AV-H2-E1].
- «Acerca de» muestra el logo, «HandText AI» y «Versión 1.0.0 (1)» [AV-H2-E2].
- «Licencias» lista las librerías e incluye **Poppins** [AV-H2-E4] [SC-503].
- El menú de cuenta ofrece «Ajustes» y «Acerca de» [AV-H1-E1].
- En Ajustes se eligieron «Oscuro» y «Muy grande», y la muestra de texto creció
  [AV-H1-E2] [AV-H1-E4].
- Al cerrar y abrir la app, la sesión y los ajustes se conservaron.
- En la versión final el recorte con uCrop funciona: R8 no rompió nada.
- La pantalla de arranque de Android 12+ muestra el ícono nuevo sobre el azul marino.

**Incidencias resueltas**:
- *«Automático» partido en dos líneas*: el ícono del botón le quitaba espacio. Se
  quitaron los íconos de los botones de tema.
- *Opción elegida en violeta apagado*: era el color por omisión de Material. Ahora el
  tema Aurora la pinta en azul corporativo con texto blanco.

**Limitaciones**:
- **SC-504 y el primer arranque**: los arranques habituales cumplen el límite de 5 s (mediana
  de 1,7 s). El primer arranque después de instalar o actualizar llegó a 5,2 y 5,8 s.
- **Número de versión**: con `--split-per-abi`, Android agrega al número interno de la
  versión el código del procesador (por ejemplo, 2001 en arm64). La app muestra «1.0.0
  (1)», que es la versión del proyecto.
- **Datos privados en la versión final**: `run-as` no funciona, así que el contenido de
  `settings.json` no se pudo leer desde `adb`. Es lo esperado en una versión final, y la
  conservación de los ajustes se comprobó reabriendo la app.
- **Texto de Flutter en inglés**: la página de licencias muestra «Powered by Flutter», un
  texto fijo de Flutter.
- Sigue pendiente CHK508 (supuestos).
