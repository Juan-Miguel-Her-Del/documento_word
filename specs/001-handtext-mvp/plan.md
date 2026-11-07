# Implementation Plan: HandText AI — MVP

**Branch**: `01-constitucion` | **Date**: 2026-10-26 | **Spec**: [spec.md](spec.md)

**Input**: Feature specification from `/specs/001-handtext-mvp/spec.md`

## Summary

Aplicación Android en Flutter que permite fotografiar o elegir una imagen manuscrita y,
con autorización del usuario, enviarla a una API FastAPI. La API valida la imagen, prepara
una copia en memoria y la reconoce con Google Cloud Vision. El usuario revisa y corrige el
texto en un editor y lo exporta a Word o PDF; esos archivos los genera la API, y el usuario
los guarda con el diálogo del sistema. El texto con cambios no exportados se conserva como
borrador privado en el teléfono. No hay cuentas, base de datos ni almacenamiento en el
servidor. Las decisiones técnicas y su evidencia están en [research.md](research.md).

## Technical Context

**Language/Version**: Dart 3.9.2 con Flutter 3.35.4 (app); Python 3.12 (API).

**Primary Dependencies**:
- *App*: image_picker 1.2, permission_handler 12.0.1 (fijada; la 13.x exige el Android
  Gradle Plugin 9), http 1.6, path_provider 2.1, path 1.9, file_picker 11.0 y
  flutter_localizations (SDK).
- *API*: FastAPI 0.162 (Starlette 1.10, Pydantic 2.14), Uvicorn 0.54, httpx 0.28,
  Pillow 13.0, python-docx 1.2 y fpdf2 2.8.
- *Versiones exactas*: `frontend/pubspec.lock` y `backend/requirements.txt`.

**Storage**:
- *Servidor*: ningún almacenamiento; todo se trata en memoria.
- *Teléfono*: un borrador de texto en el almacenamiento interno privado de la app y copias
  de trabajo de la imagen en su caché privada (ver [data-model.md](data-model.md)).
- *PostgreSQL*: no se usa, porque la persistencia de usuarios e historial no está aprobada
  (constitución §2).

**Testing**: pytest 9.1, con pypdf 6.21 para leer los PDF generados; flutter_test para las
pruebas unitarias y de widgets.

**Target Platform**: Android con minSdk 24 (valor predeterminado de Flutter 3.35) y
compileSdk 36; la API corre en cualquier sistema con Python 3.12.

**Project Type**: mobile-app + API REST.

**Performance Goals**: SC-009. Con una imagen de hasta 10 MB y conexión Wi-Fi o 4G, la app
muestra el resultado del reconocimiento o informa el fallo en 60 s como máximo.

**Constraints**:
- *Imágenes*: JPEG o PNG, ≤ 10 MB y de 600 a 10 000 px por lado.
- *Reconocimiento*: idiomas español e inglés.
- *Tiempos*: la app espera 60 s; el backend corta la llamada al OCR a los 45 s.
- *Exportación*: hasta 200 000 caracteres (protección del servicio, R14).
- *Servidor*: no escribe imágenes ni textos en disco.

**Scale/Scope**: un usuario por teléfono, una imagen por documento, tres pantallas
(inicio, vista previa y editor) y dos endpoints.

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

