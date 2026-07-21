# Spec 001: Catálogo de servicios

## Estado

Implementado (Slice 1 de la línea de features de negocio). Backend
(`modules/catalog`), `admin_web` (CRUD real) y `mobile_app` (lectura de
activos) construidos y verificados: `./gradlew build` verde (incluye
`ServicioRlsIntegrationTest`), `flutter analyze`/`flutter test` verdes en
ambas apps. Pendiente de smoke test manual end-to-end (backend +
docker-compose + apps corriendo) y de decidir cuándo arrancar la Fase 2.

## Contexto

El backend (auth + multi-tenancy con RLS) ya está sólido y probado (ver
`docs/adr/0001-modular-monolith.md`). Pero ninguna feature de negocio real
existe todavía: `admin_web` solo tiene auth implementado (branches,
catalog_pricing, CRM, empleados, inventario, promociones, reportes son
placeholders "coming soon"), y `mobile_app` solo tiene auth + selección de
tenant (booking, catálogo, vehículos, turnos, incidentes, checklist son
placeholders).

Objetivo del negocio: que el producto sea fácil de vender a un lavadero
pequeño/mediano, supla sus necesidades reales y les facilite la operación
diaria.

## Análisis de negocio

Necesidades de un dueño de lavadero pequeño/mediano, ordenadas por impacto
de venta + utilidad práctica:

1. **Catálogo de servicios y precios** — sin esto no existe nada más: qué
   lava, en cuánto tiempo, a qué precio. Hoy la mayoría de estos negocios
   no tiene ni una lista de precios formal. Es la base de todo lo demás.
2. **Agenda / Reservas** — el dolor más vendible: hoy gestionan turnos en
   un cuaderno o WhatsApp, pierden clientes por no contestar a tiempo,
   sobreagendan la capacidad del local. `Sucursal.capacidadSimultanea` ya
   existe en el dominio precisamente para esto — el javadoc de `Sucursal`
   ya anticipa un módulo `scheduling` sobre esta misma entidad.
3. **Órdenes de servicio / tablero del lavado en curso** — vista de
   empleado: qué carro está en qué estado (pendiente → en progreso →
   listo). Convierte una reserva en operación real, evita que un cliente
   se vaya sin saber si ya terminó su carro.
4. **Dashboard / reportes básicos** — cuánto vendí hoy/esta semana, qué
   servicio es el más pedido. Es lo que hace una demo memorable y
   justifica el precio de la suscripción ante el dueño.
5. Después: CRM con historial de clientes/fidelización, inventario,
   promociones, notificaciones (WhatsApp/push), facturación electrónica
   (regulatorio, esfuerzo grande aparte).

Reservas y órdenes de servicio dependen técnicamente de que el catálogo
exista (no se puede reservar "un lavado" sin que exista el servicio con su
precio). Por eso el catálogo es el primer bloque a construir.

## Slice 1 (esta spec): Catálogo de servicios

Backend (nuevo módulo `catalog`) + `admin_web` (CRUD real, reemplaza el
placeholder) + `mobile_app` (lectura de servicios activos, reemplaza el
placeholder del lado cliente).

### Requisitos

- Un `ADMIN_TENANT`/`ADMIN_SUCURSAL` puede crear, editar y
  activar/desactivar servicios del catálogo de su tenant (nombre,
  descripción, duración estimada, precio).
- Cualquier usuario autenticado del tenant (incluye `CLIENTE`, `EMPLEADO`)
  puede listar los servicios; el listado de administración incluye
  inactivos, el de cliente/empleado solo activos.
- El catálogo está aislado por tenant vía RLS (mismo mecanismo que
  `sucursal`/`usuario`), verificado con un test de integración real contra
  Postgres (no mock), igual que `SucursalRlsIntegrationTest`.
- El precio usa el value object `Money` (COP) ya existente en
  `shared-kernel`.

### Diseño técnico

**Backend — nuevo módulo `modules/catalog` (`com.lavadero.catalog`)**

