-- Módulo catalog: servicios del catálogo de un tenant (qué se lava, en
-- cuánto tiempo, a qué precio). Precio tenant-wide en esta primera
-- versión, sin variación por sucursal (ver docs/specs/001-catalogo-servicios.md).

create table servicio (
    id                          uuid primary key,
    tenant_id                   uuid not null references tenant (id),
    nombre                      varchar(255) not null,
    descripcion                 varchar(1000),
    duracion_estimada_minutos   integer not null,
    precio                      numeric(12, 2) not null,
    moneda                      varchar(3) not null,
    activo                      boolean not null default true
);

create index idx_servicio_tenant_id on servicio (tenant_id);

-- Row Level Security: mismo mecanismo que `sucursal` (V1__tenant_management.sql)
-- y `usuario` (V2__identity_access.sql) — ver esos archivos para el porqué
-- de cada cláusula.
alter table servicio enable row level security;
alter table servicio force row level security;

create policy tenant_isolation on servicio
    using (tenant_id = current_setting('app.current_tenant_id', true)::uuid);

-- Rol de aplicación no-superusuario (ver V3__app_role.sql, tenant-management):
-- sin este grant, RLS bloquearía TODAS las queries de lavadero_app contra esta
-- tabla nueva (a diferencia del superusuario, que las bypasearía en silencio).
grant select, insert, update, delete on servicio to lavadero_app;
