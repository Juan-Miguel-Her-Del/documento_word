# Revisión de la especificación: Primer uso y accesibilidad

**Documento**: [spec.md](../spec.md)
**Revisado**: 2026-10-29

Una casilla marcada indica conformidad documental; no indica aprobación del responsable.

## Formato y alcance

- [x] CHK601 Sigue el formato de 001 a 005: «Features principales», módulos numerados, viñetas y reglas críticas en negrita.
- [x] CHK602 No cambia reglas de 001 a 005: los consejos no envían nada y la accesibilidad no cambia el flujo.
- [x] CHK603 Tiene Non-Goals explícitos (videos, consejos por cuenta, auditoría externa, control por voz, pantallas de otras apps, idioma).
- [x] CHK604 No incluye código, endpoints ni tablas.

## Trazabilidad con la constitución

- [x] CHK605 Cada historia tiene prioridad, prueba independiente y escenarios Dado/Cuando/Entonces.
- [x] CHK606 Los criterios de éxito son medibles e indican el entorno (SC-606: emulador Android 16).
- [x] CHK607 Respeta la constitución:
  - §3: los consejos no piden permisos ni envían datos;
  - §5: los avisos de estado siguen distinguiendo procesamiento, éxito y fallo, ahora también por voz.
- [ ] CHK608 Validar los supuestos 1 a 4 con el responsable del proyecto.
