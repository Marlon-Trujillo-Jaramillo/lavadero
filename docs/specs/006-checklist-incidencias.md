# Spec 006: Checklist de servicio e Incidencias (empleado)

## Estado

En construcción — dos de las tres pestañas de `mobile_app` (rol EMPLEADO) eran
`ComingSoonPlaceholder` ("Turnos" ya se resolvió con la agenda de Fase 2); esta spec cubre las
otras dos.

## Contexto

El rol EMPLEADO es quien opera el lavadero día a día — que dos tercios de su app digan
"Próximamente" es el hueco de producto más visible detectado en la auditoría de convenciones
(ver `quality-audit`). Ninguna de las dos necesita un módulo nuevo: ambas cuelgan de `Reserva`
(o, en el caso de una incidencia sin reserva asociada, de la sucursal), así que viven en
`modules/scheduling` — no se justifica un bounded context nuevo para dos tablas pequeñas.

## Requisitos

### Checklist de servicio

- Lista fija de tareas estándar (no configurable por tenant en esta fase — YAGNI hasta que un
  tenant real lo pida): exterior lavado, interior aspirado, llantas, secado, aromatizante.
- El empleado marca/desmarca cada tarea para una reserva concreta. No hay restricción de que la
  reserva esté `EN_PROGRESO` — el empleado puede revisarlo antes o después también (más simple
  que modelar otra máquina de estados).
- No bloquea `completar()` de la reserva — el checklist es informativo, no una validación dura,
  para no acoplar dos conceptos que pueden evolucionar por separado.

### Incidencias

- El empleado reporta un problema durante o después de un servicio: categoría fija (daño al
  vehículo, cliente ausente, insumo faltante, otro) + descripción libre.
- Puede o no estar asociada a una reserva concreta (un insumo faltante no tiene reserva).
- El empleado ve sus propias incidencias reportadas (mismo patrón que "Mis reservas" del
  cliente: filtro por quien la reportó, no por sucursal — evita necesitar el mecanismo de
  `hasSucursal` para una vista de solo lectura de bajo riesgo).
- Sin vista de admin en esta fase (fast-follow si se necesita: `GET` por sucursal/tenant ya
  quedaría trivial de agregar sobre el mismo repositorio).

## Diseño técnico

Dos aggregates nuevos en `modules/scheduling`, mismo patrón que `Reserva`
(`domain → application → infrastructure → interfaces`, RLS estándar, `@Transactional` explícito):

- `ChecklistItem` (tenant_id, reserva_id, tipo, completado, completado_en) — una fila por
  (reserva, tipo) marcada; los tipos no marcados se completan con default `completado=false` al
  leer (no se pre-siembran filas para los 5 tipos de cada reserva).
- `Incidencia` (tenant_id, sucursal_id, reserva_id nullable, reportado_por, categoria,
  descripcion, creado_en).

Endpoints:

- `GET /api/v1/agenda/reservas/{id}/checklist` — EMPLEADO/ADMIN_SUCURSAL/ADMIN_TENANT
- `PATCH /api/v1/agenda/reservas/{id}/checklist/{tipo}` — ídem, body `{"completado": true}`
- `POST /api/v1/incidencias` — ídem
- `GET /api/v1/incidencias/mias` — ídem

`mobile_app`: `ChecklistScreen` reemplaza su placeholder mostrando el checklist de la reserva
`EN_PROGRESO` más reciente del empleado (si no hay ninguna, `EmptyState`); `IncidentsScreen`
reemplaza el suyo con lista de incidencias propias + FAB para reportar una nueva.
