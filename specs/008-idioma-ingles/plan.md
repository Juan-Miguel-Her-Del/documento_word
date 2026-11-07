# Implementation Plan: App en inglés

**Branch**: `01-constitucion` | **Date**: 2026-10-29 | **Spec**: [spec.md](spec.md)

**Input**: Feature specification from `/specs/008-idioma-ingles/spec.md`

## Summary

Los textos pasan de una clase estática en español a una clase abstracta con una
traducción por idioma. Llegan a las pantallas con el mecanismo de localización de
Flutter. Un ajuste nuevo elige el idioma: español (por omisión), inglés o el del
teléfono. La API no cambia. Las decisiones están en [research.md](research.md).

## Technical Context

**Language/Version**: Dart 3.9.2 con Flutter 3.35.4.

**Primary Dependencies**: ninguna nueva. `flutter_localizations` ya estaba (001).

**Storage**: un campo nuevo, `language`, en `settings.json` (R4).

**Testing**: flutter_test (ajuste, pantallas en inglés, letra al 200 % y texto de la
persona intacto).

**Target Platform**: Android, minSdk 24.

**Project Type**: mobile-app.

**Performance Goals**: el cambio de idioma se ve en el siguiente cuadro (sin reiniciar).

**Constraints**:
- El español es el idioma inicial (constitución §4).
- El texto de la persona nunca se traduce (constitución §3).

**Scale/Scope**:
- 3 archivos de textos (abstracto, español e inglés), unos 160 textos por idioma.
- Unos 170 usos en 22 archivos de la app y 280 en 9 archivos de pruebas.
- Un ajuste y un selector en Ajustes y en la bienvenida.

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

| Regla | Cómo se cumple | Estado |
|-------|----------------|--------|
| §2 Dependencias | Ninguna nueva | ✅ |
| §3 Fidelidad (sin traducciones) | Solo se traduce la interfaz; el texto de la persona no se toca (Historia 3, SC-803) | ✅ |
| §4 Mensajes iniciales en español | El español es el idioma inicial y el de respaldo; el inglés se elige | ⚠️ supuesto 4: confirmar la interpretación |
| §4 Identificadores en inglés | Sin cambios | ✅ |
| §5 Mensajes que dicen qué hacer | Cada mensaje traducido conserva el qué pasó y qué hacer | ✅ |
| §6 Pruebas | Ajuste, recorrido completo en inglés al 100 % y al 200 %, texto intacto | ✅ |

**Revisión posterior al diseño**: sin violaciones; queda confirmar §4 (supuesto 4).

## Project Structure

```text
frontend/
├── lib/
│   ├── models/app_settings.dart            # + AppLanguage
│   ├── services/settings_store.dart        # + language
│   ├── state/settings_controller.dart      # + setLanguage
│   ├── app.dart                            # locale, delegado y resolución (R2, R5)
│   ├── main.dart                           # títulos de servicios con AppStrings.current (R3)
│   └── presentation/
│       ├── strings.dart                    # clase abstracta, delegado y context.strings
│       ├── strings_es.dart                 # NUEVO: español
│       ├── strings_en.dart                 # NUEVO: inglés
│       ├── widgets/language_sheet.dart     # NUEVO: hoja para elegir el idioma (R9)
│       └── screens/…                       # AppStrings.x → context.strings.x
└── test/
    ├── support/strings_es.dart             # instancia en español para las pruebas
    └── presentation/language_test.dart     # NUEVO
```

## Complexity Tracking

No hay elementos que justificar.
