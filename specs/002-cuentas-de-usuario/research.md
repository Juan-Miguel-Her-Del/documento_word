# Research: Cuentas de usuario e identidad visual Aurora

**Fecha**: 2026-10-27 | **Plan**: [plan.md](plan.md)

## R1. Contraseñas: Argon2id

- **Decisión**: argon2-cffi con los parámetros predeterminados de `PasswordHasher`
  (Argon2id). La base guarda solo el hash, que ya incluye la sal y los parámetros.
- **Razón**: Argon2id es el algoritmo recomendado para contraseñas porque resiste ataques
  con GPU. Si el correo no existe, se verifica igual contra un hash ficticio, para que el
  tiempo de respuesta no revele qué correos están registrados (SC-203).
- **Alternativas**: bcrypt (bueno, pero limita la contraseña a 72 bytes); SHA-256 con sal
  (demasiado rápido para contraseñas).

## R2. Sesiones: tokens opacos con hash en la base

- **Decisión**: al ingresar se crea un token aleatorio de 256 bits
  (`secrets.token_urlsafe(32)`). La app lo recibe una vez y la base guarda solo su
  SHA-256, con el usuario y la fecha de vencimiento (30 días). Cerrar sesión borra la
  fila; eliminar la cuenta borra todas sus sesiones en cascada.
- **Razón**: se puede revocar al instante (cerrar sesión o eliminar la cuenta) y no exige
  administrar una clave de firma. Si la base se filtrara, los hashes no sirven para
  autenticarse (SC-201).
- **Alternativas**: JWT firmado (no se puede revocar sin otra tabla y exige un secreto
  adicional).

## R3. Acceso a PostgreSQL

- **Decisión**: psycopg 3 síncrono con `ConnectionPool` (psycopg-pool), consultas
  parametrizadas (`%s`) y filas como diccionarios. Las rutas asíncronas lo llaman en un
  hilo aparte (`run_in_threadpool`) o mediante dependencias síncronas de FastAPI.
- **Razón**: el modo asíncrono de psycopg no funciona con el bucle de eventos
  predeterminado de Windows (Proactor), que es donde se desarrolla el proyecto. La
  constitución §2 admite consultas parametrizadas sin ORM.
- **Alternativas**: SQLAlchemy (un ORM que habría que justificar para 2 tablas); asyncpg
  (con el mismo problema en Windows).

## R4. Migraciones en SQL

- **Decisión**: archivos `db/migrations/NNNN_nombre.sql`, aplicados en orden por
  `python -m app.persistence.migrations`. Cada uno queda anotado en la tabla
  `schema_migrations`.
- **Razón**: la constitución §2 pide SQL para esquemas y migraciones. Un ejecutor de unas
  30 líneas es más fácil de explicar que Alembic.

## R5. Pruebas contra PostgreSQL real

- **Decisión**: pgserver (dependencia de desarrollo) levanta un PostgreSQL 16 temporal
  para pytest, en unos 9 s una sola vez por sesión. Las mismas pruebas de contrato se
  ejecutan contra el almacén en memoria y contra PostgreSQL. Si pgserver no está
  disponible, las de PostgreSQL se omiten.
- **Razón**: no requiere conocer la contraseña del PostgreSQL 17 instalado y se ejecuta
  en cualquier equipo.

## R6. Bloqueo por intentos fallidos

- **Decisión**: 5 fallos seguidos bloquean el ingreso durante 15 minutos. El contador
  vive en `users` y se reinicia al ingresar correctamente o al aplicarse el bloqueo. La
  respuesta es 429 `TOO_MANY_ATTEMPTS`.
- **Razón**: frena los ataques de adivinación sin infraestructura adicional.

## R7. Sesión en el teléfono

- **Decisión**: flutter_secure_storage guarda el token y los datos visibles del usuario.
  En Android lo cifra con una clave del Android Keystore. Al abrir la app se valida con
  `GET /auth/me`; si no hay conexión, se entra con los datos guardados.
- **Razón**: es la práctica recomendada para credenciales en móviles. La app ya excluye
  sus datos de las copias de seguridad.

## R8. Borrador por usuario

- **Decisión**: el borrador se guarda en `draft_<id-de-usuario>.txt`.
  - Al cerrar sesión, se descarta (previa confirmación).
  - Al eliminar la cuenta, se borra.
  - Si la sesión vence, se conserva para esa misma persona.
- **Razón**: cumple SC-206 (nadie ve el borrador de otra persona) y el escenario CU-H2-E5.

## R9. Identidad visual Aurora

- **Decisión** (paleta «azul corporativo», 2026-10-28):
  - *Colores*:

    | Uso | Color |
    |-----|-------|
    | Fondo (casi plano) | `#0B1220` → `#0F1E36` |
    | Tarjetas | `#14223A` con borde `#2A3B57` |
    | Botón principal | azul sólido `#2563EB` |
    | Enlaces, íconos y foco | azul claro `#60A5FA` |
    | Escaneo | celeste `#38BDF8` |
    | Texto | blanco, `#CBD5E1` y `#94A3B8` |
    | Estados | `#34D399` éxito, `#FBBF24` advertencia, `#F87171` error |

  - *Superficies*: tarjetas sólidas con borde fino y esquinas de 16 px, sin desenfoque.
  - *Tipografía*: Poppins (OFL) incluida en la app (sin descargas en tiempo de ejecución).
    El título lleva «HandText» en blanco y «AI» en azul claro.
  - *Animaciones*:
    - El logo-escáner, dibujado con `CustomPainter`, es un ícono azul con una hoja blanca
      y una línea de escaneo.
    - Una línea de escaneo recorre la imagen mientras se reconoce.
    - Las pantallas cambian con transiciones de desvanecimiento.
    - El fondo es fijo: sin luces de colores en movimiento.
  - *Editor, diálogos y hojas*:
    - Encabezado azul marino sólido.
    - El texto va sobre una superficie clara u oscura según el sistema, para leer textos
      largos.
    - En modo claro, los fondos y bordes son gris pizarra neutros (`#F8FAFC`,
      `#F1F5F9`, `#E2E8F0`) con texto `#0F172A` y `#475569`. Se quita el tinte lila que
      Material agrega por defecto.
    - En modo oscuro se usan los mismos azules marinos de las pantallas Aurora.
    - En ambos modos, el botón principal es el azul corporativo.
  - *Pantalla de arranque de Android*: azul marino, para que no aparezca un destello
    blanco antes del logo.
- **Decisión anterior, reemplazada**: los degradados índigo → violeta → rosa, el acento
  cian, las tarjetas de «vidrio» y las luces animadas se veían poco profesionales
  (Clarifications del spec, 2026-10-28).
- **Contraste** (SC-208): los pares de la tabla se comprueban en
  `test/theme/aurora_contrast_test.dart` con la fórmula de luminancia de WCAG 2.1. Por
  ejemplo:
  - blanco sobre el botón: 5,2:1;
  - texto secundario sobre las tarjetas: 10,7:1;
  - azul claro sobre las tarjetas: 6,3:1.
- **Accesibilidad**: si el sistema pide reducir animaciones
  (`MediaQuery.disableAnimations`), las animaciones decorativas se detienen (SC-207). Las
  pruebas usan esa misma preferencia.
- **Alternativas**: paquetes de animación como Lottie o Rive, descartados porque exigen
  archivos de diseño externos y dependencias que no se pueden justificar.
