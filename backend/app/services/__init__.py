"""Servicios del backend: lógica sin HTTP (constitución §4, Organización).

Se pueden probar sin ejecutar la app móvil ni la API:
- image_validation.py: valida imágenes por su contenido.
- image_preparation.py: crea la copia en memoria que se envía al OCR.
- ocr/: contrato del proveedor de OCR y adaptador de Google Cloud Vision.
- documents/: reglas del texto y generadores de Word y PDF.
"""
