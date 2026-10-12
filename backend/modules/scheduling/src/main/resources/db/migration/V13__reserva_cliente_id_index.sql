-- `ReservaJpaRepository.findByClienteId` respalda `GET /api/v1/agenda/reservas/mias` (mobile_app,
-- pantalla "Mis reservas") pero solo existían índices por tenant_id y por
-- (sucursal_id, fecha_hora_inicio, fecha_hora_fin) — barato hoy (poco volumen), pero esa query
-- haría table scan en cuanto un tenant acumule reservas reales.
create index idx_reserva_cliente_id on reserva (cliente_id);
