# Spec 003: Dashboard / reportes básicos

## Estado

Implementado. `./gradlew build` verde (incluye `ReporteVentasIntegrationTest`),
`flutter analyze`/`flutter test` verdes en `lavadero_core` y `admin_web`.
Pendiente: smoke test manual end-to-end.

## Contexto

Con catálogo (Fase 1) y agenda/reservas (Fase 2) ya construidos, lo que
hace una demo memorable — y justifica el precio de la suscripción ante el
dueño — es que vea, sin esfuerzo, cuánto vendió y qué se pide más.

## Requisitos

- Un admin (`ADMIN_TENANT`/`ADMIN_SUCURSAL`) ve, para un rango de fechas:
  ingresos totales, número de reservas completadas, y el top de servicios
  más pedidos.
- `admin_web/dashboard`: el resumen de **hoy**, sin selección de rango
  (KPIs rápidos al abrir la app).
- `admin_web/reports`: el mismo resumen pero con selector de rango de
  fechas (por defecto, esta semana).
- Se agregan solo reservas `COMPLETADA` — una `CANCELADA` o `PENDIENTE`
  nunca cuenta como venta.
- Simplificación deliberada (no soportada aún): un solo tenant = una sola
  moneda. Si en el futuro un tenant opera en varias monedas, esto necesita
  rediseño (agrupar por moneda, no solo sumar).

## Diseño técnico

Vive en `modules/scheduling` (ya es dueño de `Reserva`) — no se crea un
módulo `reporting` nuevo, sería una capa sin responsabilidad propia sobre
datos que ya pertenecen a `scheduling`.

- `domain/model/ResumenVentas.java`, `domain/model/ServicioPopular.java` —
  value objects de solo lectura (no aggregates, no tienen identidad ni
  ciclo de vida propio).
- `domain/repository/ReservaRepository.java` — nuevo método
  `obtenerResumenVentas(Instant desde, Instant hasta)`.
- `infrastructure/persistence/ReservaJpaRepository.java` — la
  implementación usa **queries nativas SQL** (`@Query(nativeQuery = true)`)
  que hacen `JOIN` directo `reserva`/`servicio` a nivel de base de datos.
  Esto es una excepción deliberada al patrón "un módulo llama al caso de
  uso de otro, nunca a sus tablas" (ver `docs/specs/002-agenda-reservas.md`):
  ese patrón aplica a *escritura*/lógica de negocio cruzando módulos en
  código Java; para una *lectura* agregada de reporting, hacer el JOIN en
  SQL (mismo motor, mismo schema — el monolito modular lo permite, ver
  ADR 0001) es más simple y eficiente que traer todo a memoria y unir en
  Java. RLS sigue aplicando igual (es a nivel de conexión/sesión de
  Postgres, no de la forma de la query).
- `application/dto/ResumenVentasDto.java`, `ServicioPopularDto.java`,
  `application/command/ResumenVentasQuery.java` (desde, hasta),
  `application/usecase/ObtenerResumenVentasUseCase.java`.
- `interfaces/rest`: `GET /api/v1/agenda/reportes/resumen?desde=&hasta=`
  (fechas ISO), restringido a `ADMIN_TENANT`/`ADMIN_SUCURSAL`.
- `admin_web`: `lavadero_core` gana `ResumenVentas` (modelo a mano, sin
  codegen) + método en `SchedulingRepository`. `DashboardScreen` (KPIs de
  hoy) y `ReportsScreen` (con selector de rango) reemplazan sus
  placeholders.

## Verificación

- `cd backend && ./gradlew build` — verde, incluye un test de integración
  de la query agregada (Testcontainers, con datos reales de dos reservas
  completadas y una cancelada, verificando que la cancelada no cuenta).
- `cd admin_web && flutter analyze && flutter test`.
