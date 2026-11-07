# Quickstart: historial de documentos

**Plan**: [plan.md](plan.md) | **Decisiones**: [research.md](research.md) | **Datos**:
[data-model.md](data-model.md)

## 1. Pruebas

```powershell
cd frontend
flutter test test/services/history_store_test.dart test/state/history_flow_test.dart test/presentation/history_screen_test.dart
```

## 2. Probarlo en el teléfono

1. Guardar un texto como Word o PDF (como en 001).
2. En el inicio, tocar **Mis documentos**: el documento aparece primero, con su fecha,
   sus formatos y sus palabras.
3. Tocarlo: se abre en el editor. Corregirlo y guardarlo otra vez actualiza la misma
   entrada.
4. El ícono de la papelera de cada documento lo quita de la lista; el de arriba borra
   todo. Los archivos ya guardados en el teléfono no se tocan.

## 3. Dónde está y cuándo se borra

- Archivo: `history_<id de la cuenta>.json`, en la carpeta privada de la app (la misma
  del borrador). Sin copias de seguridad.
- Se conserva al cerrar sesión.
- Se borra:
  - con «Eliminar» o «Borrar todo»;
  - al eliminar la cuenta;
  - al borrar los datos de la app o desinstalarla.
