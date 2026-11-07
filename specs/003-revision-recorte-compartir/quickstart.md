# Quickstart: revisión asistida, recorte y compartir

**Plan**: [plan.md](plan.md) | **Contrato**: [contracts/recognition-api.md](contracts/recognition-api.md)

La API y la app se ejecutan igual que en el
[quickstart de 002](../002-cuentas-de-usuario/quickstart.md). Esta funcionalidad no
agrega variables de entorno ni migraciones.

## 1. Dependencias nuevas de la app

```powershell
cd frontend
flutter pub get   # instala image_cropper 12.2.1 y share_plus 12.0.2
```

## 2. Pruebas automatizadas

```powershell
cd backend;  .venv\Scripts\python -m pytest tests/test_uncertain_words.py tests/test_google_vision_provider.py tests/test_recognitions_api.py
cd frontend; flutter test test/services/uncertain_ranges_test.dart test/state/extras_flow_test.dart test/presentation/extras_screens_test.dart
```

## 3. Validación manual en el emulador o el teléfono

| Escenario | Pasos | Resultado esperado |
|-----------|-------|--------------------|
| EX-H1-E1 | Reconocer una hoja manuscrita (necesita la clave de Google) | Las palabras dudosas aparecen con fondo ámbar y subrayado ondulado; la barra dice cuántas son |
| EX-H1-E3 / E5 | Tocar «Siguiente» y luego «Está bien» | Se selecciona la palabra; al aceptarla, el contador baja y el texto no cambia |
| EX-H1-E7 | Con marcas pendientes, cerrar la app (`adb shell am kill com.handtextai.handtext_ai`) y abrirla | El borrador vuelve con sus marcas |
| EX-H2-E1 / E2 | En la vista previa, «Recortar o girar», recortar, girar y confirmar | La vista previa muestra la nueva imagen y sus nuevas dimensiones |
| EX-H2-E5 | Después de recortar, «Usar la imagen original» | Vuelven la imagen y las dimensiones originales |
| EX-H2-E7 | Abrir la foto en la galería después de recortar | La foto original no cambió |
| EX-H3-E1 / E2 | Exportar a PDF, guardar y tocar «Compartir» | Se abre el selector de Android con el PDF (mismo nombre) |