Mismo patrón exacto que `tenant-management`. Dependencias: solo
`shared-kernel` + `contracts` (un `Servicio` solo necesita `tenantId`,
precio tenant-wide sin variación por sucursal en esta primera versión —
precio por sucursal queda como extensión futura, no se construye ahora).

- `domain/model/Servicio.java` — `AggregateRoot<UUID>`: `tenantId`,
  `nombre`, `descripcion` (nullable), `duracionEstimadaMinutos` (int > 0),
  `precio` (`Money`), `activo` (boolean). Factory `Servicio.nuevo(...)` con
  `activo = true`. Métodos `activar()`, `desactivar()`,
  `actualizarDetalles(...)`, `actualizarPrecio(Money nuevo)`.
- `domain/repository/ServicioRepository.java` — `findById`,
  `findAllDelTenantActual()`, `save`.
- `application/command/` — `CrearServicioCommand`, `ActualizarServicioCommand`,
  `CambiarEstadoServicioCommand` (records).
- `application/dto/ServicioDto.java`.
- `application/usecase/` — `CrearServicioUseCase`, `ActualizarServicioUseCase`,
  `CambiarEstadoServicioUseCase`, `ListarServiciosUseCase` (admin, todos),
  `BuscarServiciosActivosUseCase` (cliente/empleado, solo activos).
- `infrastructure/persistence/` — `ServicioJpaEntity` (con
  `@FilterDef`/`@Filter` `tenantFilter`), `ServicioJpaRepository`,
  `ServicioRepositoryAdapter` (`@Transactional` explícito por método).
- `interfaces/rest/ServicioController.java` + dto — endpoints bajo
  `/catalogo/servicios`: escritura protegida con
  `@PreAuthorize("hasAnyRole('ADMIN_TENANT','ADMIN_SUCURSAL')")`, lectura
  abierta a cualquier rol autenticado.
- Migración `modules/catalog/src/main/resources/db/migration/V5__catalog.sql`
  — tabla `servicio` con RLS + policy + `grant ... to lavadero_app`.
- Wiring: `settings.gradle.kts`, `bootstrap/build.gradle.kts`,
  `architecture-tests/build.gradle.kts`.
- Test: `ServicioRlsIntegrationTest` (Testcontainers, mismo split
  Flyway-admin/datasource-`lavadero_app` que `SucursalRlsIntegrationTest`)
  + test de dominio de `Servicio`.

**`admin_web` — `CatalogPricingScreen` real**

- `packages/lavadero_core`: modelo `service_item.dart` (Freezed) +
  repositorio `catalog_repository.dart` (mismo patrón que
  `tenant_repository.dart`).
- `catalogRepositoryProvider` en `admin_web` y `mobile_app`.
- `admin_web/lib/features/catalog_pricing/`: `CatalogPricingController`
  (Notifier) + `CatalogPricingScreen` (lista + alta/edición +
  activar/desactivar), reemplaza el placeholder en `admin_shell.dart`.

**`mobile_app` — `client/catalog/CatalogScreen` real (solo lectura)**

- `CatalogController` (Notifier, solo activos) + `CatalogScreen`
  actualizada, swap en `client_shell.dart`.

## Roadmap (fases siguientes, no en esta spec)

- **Fase 2 — Agenda/Reservas + Órdenes de servicio**: módulo `scheduling`,
  aggregate `Reserva` (`PENDIENTE→CONFIRMADA→EN_PROGRESO→COMPLETADA→CANCELADA`),
  depende de `catalog` + `tenant-management` (`capacidadSimultanea`).
- **Fase 3 — Dashboard/reportes básicos** sobre `Reserva` completada.
- **Fase 4 — CRM/fidelización, inventario, promociones**.
- **Fase 5 — Notificaciones y facturación electrónica** (regulatorio).

## Verificación

- `cd backend && ./gradlew build` — compila y pasan todos los tests,
  incluido `ServicioRlsIntegrationTest` y `architecture-tests`.
- `cd admin_web && flutter analyze && flutter test`.
- `cd mobile_app && flutter analyze && flutter test`.
- Smoke test manual: crear un servicio en `admin_web`, verlo en la lista,
  desactivarlo; confirmar que `mobile_app` (cliente) solo lista activos.
