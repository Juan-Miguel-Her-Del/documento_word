# Revisión de la especificación: Revisión asistida, recorte y compartir

**Documento**: [spec.md](../spec.md)
**Revisado**: 2026-10-28

Una casilla marcada indica conformidad documental; no indica aprobación del responsable.

## Formato y alcance

- [x] CHK301 Sigue el formato de 001 y 002: «Features principales», módulos numerados, viñetas y reglas críticas en negrita.
- [x] CHK302 Declara qué supuestos de 001 reemplaza (4: recorte y giro; 7: compartir) y conserva las demás reglas.
- [x] CHK303 Tiene Non-Goals explícitos (corrección automática, filtros, varias páginas, compartir sin guardar).
- [x] CHK304 No incluye código, endpoints, tablas ni tecnologías.

## Trazabilidad con la constitución

- [x] CHK305 Cada historia tiene prioridad, prueba independiente y escenarios Dado/Cuando/Entonces.
- [x] CHK306 Los criterios de éxito son medibles.
- [x] CHK307 Respeta la constitución §3:
  - las marcas no alteran el texto (Fidelidad);
  - el recorte trabaja sobre una copia (Conservación del original);
  - compartir es una acción explícita (Privacidad).
- [x] CHK308 Define la retención de los archivos temporales nuevos (copia recortada y copia para compartir).
- [ ] CHK309 Validar los supuestos 1 a 5 con el responsable del proyecto.
- [ ] CHK310 Confirmar con la profesora la ampliación del alcance: los supuestos 4 y 7 de 001 dejaban fuera el recorte y compartir.

## Notas

- Las tres mejoras las eligió el responsable del proyecto el 2026-10-28 (ver
  `Clarifications`).
- El umbral del 80 % es una decisión inicial: se puede ajustar cuando se mida la calidad
  con la clave real de Google (SC-010 de 001, todavía pendiente).
