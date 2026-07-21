# Spec 002: Agenda / Reservas

## Estado

Implementado (Fase 2 del roadmap, ver `docs/specs/001-catalogo-servicios.md`).
Backend (`modules/scheduling` + endpoint `GET /api/v1/sucursales` nuevo en
tenant-management, necesario para que el cliente elija dónde reservar) y
`mobile_app` (reserva de cliente + agenda de empleado) construidos y
verificados: `./gradlew build` verde (incluye `ReservaRlsIntegrationTest`,
`ReservaTest`, `DisponibilidadServiceTest` y la nueva regla ArchUnit
`ningunOtroModuloDeNegocioDependeDeScheduling`), `flutter analyze`/`flutter
test` verdes en `lavadero_core`, `admin_web` y `mobile_app`. Pendiente:
vista de agenda en `admin_web` y smoke test manual end-to-end.

## Contexto

Con el catálogo de servicios ya construido (Fase 1), el siguiente dolor más
vendible para un lavadero pequeño/mediano es la agenda: hoy gestionan turnos
en un cuaderno o por WhatsApp, pierden clientes por no contestar a tiempo y
sobreagendan la capacidad del local. `Sucursal.capacidadSimultanea`
(tenant-management) ya existe en el dominio precisamente para esto — su
javadoc anticipa explícitamente un módulo `scheduling` sobre esta misma
entidad.

## Requisitos

- Un cliente reserva un servicio del catálogo en una sucursal, para una
  fecha/hora — la reserva se confirma en el momento (sin aprobación manual
  de un admin: fricción innecesaria para un MVP) siempre que la sucursal
  tenga capacidad libre en ese horario.
- La capacidad se respeta de verdad: no se puede reservar más allá de
  `capacidadSimultanea` reservas simultáneas (que se solapen en el tiempo)
  en la misma sucursal.
- Un empleado ve la agenda del día de su sucursal y puede marcar una
  reserva "en progreso" (el carro llegó y se está lavando) y "completada".
- Un cliente o un admin puede cancelar una reserva que no haya iniciado.
- Precio y duración se "congelan" en la reserva al momento de crearla
  (copiados del `Servicio`): si el catálogo cambia de precio después, no
  debe afectar reservas ya hechas — value objects inmutables, no una FK
  "viva" a un precio que cambia bajo los pies de una reserva pasada.

### Máquina de estados de `Reserva`

```
PENDIENTE --(empleado: iniciar)--> EN_PROGRESO --(empleado: completar)--> COMPLETADA
    |
    +--(cancelar: cliente dueño o admin/empleado)--> CANCELADA
```

(Solo se puede cancelar antes de iniciar — una vez `EN_PROGRESO` ya no.)

(Se simplifica respecto al roadmap original de la Fase 1, que mencionaba un
estado `CONFIRMADA` separado: sin flujo de aprobación manual, `PENDIENTE` ya
implica "confirmada" — capacidad ya se validó al crearla. Cuatro estados,
no cinco.)

## Diseño técnico

### Backend: nuevo módulo `modules/scheduling` (`com.lavadero.scheduling`)

A diferencia de `catalog` (deliberadamente sin dependencias de negocio),
`scheduling` sí necesita conocer `Sucursal` (capacidad) y `Servicio`
(precio/duración a congelar), así que depende de `tenant-management` y
`catalog`. También depende de `identity-access` para leer el usuario
autenticado actual (`JwtAuthenticatedPrincipal`) en la capa `interfaces` —
mismo patrón de dependencia "hacia arriba" que ya usa `identity-access` con
`tenant-management`.

- `domain/model/Reserva.java` — `AggregateRoot<UUID>`: `tenantId`,
  `sucursalId`, `servicioId`, `clienteId`, `fechaHoraInicio` (Instant),
  `duracionEstimadaMinutos` (congelada), `precio` (`Money`, congelado),
  `estado` (`ReservaEstado` enum: PENDIENTE/EN_PROGRESO/COMPLETADA/CANCELADA).
  Factory `Reserva.nueva(...)` en `PENDIENTE`. Métodos `iniciar()`,
  `completar()`, `cancelar()` que validan la transición (lanzan
  `IllegalStateException` si la transición no es válida — invariante de
  dominio, no de aplicación). `getFechaHoraFin()` calculado
  (`fechaHoraInicio + duracionEstimadaMinutos`).
- `domain/repository/ReservaRepository.java` — `findById`,
  `findAllDelTenantActual()` (admin/empleado, por sucursal+rango de fecha —
  ver `findPorSucursalYRango`), `save`.
- `domain/service/DisponibilidadService.java` (domain service, no
  aggregate): dado sucursal + rango horario + lista de reservas activas
  (PENDIENTE/EN_PROGRESO) de esa sucursal en ese rango + capacidad, decide
  si hay cupo. Vive en `domain` porque es una regla de negocio pura, sin
  I/O — el use case le pasa los datos ya cargados.
- `application/command/CrearReservaCommand`, `CancelarReservaCommand`,
  `CambiarEstadoReservaCommand`.
