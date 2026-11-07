# Quickstart: varias páginas por documento

**Plan**: [plan.md](plan.md)

La API y la app se ejecutan igual que en el
[quickstart de 002](../002-cuentas-de-usuario/quickstart.md). Esta funcionalidad no
agrega dependencias, variables de entorno ni migraciones.

## 1. Pruebas automatizadas

```powershell
cd frontend
flutter test test/services/page_join_test.dart test/state/pages_flow_test.dart test/presentation/pages_screen_test.dart
```

## 2. Validación manual en el emulador o el teléfono

| Escenario | Pasos | Resultado esperado |
|-----------|-------|--------------------|
| VP-H1-E1 | «Elegir imagen guardada» y marcar 3 fotos en el selector | La vista previa muestra 3 miniaturas numeradas y «Reconocer 3 páginas» |
| VP-H2-E2 | Elegir una miniatura y tocar las flechas | La página cambia de lugar y la numeración se actualiza |
| VP-H2-E3 | Tocar el ícono de la papelera | La página desaparece y quedan las demás |
| VP-H1-E2 | Tocar la tarjeta «+» y elegir «Tomar fotografía» o «Elegir de la galería» | La nueva página se agrega al final |
| VP-H1-E3 | Tocar «Reconocer 3 páginas» | La autorización dice «¿Autoriza el envío de 3 imágenes?» |
| VP-H1-E5 | Autorizar (con la clave de Google) | El editor muestra el texto de las 3 páginas en orden, separadas por una línea en blanco |
| VP-H3-E1 | Detener la API en medio del reconocimiento | El aviso dice qué página falló y ofrece «Reintentar» |
