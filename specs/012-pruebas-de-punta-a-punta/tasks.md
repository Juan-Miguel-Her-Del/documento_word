---

description: "Tareas de la funcionalidad 012: pruebas de punta a punta"
---

# Tasks: Pruebas de punta a punta

**Input**: [plan.md](plan.md), [spec.md](spec.md), [research.md](research.md)

Los identificadores siguen desde T1101.

## Phase 1: User Story 1 - De la cuenta al Word (Priority: P1) 🎯

- [X] T1101 [US1] integration_test en dev_dependencies; recorrido en frontend/integration_test/flujo_completo_test.dart con la app armada como en main.dart (R2), la hoja sintética (R3) y los tiempos (R4)

## Phase 2: User Story 2 - Volver a encontrarlo (Priority: P2)

- [X] T1102 [US2] Cerrar sesión, volver a entrar y encontrar el documento, en el mismo recorrido

## Phase 3: Polish

- [X] T1103 quickstart.md (el comando), README.md y MAPA_DEL_CODIGO.md
- [X] T1104 Ejecución en el emulador con la API local; registro de verificación al final de este archivo

## Dependencies & Execution Order

US1 → US2 → Polish. Requiere 009 a 011 terminadas: el recorrido pasa por sus pantallas.

## Registro de verificación (T1103, 2026-11-06)

Constitución §6, Entrega: verificaciones ejecutadas, resultados y limitaciones.

| Verificación | Comando o entorno | Resultado |
|--------------|-------------------|-----------|
| Analizador | `flutter analyze` (incluye `integration_test`) | Sin problemas: el recorrido compila contra la app actual |
| Comando documentado [SC-1203] | [quickstart.md](quickstart.md) y README («Pruebas») | Un solo comando, para el emulador y para un teléfono por USB |
| Ejecución del recorrido [SC-1201] [SC-1202] | Emulador con la API local | **No se ejecutó** (ver limitaciones) |

**Limitaciones**:
- **El recorrido no se ha ejecutado.** Necesita a la vez el emulador, la compilación de
  Gradle, la API y PostgreSQL. Con 1 a 2 GB de memoria libres en el computador, el
  emulador dejó de responder en las sesiones de 009 y 011.
- Hasta ejecutarlo, SC-1201 (pasa en menos de 3 minutos) y SC-1202 (.docx real con el
  texto corregido) **no están comprobados**. T1104 sigue abierta.
- Cómo ejecutarlo: [quickstart.md](quickstart.md). Un teléfono por USB gasta menos memoria
  del computador que el emulador. SC-1201 nombra el emulador de referencia: si se usa un
  teléfono, hay que anotarlo en el registro.
- Los supuestos 1 y 2 siguen pendientes de validación (CHK1206).

## Registro de verificación (T1104, 2026-11-07)

| Verificación | Comando o entorno | Resultado |
|--------------|-------------------|-----------|
| Ejecución del recorrido [SC-1201] [SC-1202] | Emulador Medium Phone API 36 (Android 16), API local con PostgreSQL temporal | **Pasa**: 175,9 s en total, menos de 3 minutos. El .docx lo genera la API real y contiene el texto corregido |

Tiempo de cada paso: crear la cuenta 59,2 s; elegir la hoja y reconocer 35,6 s; corregir
y guardar el Word 6,8 s; encontrarlo en Mis documentos 10,4 s; cerrar sesión, volver y
encontrarlo 19,1 s.

**Qué hizo falta para ejecutarlo**:
- Gradle pedía 8 GB de memoria en un computador de 7,4 GB y la JVM se cerraba
  (`hs_err_pid*.log`). Con 2,5 GB ([gradle.properties](../../frontend/android/gradle.properties))
  compila con el emulador abierto.
- Había que desbloquear el emulador con su PIN (1234, de la spec 011). Mientras Android no
  se desbloquea después de encenderse, no deja abrir la app («Activity class does not
  exist»).
- En este computador, otro proyecto ocupa `127.0.0.1:8000`, que es el `10.0.2.2:8000` del
  emulador. La API se levantó en el puerto 8001 (`--dart-define=API_BASE_URL=http://10.0.2.2:8001/`).
- Corrección de la prueba: al volver de Mis documentos, el inicio quedaba desplazado hacia
  abajo y el botón «Cuenta» no existía en la lista. La prueba ahora sube antes de tocarlo
  (`_tapTooltip`).

**Limitaciones**: el reconocimiento sigue simulado (falta la clave de Google; R2).
