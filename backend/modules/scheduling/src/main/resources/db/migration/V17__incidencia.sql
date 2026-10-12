-- Incidencias reportadas por el staff durante/después de un servicio. reserva_id es opcional: un
-- insumo faltante no está atado a una reserva concreta. Ver docs/specs/006-checklist-incidencias.md.

create table incidencia (
    id                          uuid primary key,
    tenant_id                   uuid not null references tenant (id),
    sucursal_id                 uuid not null references sucursal (id),
    reserva_id                  uuid references reserva (id),
    reportado_por_usuario_id    uuid not null references usuario (id),
    categoria                   varchar(30) not null,
    descripcion                 text not null,
    creado_en                   timestamptz not null
);

create index idx_incidencia_tenant_id on incidencia (tenant_id);
create index idx_incidencia_reportado_por on incidencia (reportado_por_usuario_id);

-- Row Level Security: mismo mecanismo que reserva (tenant_id no nulo, política de una sola rama).
alter table incidencia enable row level security;
alter table incidencia force row level security;

create policy tenant_isolation on incidencia
    using (tenant_id = current_setting('app.current_tenant_id', true)::uuid);

grant select, insert, update, delete on incidencia to lavadero_app;
