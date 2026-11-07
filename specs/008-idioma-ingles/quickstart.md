# Quickstart: app en inglés

**Plan**: [plan.md](plan.md) | **Decisiones**: [research.md](research.md)

## 1. Pruebas

```powershell
cd frontend
flutter test test/presentation/language_test.dart test/state/settings_test.dart
```

`language_test.dart` recorre todas las pantallas en inglés, con la letra normal y al
200 %, y falla si se ve un texto en español.

## 2. Dónde están los textos

| Archivo | Qué tiene |
|---------|-----------|
| `frontend/lib/presentation/strings.dart` | La lista de todos los textos (clase abstracta), el idioma inicial y cómo llegan a las pantallas |
| `frontend/lib/presentation/strings_es.dart` | Los textos en español |
| `frontend/lib/presentation/strings_en.dart` | Los textos en inglés |

Para agregar un texto:
1. Declararlo en `strings.dart`.
2. Escribirlo en los dos idiomas (si falta en uno, la app no compila).
3. Usarlo en la pantalla con `context.strings.nombre`.

## 3. Cambiar el idioma en el teléfono

- En la bienvenida: el botón con el ícono de idioma, arriba a la derecha.
- Con sesión: menú de la cuenta > Ajustes > Idioma.

Las opciones son Español, English y Automático (el idioma del teléfono). El texto de los
documentos nunca se traduce.
