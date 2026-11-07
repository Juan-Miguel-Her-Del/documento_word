# Quickstart: primer uso y accesibilidad

**Plan**: [plan.md](plan.md) | **Decisiones**: [research.md](research.md)

## 1. Pruebas

```powershell
cd frontend
flutter test test/presentation/tips_screen_test.dart test/presentation/accessibility_test.dart test/state/settings_test.dart
```

`accessibility_test.dart` recorre todas las pantallas, menús, hojas y diálogos con la letra
normal y al 200 %, y falla si algo no tiene nombre para TalkBack, mide menos de
48 × 48 dp o se desborda.

## 2. Ver los consejos otra vez en el teléfono

Los consejos aparecen solos una vez por teléfono. Para volver a verlos:
- desde la app: **Consejos para una buena foto**, en el inicio o en Ajustes;
- como la primera vez: borrar los datos de la app (Ajustes de Android > Aplicaciones >
  HandText AI > Almacenamiento > Borrar datos). Eso también cierra la sesión.

## 3. Probar con la letra grande y con TalkBack

Con el emulador o el teléfono conectado:

```powershell
adb shell settings put system font_scale 2.0    # letra al 200 %
adb shell settings put system font_scale 1.0    # volver a la normal
```

TalkBack se activa en Ajustes de Android > Accesibilidad > TalkBack. Con TalkBack:
- un toque elige un elemento y lo lee;
- dos toques lo activan;
- deslizar a la derecha o a la izquierda pasa al siguiente o al anterior.
