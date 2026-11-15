# Spec 008: Registro self-service de lavaderos

## Estado

Implementado (2026-11-15). `./gradlew build` verde (incluye `OnboardingTenantUseCaseIntegrationTest`
y `ValidacionAltasTest`); `flutter analyze --fatal-infos` y `flutter test` verdes en
`lavadero_core`, `admin_web` y `mobile_app`.

## Contexto

El backend ya tenía el alta self-service (`POST /api/v1/onboarding/tenants`,
`OnboardingTenantUseCase`, desde la auditoría de 2026-08-18): crea el tenant, su sucursal
principal y el primer `ADMIN_TENANT` en **una sola transacción**, con plan Starter, y devuelve los
tokens. Es público, está en la lista blanca de `SecurityConfig` y tiene rate limiting estricto en
`RateLimitFilter`.

Pero:

1. **Ninguna app lo usaba**: un lavadero nuevo seguía sin poder registrarse solo.
2. **No tenía tests**: la atomicidad "todo o nada" no estaba verificada.
3. **Los endpoints públicos de alta no validaban casi nada**: ni formato de correo ni tamaño de
   contraseña. Se podía crear una cuenta con contraseña `a` y correo `x`, y mandar contraseñas
   enormes para gastar CPU en Argon2.

## Qué se hizo

### Backend

- `LimitesCampos`: límites centralizados para los tres endpoints públicos de alta
  (`RegisterRequest`, `CrearEmpleadoRequest`, `OnboardingTenantRequest`), para que no se
  desalineen:

  | Campo | Regla |
  |---|---|
  | Email | `@Email`, máximo 254 |
  | Contraseña | 8 a 128 caracteres (el tope protege a Argon2 de entradas enormes) |
  | Nombres | máximo 120 |
  | NIT | máximo 30 |
  | Slug | 3 a 40, `^[a-z0-9]+(-[a-z0-9]+)*$` |

  El **login no** se restringe: quien ya tenga una contraseña de menos de 8 caracteres puede
  seguir entrando.
- `OnboardingTenantUseCaseIntegrationTest` (Testcontainers, Postgres real con RLS): el alta crea
  tenant + sucursal + administrador; un slug repetido falla **sin dejar nada a medias** (los
  conteos se hacen con el superusuario del contenedor, que ve todas las filas); cada alta es un
  lavadero independiente.
- `ValidacionAltasTest`: las reglas de la tabla, con el `Validator` de Jakarta.

### Apps

- `lavadero_core`: `AuthRepository.registrarLavadero` (sin `X-Tenant-Slug`: el lavadero aún no
  existe), guarda la sesión igual que el login.
- `admin_web`: pantalla **Crear cuenta** (`/registro`), enlazada desde el login. El "código del
  lavadero" (slug) se propone a partir del nombre (sin tildes ni símbolos) hasta que el usuario lo
  edita. Valida con las mismas reglas del backend antes de enviar. Al terminar, la sesión queda
  iniciada como `ADMIN_TENANT` y el router lleva al panel.
- `mobile_app`: el registro de clientes pedía mínimo 6 caracteres; ahora 8, igual que el backend.

## Fuera de alcance (siguiente iteración)

- Verificación del correo antes de activar la cuenta (necesita envío de correos; Mailhog ya está
  en `docker-compose` para desarrollo).
- Elegir plan al registrarse (hoy siempre Starter; se cambia después desde Suscripción).
- Captcha: el rate limiting cubre el abuso básico por IP.
