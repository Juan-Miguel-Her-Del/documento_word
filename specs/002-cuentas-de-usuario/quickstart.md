# Quickstart: cuentas de usuario e identidad visual Aurora

Complementa [001/quickstart.md](../001-handtext-mvp/quickstart.md). Los comandos son para
PowerShell y se ejecutan desde la raíz del repositorio (`documento_word`).

## 1. Base de datos (una sola vez)

En el PostgreSQL 17 instalado en el equipo, se crea el usuario y la base de HandText AI.
La clave del nuevo usuario la elige usted y no se guarda en ningún archivo:

```powershell
& "C:\Program Files\PostgreSQL\17\bin\psql.exe" -U postgres -v clave="una-clave-segura" -f db/setup_local_database.sql
```

Luego se aplican las migraciones (tablas `users` y `sessions`):

```powershell
cd backend
$env:HANDTEXT_DATABASE_URL = "postgresql://handtext:una-clave-segura@localhost:5432/handtext"
.venv\Scripts\python -m app.persistence.migrations
```

## 2. API con cuentas

En la misma terminal, con `HANDTEXT_DATABASE_URL` definida (y opcionalmente
`HANDTEXT_GOOGLE_VISION_API_KEY`):

```powershell
.venv\Scripts\python -m pip install -r requirements-dev.txt
.venv\Scripts\python -m uvicorn app.main:app --host 0.0.0.0 --port 8000
```

Sin `HANDTEXT_DATABASE_URL`, las rutas de cuentas y las protegidas responden
`503 ACCOUNTS_UNAVAILABLE`.

## 3. Pruebas

```powershell
cd backend;  .venv\Scripts\python -m pytest     # incluye PostgreSQL real con pgserver
cd frontend; flutter test                       # incluye pantallas de cuenta
```

Las pruebas de persistencia levantan solas un PostgreSQL temporal con pgserver y no
necesitan la clave del PostgreSQL instalado. Para la prueba de contrato con la API real,
vea la cabecera de `frontend/test/integration/api_contract_test.dart`.

## 4. App

```powershell
cd frontend
flutter run --dart-define=API_BASE_URL=http://10.0.2.2:8000/
```

## 5. Validación manual

| Escenario | Pasos | Resultado esperado |
|-----------|-------|--------------------|
| CU-H1-E1 / E2 | Abrir la app por primera vez y crear una cuenta | Bienvenida animada; tras registrarse, el inicio saluda por el nombre |
| CU-H1-E8 | Ingresar 5 veces con una contraseña mala y luego con la buena | Aviso de bloqueo de 15 minutos |
| CU-H1-E9 | Cerrar la app por completo y volver a abrirla | Entra directo, sin pedir la contraseña |
| CU-H2-E2 | Editar un texto sin exportarlo y cerrar sesión desde el avatar | Pide confirmación porque se descartará |
| CU-H2-E3 | Avatar → Eliminar cuenta → escribir la contraseña | Vuelve a la bienvenida con «Su cuenta y sus datos se eliminaron» |
| CU-H3-E2 | Reconocer una imagen | Una línea de escaneo recorre la imagen mientras espera |
| CU-H3-E3 | Ajustes de Android → Accesibilidad → Quitar animaciones | El fondo y el logo quedan quietos |
| CU-H3-E4 | Activar el modo oscuro de Android | El editor usa colores oscuros legibles |
