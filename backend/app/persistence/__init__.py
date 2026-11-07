"""Capa de persistencia (constitución §2: todo acceso a la base pasa por aquí).

- user_store.py: contrato del almacén de usuarios y sesiones, y sus errores.
- postgres_store.py: implementación con PostgreSQL y consultas parametrizadas.
- migrations.py: aplica los archivos SQL de db/migrations/.
"""
