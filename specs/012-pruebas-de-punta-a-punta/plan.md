# Implementation Plan: Pruebas de punta a punta

**Branch**: `01-constitucion` | **Date**: 2026-11-05 | **Spec**: [spec.md](spec.md)

**Input**: Feature specification from `/specs/012-pruebas-de-punta-a-punta/spec.md`

## Summary

Una prueba de `integration_test` recorre la app en el emulador contra la API y la base
reales:
- crear la cuenta;
- elegir la hoja;
- autorizar el envío y llegar al editor;
- corregir el texto;
- guardar el Word;
- encontrarlo en Mis documentos.

Solo se simulan el reconocimiento (falta la clave de Google) y las pantallas de Android
(R2).

## Technical Context

**Language/Version**: Dart 3.9.2 con Flutter 3.35.4.

**Primary Dependencies**: `integration_test` (del SDK de Flutter, solo para pruebas).

**Storage**: los de la app (temporales de la prueba).

**Testing**: es la prueba.

**Target Platform**: emulador Android 16 con la API local.

**Project Type**: mobile-app.

**Performance Goals**: recorrido completo en menos de 3 minutos (SC-1201).

**Constraints**: no cambia el código de la app.

**Scale/Scope**: un archivo de prueba y un ayudante para armar la app.

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

| Regla | Cómo se cumple | Estado |
|-------|----------------|--------|
| §2 Dependencias | `integration_test` es del SDK; se registra en `dev_dependencies` | ✅ |
| §3 Formatos de salida | La prueba verifica la firma del .docx real | ✅ |
| §6 Verificación | Recorrido automático completo; muestras sintéticas | ✅ |
| §6 Datos de prueba | Cuenta y hoja sintéticas; ningún documento privado | ✅ |

**Revisión posterior al diseño**: sin violaciones.

## Project Structure

```text
frontend/
├── pubspec.yaml                                # + integration_test (dev)
└── integration_test/
    └── flujo_completo_test.dart                # NUEVO: el recorrido (R2 a R4)
```

## Complexity Tracking

No hay elementos que justificar.
