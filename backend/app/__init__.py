"""Paquete de la API de HandText AI.

Mapa rápido del backend:
- main.py: crea la aplicación FastAPI, el identificador de solicitud y los registros.
- config.py: límites acordados en el spec, idiomas, tiempos y la clave del proveedor.
- errors.py: catálogo de errores con código estable y mensaje en español.
- api/: rutas HTTP (reconocimiento y exportación).
- services/: lógica sin HTTP (validar imágenes, OCR, generar Word y PDF).
"""
