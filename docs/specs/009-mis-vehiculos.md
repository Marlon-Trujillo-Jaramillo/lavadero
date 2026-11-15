# Spec 009: Mis vehículos

## Estado

Implementado (2026-11-15). `./gradlew build` verde (incluye `VehiculoTest`, `VehiculoUseCasesTest`,
`VehiculoRlsIntegrationTest` y el chequeo automático de RLS de `RlsPoliticasIntegrationTest`);
`flutter analyze --fatal-infos` y `flutter test` verdes en `lavadero_core`, `mobile_app` y
`admin_web`.

## Contexto

"Mis vehículos" era el único `ComingSoonPlaceholder` que veía el cliente. Su texto prometía tres
cosas: guardar los autos una vez, reservar eligiendo el auto y que el lavadero sepa qué carro llega.

## Requisitos

- El cliente agrega vehículos (placa + tipo obligatorios; marca y color opcionales), los ve y los
  quita.
- **Quitar archiva, no borra**: las reservas que usaron el vehículo lo siguen referenciando.
- Un cliente no puede tener dos vehículos **activos** con la misma placa en el mismo lavadero; uno
  archivado sí se puede volver a registrar.
- Al reservar, el vehículo es **opcional**. Se propone el más reciente y se puede elegir otro, "Sin
  vehículo" o agregar uno nuevo sin salir del flujo.
- El empleado y el dueño ven la placa en la agenda.

## Diseño técnico

Vive en `modules/scheduling` (mismo criterio de la spec 006: dos conceptos pequeños atados a
`Reserva` no justifican un bounded context nuevo).

| Pieza | Decisión |
|---|---|
| `Placa` (value object) | Se normaliza (mayúsculas, sin espacios ni guiones: `abc-123` → `ABC123`) y acepta 5 a 8 letras o números: carros, motos y placas especiales o extranjeras, sin atarse a un solo formato |
| `Vehiculo` (agregado) | `archivar()` en vez de borrar; `paraReserva()` falla si está archivado |
| `VehiculoReservado` | La reserva guarda `vehiculo_id` y **una copia de la placa**, igual que ya congela precio y duración: la agenda la muestra sin joins (sin N+1) y el historial no cambia si el vehículo se archiva |
| V22 | Tabla `vehiculo` con RLS (forma `nullif` de V18), índice por cada FK y un **índice único parcial** `(tenant_id, cliente_id, placa) where activo` que respalda la regla si dos peticiones llegan a la vez |
| Propiedad | El `clienteId` sale siempre del token. Archivar o reservar con un vehículo de otro cliente responde **404** (no confirma que el id exista) |

Endpoints (rol `CLIENTE`):

- `GET /api/v1/vehiculos/mios`
- `POST /api/v1/vehiculos` — `{placa, tipo, marca?, color?}`
- `DELETE /api/v1/vehiculos/{id}` — archiva
- `POST /api/v1/agenda/reservas` acepta `vehiculoId` opcional; `ReservaResponse` trae `vehiculoId`
  y `vehiculoPlaca`.

### Hallazgo corregido en el camino

Las reglas de dominio violadas (`IllegalStateException`, p. ej. completar una reserva que no ha
iniciado; `IllegalArgumentException`, p. ej. una placa inválida) caían en el 500 genérico.
`GlobalExceptionHandler` ahora las traduce a **409** y **400** con su mensaje, solo si nacen en
`com.lavadero.*.domain.*`; las de librerías siguen siendo 500 sin exponer su mensaje.

## Apps

- `lavadero_core`: `Vehiculo`, `TipoVehiculo`, `VehiculoRepository`; `Reserva` con
  `vehiculoId`/`vehiculoPlaca`; `SchedulingRepository.crear(vehiculoId:)`.
- `mobile_app`: pantalla real (lista, estado vacío con acción, formulario en hoja inferior con la
  misma validación de placa del backend, quitar con confirmación). En Reservar, paso "Vehículo
  (opcional)" y la placa en la confirmación. El empleado ve la placa en su agenda. Si cargar los
  vehículos falla, Reservar sigue funcionando sin ellos.
- `admin_web`: la placa en la agenda del día.

## Fuera de alcance

- Historial de lavados por vehículo ("cuándo toca el próximo").
- Editar un vehículo (hoy: quitar y volver a agregar).
- Tipos de vehículo configurables por lavadero y precios por tipo.
