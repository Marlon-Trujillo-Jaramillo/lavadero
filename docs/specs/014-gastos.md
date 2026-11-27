# Spec 014: Gastos y utilidad

## Estado

Implementado (2026-11-26). Incluye `GastoUseCasesTest` (utilidad, utilidad negativa, validación de
rango) y `V26__gasto.sql` con RLS (verificada por el chequeo automático de políticas). En
`admin_web`, una tarjeta de **utilidad** en reportes y el registro/listado de gastos.

## Contexto

El dashboard y los reportes mostraban **ingresos** (reservas `COMPLETADA`), pero el dueño no sabe
si gana: un lavadero puede facturar mucho y perder plata. Faltaba registrar los **gastos
operativos** y cerrar el cálculo: `utilidad = ingresos − gastos`.

## Requisitos

- **Gasto:** fecha, categoría, descripción (1–120), monto (> 0, COP) y, opcional, una sucursal
  (sin sucursal = gasto general del negocio).
- **Categorías:** `ARRIENDO`, `NOMINA`, `INSUMOS`, `SERVICIOS_PUBLICOS`, `MANTENIMIENTO`, `OTRO`.
- **Resumen financiero** de un rango `[desde, hasta]` (inclusive, días en UTC como el resumen de
  ventas): `ingresos`, `gastos` y `utilidad` (puede ser negativa).
- **Alcance:** el dueño (`ADMIN_TENANT`) ve todo el tenant; el `ADMIN_SUCURSAL` queda limitado a su
  sucursal, igual que en reportes de ventas. Multi-tenant aislado por RLS (`tenant_id`).

## API

- `POST /api/v1/gastos` — registra un gasto. `ADMIN_SUCURSAL`/`ADMIN_TENANT`.
- `GET /api/v1/gastos?desde&hasta[&sucursalId]` — gastos del rango, el más reciente primero.
- `GET /api/v1/finanzas/resumen?desde&hasta[&sucursalId]` — `{ ingresos, gastos, utilidad, moneda }`.

## Diseño

- Módulo `scheduling` (junto al resumen de ventas, del que la utilidad reutiliza los ingresos).
- Agregado `Gasto` (dominio puro, valida monto y descripción); `GastoRepository` (save, listar,
  sumar). `ObtenerResumenFinancieroUseCase` combina `ReservaRepository.obtenerResumenVentas`
  (ingresos) y `GastoRepository.sumar` (gastos). La utilidad se expone como `BigDecimal` porque
  `Money.restar` prohíbe negativos y la utilidad sí puede serlo.
- Migración `V26__gasto.sql`: tabla `gasto` con RLS `force`, política de aislamiento por tenant,
  índices `(tenant_id, fecha)` y `(sucursal_id)`, y grants a `lavadero_app`.
