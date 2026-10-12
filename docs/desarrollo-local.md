# Desarrollo local — cómo levantar todo conectado

Guía práctica para correr backend + apps Flutter localmente, con datos de
prueba. Ver también `docs/specs/*.md` (qué se construyó y por qué) y
`docs/adr/0001-modular-monolith.md` (arquitectura general).

## 1. Requisitos de entorno (una sola vez por máquina)

- **Java 21**: instalado vía `brew install openjdk@21`, pero no está en el
  PATH por defecto. Antes de cualquier comando de Gradle:
  ```bash
  export JAVA_HOME="/opt/homebrew/opt/openjdk@21/libexec/openjdk.jdk/Contents/Home"
  export PATH="$JAVA_HOME/bin:$PATH"
  ```
- **Docker**: no hay Docker Desktop instalado; se usa **Colima**
  (`brew install colima docker docker-compose`). Arrancar con `colima start`
  (una vez por sesión/reinicio de la máquina).
- **`docker compose`** (el plugin, no el binario viejo `docker-compose`)
  necesita registrarse en `~/.docker/config.json`:
  ```json
  { "cliPluginsExtraDirs": ["/opt/homebrew/lib/docker/cli-plugins"] }
  ```
- Para que **Testcontainers** (tests de RLS del backend) funcione con
  Colima, exportar antes de correr `./gradlew test`/`build`:
  ```bash
  export DOCKER_HOST="unix://$HOME/.colima/default/docker.sock"
  export DOCKER_API_VERSION="1.44"
  export TESTCONTAINERS_DOCKER_SOCKET_OVERRIDE="/var/run/docker.sock"
  ```

## 2. Levantar infra (Postgres)

```bash
export DOCKER_HOST="unix://$HOME/.colima/default/docker.sock"
cd /Users/marlontrujillojaramillo/Desarrollo/lavadero
docker compose -f infra/docker-compose.yml up -d postgres
```
(Redis/MinIO/Mailhog están en el compose para features futuras — el código
actual no los usa todavía, no hace falta levantarlos.)

## 3. Levantar el backend

```bash
export JAVA_HOME="/opt/homebrew/opt/openjdk@21/libexec/openjdk.jdk/Contents/Home"
export PATH="$JAVA_HOME/bin:$PATH"
cd backend
./gradlew :bootstrap:bootRun --args='--spring.profiles.active=dev'
```
Corre en `http://localhost:8080`. Aplica las migraciones Flyway
automáticamente (crea todas las tablas + el rol `lavadero_app`). Verificar
con `curl http://localhost:8080/actuator/health` → `{"status":"UP"}`.

## 4. Datos de prueba

**No existe todavía un flujo de auto-registro de tenants** (crear un tenant
requiere rol `SUPER_ADMIN`, y no hay ningún `SUPER_ADMIN` sembrado — es un
hueco real del producto, no solo de desarrollo local). Los datos de abajo
se sembraron a mano el 2026-07-20 en la base de dev:

- Tenant: **`lavadero-demo`** ("Lavadero Demo"), con una sucursal
  "Principal" (capacidad 2).
- Usuarios (contraseña `Test1234!` para todos):

  | Email | Rol(es) | Tenant |
  |---|---|---|
  | `admin@demo.com` | `ADMIN_TENANT` + `CLIENTE` | `lavadero-demo` |
  | `empleado@demo.com` | `EMPLEADO` (con sucursal asignada) | `lavadero-demo` |
  | `superadmin@lavadero.app` | `SUPER_ADMIN` | Ninguno (login **sin** header `X-Tenant-Slug`) |

  `SUPER_ADMIN` es una cuenta de plataforma: el dominio (`Usuario.java`)
  prohíbe que tenga `tenantId` — no se puede simplemente agregarle el rol a
  un usuario que ya pertenece a un tenant (falla con
  `IllegalArgumentException: Un SUPER_ADMIN no puede tener tenantId`). Para
  crear otra, registrar un usuario normal y luego, por SQL: `update usuario
  set tenant_id = null ...`, quitar el rol `CLIENTE` y agregar
  `SUPER_ADMIN`.

Si hay que volver a sembrar (p. ej. tras borrar el volumen de Postgres),
la secuencia es:
1. Insertar `tenant` + `sucursal` directo por SQL (`docker exec
   lavadero-postgres psql -U lavadero -d lavadero -c "..."`), usando el
   plan sembrado `00000000-0000-0000-0000-000000000001`.
2. Crear el primer usuario con el endpoint REAL `POST /api/v1/auth/register`
   (con header `X-Tenant-Slug`) — así el hash de contraseña (Argon2, no
   bcrypt) queda correcto; nunca escribirlo a mano.
3. Elevar el rol con `insert into usuario_rol (usuario_id, rol) values
   (..., 'ADMIN_TENANT')` (o `EMPLEADO`, y en ese caso también `update
   usuario set sucursal_id = ...`).

## 5. Correr `admin_web`

```bash
cd admin_web
flutter run -d chrome --dart-define=API_BASE_URL=http://localhost:8080
```
En el login, tenant slug = `lavadero-demo`.

## 6. Correr `mobile_app`

`API_BASE_URL` es sobreescribible por `--dart-define` en los tres entry
points (`main_dev.dart`/`main_staging.dart`/`main_prod.dart`) sin tocar el
código — cada uno mantiene su URL real como valor por defecto.

