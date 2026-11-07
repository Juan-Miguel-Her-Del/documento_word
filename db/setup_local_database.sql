-- Prepara la base de datos local de HandText AI en el PostgreSQL instalado (tarea T103).
-- Se ejecuta UNA sola vez, como el superusuario «postgres», indicando la clave del nuevo
-- usuario en la línea de comandos (PowerShell, desde la raíz del repositorio):
--
--   & "C:\Program Files\PostgreSQL\17\bin\psql.exe" -U postgres -v clave="una-clave-segura" -f db/setup_local_database.sql
--
-- La clave NO se escribe en este archivo (constitución §2: las credenciales se
-- suministran por configuración externa). Después se configura la API con:
--   $env:HANDTEXT_DATABASE_URL = "postgresql://handtext:una-clave-segura@localhost:5432/handtext"

CREATE ROLE handtext LOGIN PASSWORD :'clave';
CREATE DATABASE handtext OWNER handtext;
