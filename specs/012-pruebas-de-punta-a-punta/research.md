# Research: Pruebas de punta a punta

## R1. Herramienta

**Decisión**: `integration_test`, que viene con Flutter (`sdk: flutter`, sin versión
externa). Corre la app en el emulador con el mismo lenguaje de las pruebas de widgets.

**Alternativa**: Patrol o Appium, que también manejan pantallas de Android. Son una
dependencia o un servidor más, y esas pantallas no son de la app (Non-Goal).

## R2. Qué es real y qué se simula

**Decisión**: la prueba arma la app igual que `main.dart`, con estas diferencias:

| Pieza | En la prueba |
|-------|--------------|
| Cuentas y sesión | Reales: API local, PostgreSQL y Android Keystore |
| Exportar a Word | Real: lo genera la API |
| Borrador, historial y ajustes | Reales, en archivos del teléfono |
| Copias de trabajo y validación de la imagen | Reales |
| Reconocimiento | Simulado: devuelve un texto con palabras dudosas (falta la clave de Google) |
| Selector de fotos | Simulado: entrega una hoja sintética |
| Diálogo para guardar | Simulado: guarda en la carpeta privada de la app |

## R3. La hoja

**Decisión**: se dibuja en la prueba (1200 × 1600 px, blanca, con líneas de texto) con
`dart:ui` y se convierte a PNG. No hay archivos de prueba que mantener, y pasa la
validación real de 001 (formato por contenido y medidas).

## R4. Ejecución y tiempos

**Decisión**: un solo comando, con la URL de la API como en `flutter run`:
`flutter test integration_test -d emulator-5554 --dart-define=API_BASE_URL=http://10.0.2.2:8000/`.
Los tiempos de cada paso se miden con `Stopwatch` y se escriben en el registro
[SC-1201]. Cada ejecución usa un correo con la hora, así se puede repetir.
