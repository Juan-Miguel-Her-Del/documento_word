# Revisión del documento de entrada: HandText AI

**Documento**: [spec.md](../spec.md)
**Revisado**: 2026-10-26
**Referencia**: prompt de especificaciones funcionales proporcionado por la profesora.

Esta lista revisa el documento de entrada para `/speckit.specify`. Una casilla marcada
indica conformidad documental con ese prompt; no indica aprobación del usuario,
implementación terminada ni pruebas de la aplicación ejecutadas.

## Cumplimiento del formato y alcance

- [x] CHK001 El documento comienza con `## Features principales`.
- [x] CHK002 Las funcionalidades se organizan en módulos numerados con encabezados de nivel 3.
- [x] CHK003 Cada módulo utiliza viñetas para describir comportamientos del sistema.
- [x] CHK004 Las reglas críticas de validación, integridad y privacidad están en negrita.
- [x] CHK005 Se identifica HandText AI, su propósito, sus usuarios y el alcance del MVP.
- [x] CHK006 Existe la sección explícita de Non-Goals con las funcionalidades excluidas.
- [x] CHK007 No se incluyen código, endpoints, modelos de datos, carpetas ni stack tecnológico.
- [x] CHK008 Las condiciones desconocidas se señalan como pendientes de definición.
- [x] CHK009 Las cifras propuestas anteriormente no se presentan como reglas acordadas.
- [x] CHK010 El alcance y las reglas de dominio respetan la constitución (ver CHK015–CHK017).

## Definiciones y revisión pendientes

- [x] CHK011 Acordar los formatos, el tamaño máximo y los límites de dimensiones de imagen (JPEG y PNG, 10 MB, 600–10 000 px; 2026-10-26).
- [ ] CHK012 Acordar los idiomas, la calidad mínima del reconocimiento y su espera máxima (idiomas y espera acordados el 2026-10-26; el 2026-10-29 se definió cómo medir la calidad y se propuso un CER ≤ 10 %; falta que el responsable apruebe la meta).
- [x] CHK013 Definir las condiciones y plazos de conservación y eliminación de temporales (2026-10-26: nada en el servidor; borrador local hasta exportar o descartar).
- [ ] CHK014 Revisar el contenido con el responsable del proyecto antes de adoptarlo.

## Trazabilidad con la constitución

- [x] CHK015 Cada historia tiene prioridad, prueba independiente y escenarios Dado/Cuando/Entonces.
- [x] CHK016 Los criterios de éxito son medibles y se derivan de reglas ya escritas.
- [ ] CHK017 Definir los criterios de tiempo y calidad (SC-009 definido el 2026-10-26; SC-010 redactado el 2026-10-29 con la medición de R15; falta la aprobación de la meta, CHK012).
- [ ] CHK018 Validar los supuestos del spec con el responsable del proyecto (los supuestos 1–7 se implementaron tal como están).

## Notas

- «Features principales» conserva el formato funcional solicitado y sigue siendo la fuente
  de los requisitos, referenciados por número de módulo. Se añaden historias y criterios SC
  porque la constitución exige escenarios de aceptación y resultados medibles (sección 6).
  Los identificadores FR y EC anteriores siguen sin aplicar.
- Se retiran como reglas los valores no confirmados de tamaño, resolución, tiempos,
  retención, precisión, muestras de prueba y condiciones de evaluación.
- El 2026-10-26 se acordaron los formatos y límites de imagen, los idiomas, la espera
  máxima y la conservación de los datos (sección `Clarifications` del spec). La calidad
  mínima del reconocimiento sigue pendiente.
- Con esas decisiones se generaron plan.md, research.md, data-model.md, contracts/,
  quickstart.md y tasks.md, y se implementó el MVP. Siguen abiertas la calidad mínima
  (CHK012, CHK017) y la revisión del responsable del proyecto (CHK014, CHK018).
- Ejecutar `/speckit.specify` de nuevo crearía `specs/002-…` en lugar de actualizar esta
  carpeta.