- `application/dto/ReservaDto`.
- `application/usecase/CrearReservaUseCase` (valida disponibilidad vía
  `DisponibilidadService`, congela precio/duración leyendo `Servicio` vía
  `ServicioRepository` de `catalog`, valida sucursal vía `SucursalRepository`
  de `tenant-management`), `IniciarReservaUseCase`,
  `CompletarReservaUseCase`, `CancelarReservaUseCase`,
  `ListarAgendaDelDiaUseCase` (por sucursal, para la vista de empleado),
  `ListarMisReservasUseCase` (por cliente, para la vista de cliente).
- `infrastructure/persistence/ReservaJpaEntity` (+ `@FilterDef`/`@Filter`
  `tenantFilter`), `ReservaJpaRepository`, `ReservaRepositoryAdapter`
  (`@Transactional` explícito por método, mismo patrón que `catalog`).
- `interfaces/rest/ReservaController` — endpoints bajo
  `/api/v1/agenda/reservas`: `POST` (cliente, crea), `GET ?sucursalId=&fecha=`
  (empleado/admin, agenda del día), `GET /mias` (cliente, sus reservas),
  `PATCH /{id}/iniciar`, `PATCH /{id}/completar` (empleado/admin),
  `PATCH /{id}/cancelar` (cliente dueño o admin/empleado). El `clienteId`
  de una reserva nueva sale de `JwtAuthenticatedPrincipal.usuarioId()`
  (`@AuthenticationPrincipal`), nunca del body de la request.
- Migración `modules/scheduling/src/main/resources/db/migration/V6__scheduling.sql`
  — tabla `reserva` con `tenant_id`, FKs a `sucursal`/`servicio`/`usuario`,
  RLS + policy + `grant ... to lavadero_app`, índice compuesto
  `(sucursal_id, fecha_hora_inicio)` para las queries de agenda/disponibilidad.
- Wiring: `settings.gradle.kts`, `bootstrap/build.gradle.kts`,
  `architecture-tests/build.gradle.kts` — igual que `catalog`.
- Tests: `ReservaTest` (dominio: transiciones de estado válidas/inválidas),
  `DisponibilidadServiceTest` (capacidad se respeta, solapamiento de
  horarios), `ReservaRlsIntegrationTest` (Testcontainers, mismo patrón
  admin/`lavadero_app` que `ServicioRlsIntegrationTest` — este módulo SÍ
  depende de `tenant-management`/`catalog`/`identity-access`, así que su
  Flyway ya trae `tenant`/`sucursal`/`servicio` sin necesitar un
  `testImplementation` extra como el que sí necesitó `catalog`).

### `admin_web` — vista de agenda (`branches` o una sección nueva)

Fuera de alcance de esta ronda de implementación — placeholder se
mantiene por ahora; ver "Roadmap" abajo. El foco de esta spec es
backend + `mobile_app` (cliente reserva, empleado gestiona el día), que es
donde está el valor de venta inmediato.

### `mobile_app` — cliente reserva (`client/booking`) y empleado gestiona el día (`employee/shifts` → se convierte en la agenda del día, ver nota)

- `packages/lavadero_core`: modelo `reserva.dart` (clase escrita a mano,
  sin codegen — mismo patrón que `service_item.dart`) + `SchedulingRepository`
  (`crear`, `misReservas`, `agendaDelDia`, `iniciar`, `completar`, `cancelar`).
- `client/booking/`: `BookingController` (Notifier) + `BookingScreen` real
  — selecciona servicio (reutiliza `catalogRepositoryProvider`), fecha/hora,
  confirma. Reemplaza el placeholder.
- Vista de empleado para la agenda del día: en vez de crear una sección
  nueva no contemplada en el roadmap original, se reutiliza
  `employee/shifts` (ya existe como placeholder "Turnos" en la bottom nav)
  como la agenda del día — es semánticamente lo mismo que necesita un
  empleado un lunes en la mañana. Si a futuro turnos de personal (quién
  trabaja cuándo) resulta ser un concepto realmente distinto, se separa
  entonces — no antes (evitar sobre-diseñar una distinción que no se ha
  necesitado todavía).

## Roadmap actualizado

- **Esta spec**: backend `scheduling` completo + `mobile_app` (cliente +
  empleado).
- **Siguiente**: vista de agenda en `admin_web` (probablemente reemplazando
  `branches_screen.dart` o como parte de `dashboard_screen.dart` — a
  decidir cuando se aborde) + Fase 3 (dashboard/reportes básicos sobre
  `Reserva` completada).
- Fases 4-5 sin cambios respecto a `001-catalogo-servicios.md`.

## Verificación

- `cd backend && ./gradlew build` — verde, incluye `ReservaTest`,
  `DisponibilidadServiceTest`, `ReservaRlsIntegrationTest` y
  `architecture-tests`.
- `cd mobile_app && flutter analyze && flutter test`.
- Invocar `rls-guardian` sobre la migración/entidad nueva y
  `architecture-guardian`/`flutter-reviewer` sobre el resto antes de
  darlo por terminado (en la próxima sesión — ver nota en memoria sobre
  que los subagentes nuevos no están disponibles hasta reiniciar sesión).
