-- V16 y V17 se escribieron con la política vieja (sin nullif) y reintrodujeron el bug que V8-V11
-- ya habían corregido: en una conexión del pool que viene de una transacción con tenant,
-- current_setting(..., true) devuelve '' (no NULL) y el cast ''::uuid revienta con un 500.
-- Ver V8__fix_rls_local_setting_reset.sql (tenant-management) para la explicación completa.
drop policy tenant_isolation on checklist_item;
create policy tenant_isolation on checklist_item
    using (tenant_id = nullif(current_setting('app.current_tenant_id', true), '')::uuid);

drop policy tenant_isolation on incidencia;
create policy tenant_isolation on incidencia
    using (tenant_id = nullif(current_setting('app.current_tenant_id', true), '')::uuid);

-- FKs sin índice (convención: toda FK/columna de lookup lleva el suyo). reserva.servicio_id lo usa
-- el reporte de ventas en su join, y borrar/actualizar un servicio escanea reserva sin él.
create index idx_reserva_servicio_id on reserva (servicio_id);
create index idx_incidencia_sucursal_id on incidencia (sucursal_id);
create index idx_incidencia_reserva_id on incidencia (reserva_id);