- **Emulador Android**: usar `10.0.2.2` (así ve el emulador al `localhost`
  de la máquina host, no `localhost` directo):
  ```bash
  flutter emulators --launch Medium_Phone   # si no hay uno ya corriendo
  cd mobile_app
  flutter run -t lib/main_dev.dart -d emulator-5554 \
    --dart-define=API_BASE_URL=http://10.0.2.2:8080
  ```
- **Simulador iOS / Chrome / macOS**: `localhost` funciona directo:
  ```bash
  flutter run -t lib/main_dev.dart -d <device> \
    --dart-define=API_BASE_URL=http://localhost:8080
  ```

## 7. Bugs encontrados y corregidos al probar la app real (2026-07-20/21)

Ninguno de estos lo detectaron los tests de la sesión (todos corren contra
un `@SpringBootApplication` acotado a un solo módulo) — solo aparecieron al
arrancar `com.lavadero.bootstrap.Application` completo por primera vez:

1. `Application.java` necesitaba `@EnableJpaRepositories`/`@EntityScan`
   explícitos (el `scanBasePackages` de `@SpringBootApplication` no alcanza
   al descubrimiento de repositorios/entidades de Spring Data JPA).
2. `bootstrap` necesitaba `spring-boot-starter-data-jpa` como dependencia
   directa (no solo transitiva).
3. 4 entidades JPA (`Sucursal`, `Usuario`, `Servicio`, `Reserva`)
   declaraban el mismo `@FilterDef` — Hibernate lo rechaza cuando conviven
   en una sola unidad de persistencia. Ahora solo `SucursalJpaEntity` lo
   declara; las demás solo lo referencian con `@Filter`.
4. Faltaba `org.bouncycastle:bcprov-jdk18on` en runtime (lo necesita
   `Argon2PasswordEncoder`).
5. **El más importante**: `LoginUseCase`, `RegistrarClienteUseCase` y
   `RefreshTokenUseCase` (los tres endpoints públicos, sin JWT todavía)
   nunca fijaban `TenantContext` antes de tocar `usuario` (RLS + FORCE) —
   login/registro de cualquier usuario que no fuera `SUPER_ADMIN` nunca
   habría funcionado contra RLS real, en ningún ambiente. Para el refresh
   hubo que denormalizar `tenant_id` en `refresh_token` (migración V7) para
   resolver un huevo-y-gallina (necesitaba saber el tenant para leer
   `usuario`, pero solo lo sabía leyendo `usuario`).

Ya verificado de punta a punta: registro, login, refresh, CRUD autenticado
de catálogo, creación de reservas — todo funciona contra Postgres real con
RLS real.

## 7b. Bugs encontrados y corregidos probando gestión de planes / SUPER_ADMIN (2026-08-08)

Dos bugs más, otra vez invisibles a toda la suite de tests hasta que se
ejercitó por primera vez un login real de `SUPER_ADMIN` (nunca antes
probado — no existía ninguna cuenta así):

6. **`set_config('app.current_tenant_id', <uuid>, true)` (alcance LOCAL a
   la transacción, ver `TenantAwareTransactionAspect`) revierte a `''`
   (string vacío), no a `NULL`, cuando termina la transacción que lo fijó**
   — comportamiento real de Postgres para parámetros de sesión "custom" la
   primera vez que se tocan en una conexión. Como HikariCP reutiliza
   conexiones, cualquier conexión que sirvió una request de un tenant
   normal quedaba con `app.current_tenant_id = ''`; la siguiente request de
   plataforma (SUPER_ADMIN, sin tenant) que reusara esa conexión rompía con
   `invalid input syntax for type uuid: ""` en las 4 políticas RLS
   (`sucursal`, `usuario`, `servicio`, `reserva`). Fix: `nullif(..., '')`
   antes del cast a `uuid` en las 4 políticas — migraciones V8 (tenant-
   management), V9 (identity-access), V10 (catalog), V11 (scheduling); una
   por módulo porque los tests de integración de cada módulo corren Flyway
   solo contra sus propias migraciones.
7. **`@PreAuthorize` deniega lanzando `AuthorizationDeniedException`, no
   `ForbiddenException`** — `GlobalExceptionHandler` no tenía handler para
   esa excepción, así que caía en el catch-all genérico y devolvía 500 en
   vez de 403 para CUALQUIER usuario autenticado sin el rol requerido, en
   CUALQUIER endpoint `@PreAuthorize` de toda la API. Nunca se había hecho
   una llamada real con un rol insuficiente contra un endpoint protegido.
   Fix: nuevo `@ExceptionHandler(AuthorizationDeniedException.class)` →
   403.

## 8. Estado / pendientes

- No hay flujo de auto-registro de tenants (ver sección 4) — hueco real de
  producto, no solo de testing local. (Mitigado parcialmente: ahora sí hay
  una forma documentada de crear un `SUPER_ADMIN`, ver sección 4.)
- Vista de agenda en `admin_web` todavía pendiente (Fase 2 solo cubrió
  `mobile_app`).
- `SENTRY_DSN` vacío — falta crear las cuentas en sentry.io (ver
  `docs/specs/004-observabilidad.md`).
- `admin_web` no se pudo verificar visualmente en este entorno (sandbox sin
  acceso a captura de pantalla de Chrome/macOS) — sí se verificó
  `flutter analyze`/`flutter test` (verdes) y, por compartir el mismo
  `LavaderoTheme`/`SubscriptionPlanController` ya probado, y el backend vía
  `curl` end-to-end (login SUPER_ADMIN, CRUD de planes, 403 por rol
  insuficiente). Falta una pasada visual manual en el navegador.
