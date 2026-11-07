# HandText AI: app Android

App Flutter de HandText AI: digitaliza documentos escritos a mano. Toma una foto o
escanea la hoja, reconoce el texto, deja revisarlo y corregirlo, y lo guarda como Word o
PDF.

Esta carpeta tiene solo la app. La documentación está en la raíz del proyecto:
- [README.md](../README.md): qué hace, cómo ejecutar la app y la API, y cómo probarlas.
- [MAPA_DEL_CODIGO.md](../MAPA_DEL_CODIGO.md): dónde está en el código cada escenario
  de los specs.
- [specs/](../specs/): la especificación de cada funcionalidad, de 001 a 012.

## Carpetas

- `lib/`: el código de la app.
  - `models/`: los datos (página, borrador, documento, ajustes, fallos).
  - `services/`: lo que habla con el exterior (API, archivos, cámara, escáner, huella).
  - `state/`: los controladores que deciden qué pasa en cada momento.
  - `presentation/`: las pantallas, los componentes y los textos en español e inglés.
  - `theme/`: los colores y estilos Aurora.
  - `config/`: la dirección de la API.
- `test/`: pruebas automatizadas (`flutter test`).
- `integration_test/`: prueba de punta a punta (spec 012).
- `android/`: el proyecto nativo de Android.
- `assets/fonts/`: la tipografía Poppins y su licencia.
- `tool/`: la herramienta que genera el ícono.
