-- Checklist de servicio: una fila por (reserva, tipo) marcado. No se pre-siembran filas para los
-- 5 tipos fijos de cada reserva (ver ChecklistItemTipo) — un tipo sin fila se interpreta como no
-- completado. Ver docs/specs/006-checklist-incidencias.md.

create table checklist_item (
    id              uuid primary key,
    tenant_id       uuid not null references tenant (id),
    reserva_id      uuid not null references reserva (id),
    tipo            varchar(30) not null,
    completado      boolean not null default false,
    completado_en   timestamptz,
    unique (reserva_id, tipo)
);

create index idx_checklist_item_tenant_id on checklist_item (tenant_id);
create index idx_checklist_item_reserva_id on checklist_item (reserva_id);

-- Row Level Security: mismo mecanismo que reserva (tenant_id no nulo, política de una sola rama).
alter table checklist_item enable row level security;
alter table checklist_item force row level security;

create policy tenant_isolation on checklist_item
    using (tenant_id = current_setting('app.current_tenant_id', true)::uuid);

grant select, insert, update, delete on checklist_item to lavadero_app;
