# Revisión de la especificación: Historial de documentos

**Documento**: [spec.md](../spec.md)
**Revisado**: 2026-10-29

Una casilla marcada indica conformidad documental; no indica aprobación del responsable.

## Formato y alcance

- [x] CHK701 Sigue el formato de 001 a 006: «Features principales», módulos numerados, viñetas y reglas críticas en negrita.
- [x] CHK702 No cambia reglas de 001 a 006: el servidor sigue sin guardar documentos y el guardado funciona igual.
- [x] CHK703 Tiene Non-Goals explícitos (servidor y sincronización, búsqueda, guardar imágenes o archivos, documentos anteriores, idioma).
- [x] CHK704 No incluye código, endpoints ni tablas.

## Trazabilidad con la constitución

- [x] CHK705 Cada historia tiene prioridad, prueba independiente y escenarios Dado/Cuando/Entonces.
- [x] CHK706 Los criterios de éxito son medibles e indican volumen y entorno (SC-705: 50 documentos, emulador Android 16).
- [x] CHK707 Respeta la constitución:
  - §3 Retención: el plan define ubicación, permisos, retención y eliminación;
  - §3 Consistencia: un guardado fallido nunca aparece como disponible;
  - §3 Acceso: cada cuenta solo ve su historial;
  - §3 Operaciones destructivas: borrar pide confirmación.
- [ ] CHK708 Validar los supuestos 1 a 4 con el responsable del proyecto.
- [ ] CHK709 Confirmar con la profesora que el historial entra al alcance (001 lo dejaba fuera; constitución §1).
