# Contrato de la API de cuentas — HandText AI

Complementa [001/contracts/api.md](../../001-handtext-mvp/contracts/api.md): mismo
formato de error, cabecera `X-Request-ID` y cuerpos JSON de hasta 16 KB. En caso de
error de esquema, la respuesta es `422 VALIDATION_ERROR` sin repetir ningún dato enviado.

## Autenticación de las rutas protegidas

`POST /api/v1/recognitions`, `POST /api/v1/exports`, `POST /api/v1/auth/logout`,
`GET /api/v1/auth/me` y `DELETE /api/v1/account` exigen la cabecera:

```text
Authorization: Bearer <token>
```

Sin token, o con uno inválido o vencido, la respuesta es
`401 UNAUTHENTICATED` con la cabecera `WWW-Authenticate: Bearer`.

## POST /api/v1/auth/register

```json
{ "display_name": "Ana", "email": "ana@correo.com", "password": "********", "accepts_data_policy": true }
```

**201**: `{ "token": "…", "user": { "id": "uuid", "display_name": "Ana", "email": "ana@correo.com" } }`

| HTTP | `code` | Cuándo |
|------|--------|--------|
| 400 | `INVALID_DISPLAY_NAME` | Nombre vacío o de más de 60 caracteres |
| 400 | `INVALID_EMAIL` | Formato inválido o más de 254 caracteres |
| 400 | `WEAK_PASSWORD` | Menos de 8 o más de 128 caracteres |
| 400 | `DATA_POLICY_NOT_ACCEPTED` | `accepts_data_policy` distinto de `true` |
| 409 | `EMAIL_ALREADY_REGISTERED` | Ya existe una cuenta con ese correo (sin distinguir mayúsculas) |

## POST /api/v1/auth/login

```json
{ "email": "ana@correo.com", "password": "********" }
```

**200**: igual que el registro.

| HTTP | `code` | Cuándo |
|------|--------|--------|
| 401 | `INVALID_CREDENTIALS` | Correo inexistente o contraseña incorrecta (mismo mensaje) |
| 429 | `TOO_MANY_ATTEMPTS` | Cuenta bloqueada 15 minutos tras 5 fallos seguidos |

## GET /api/v1/auth/me

**200**: `{ "user": { "id": "…", "display_name": "…", "email": "…" } }`

## POST /api/v1/auth/logout

**204** sin cuerpo. La sesión deja de ser válida.

## DELETE /api/v1/account

```json
{ "password": "********" }
```

**204**: se borran la cuenta y todas sus sesiones.
**401 `INVALID_CREDENTIALS`**: contraseña incorrecta; la cuenta se conserva.

## Errores comunes

| HTTP | `code` | Cuándo |
|------|--------|--------|
| 503 | `ACCOUNTS_UNAVAILABLE` | La base de datos no está configurada o no responde |