| Regla | Cómo se cumple | Estado |
|-------|----------------|--------|
| §1 Alcance del MVP | Una imagen, Android, revisión y exportación a Word o PDF; nada de los Non-Goals | ✅ |
| §2 Stack | Flutter en `frontend/` y FastAPI en `backend/`; la clave del OCR solo existe en el backend | ✅ |
| §2 Base de datos | PostgreSQL no se usa porque no hay persistencia aprobada; `db/` no se crea | ✅ N/A |
| §2 Proveedor OCR con evidencia | R1 documenta manuscrito, privacidad, costo y límites; falta medir la calidad (SC-010) | ⚠️ parcial |
| §2 Generación de archivos | Servicio `app/services/documents/`, separado de las rutas | ✅ |
| §2 Dependencias registradas | `pubspec.lock` y `requirements.txt` con versiones exactas | ✅ |
| §3 Conservación del original | Copia de trabajo en la caché de la app; el backend trabaja en memoria | ✅ |
| §3 Fidelidad | El texto del proveedor no se modifica; el editor advierte posibles errores | ✅ |
| §3 Autoridad del texto editado | Se exporta el texto del editor; hay confirmación antes de sustituirlo o descartarlo | ✅ |
| §3 Integridad | Validación en la app y en el backend; se rechaza el texto vacío; un fallo nunca se anuncia como éxito | ✅ |
| §3 Formatos de salida | .docx y .pdf reales; la app verifica la firma de los bytes recibidos | ✅ |
| §3 Privacidad | Autorización antes de cada envío, registros sin contenido y sin copias de seguridad | ✅ |
| §3 Acceso | Sin cuentas y servidor sin estado: no existen documentos de otros usuarios que exponer | ✅ |
| §3 Retención | Definida en el spec (Clarifications) y en [data-model.md](data-model.md) | ✅ |
| §4 Estructura y organización | `frontend/` (models, services, state, presentation), `backend/` (api, services) y `specs/` | ✅ |
| §5 Errores y validación | Catálogo de códigos y respuestas en [contracts/api.md](contracts/api.md) | ✅ |
| §6 Verificación | Pruebas automatizadas de OCR, exportación, permisos e integraciones (tasks.md) | ✅ |

**Resultado previo a la investigación**: aprobado. La evidencia de calidad del OCR queda
como deuda registrada (SC-010), sin bloquear la implementación del flujo.

**Revisión posterior al diseño**: sin violaciones nuevas. El diseño no añade servicios,
capas ni dependencias fuera de las justificadas en research.md.

## Project Structure

### Documentation (this feature)

```text
specs/001-handtext-mvp/
├── spec.md              # Especificación (historias, criterios y Clarifications)
├── plan.md              # Este archivo
├── research.md          # Decisiones técnicas y evidencia
├── data-model.md        # Entidades, reglas y estados
├── quickstart.md        # Cómo ejecutar y validar
├── contracts/api.md     # Contrato de la API REST
├── checklists/          # Revisión del spec
└── tasks.md             # Tareas ejecutadas
```

### Source Code (repository root)

```text
backend/
├── app/
│   ├── main.py                  # Crea la API, request_id y registros seguros
│   ├── config.py                # Límites del spec, idiomas, tiempos y clave
│   ├── errors.py                # Catálogo de errores y manejadores
│   ├── schemas.py               # Modelos de entrada y salida
│   ├── api/                     # Rutas: recognitions.py, exports.py, request_body.py
│   ├── services/
│   │   ├── image_validation.py  # Validación por contenido
│   │   ├── image_preparation.py # Copia en memoria para el OCR
│   │   ├── ocr/                 # Contrato y adaptador de Google Cloud Vision
│   │   └── documents/           # Reglas del texto y generadores Word y PDF
│   └── assets/fonts/            # DejaVu Sans y su licencia
├── tests/                       # pytest (muestras sintéticas)
├── pyproject.toml
└── requirements.txt / requirements-dev.txt

frontend/
├── lib/
│   ├── main.dart / app.dart     # Arranque y composición
│   ├── config/                  # URL del backend, tiempos y límites
│   ├── models/                  # Datos sin lógica de interfaz
│   ├── services/                # Imagen, cámara, red, guardado y borrador
│   ├── state/                   # DocumentFlowController
│   ├── presentation/            # Textos, pantallas y widgets
│   └── theme/                   # Tema centralizado
├── test/                        # Pruebas unitarias y de widgets
└── android/                     # Proyecto Android (manifiestos ajustados)
```

**Structure Decision**: se aplica la estructura de la constitución §4. `db/` no se crea
porque no hay persistencia aprobada. Las pruebas están en `backend/tests` y
`frontend/test`.

## Complexity Tracking

No hay violaciones de la constitución que justificar.
