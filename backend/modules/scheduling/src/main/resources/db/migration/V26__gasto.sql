-- Gastos operativos del lavadero (arriendo, nómina, insumos, servicios públicos…). Permiten pasar
-- de "cuánto entró" (resumen de ventas) a "cuánto ganó": utilidad = ingresos - gastos. Ver
-- docs/specs/014-gastos.md.

create table gasto (
    id            uuid primary key,
    tenant_id     uuid not null references tenant (id),
    -- null = gasto general del negocio; con sucursal, se imputa a esa sucursal.
    sucursal_id   uuid references sucursal (id),
    fecha         date not null,
    categoria     varchar(24) not null,
    descripcion   varchar(120) not null,
    monto         numeric(12, 2) not null,
    moneda        varchar(3) not null,
    creado_en     timestamptz not null,
    constraint ck_gasto_categoria check (
        categoria in ('ARRIENDO', 'NOMINA', 'INSUMOS', 'SERVICIOS_PUBLICOS', 'MANTENIMIENTO', 'OTRO')),
    constraint ck_gasto_monto check (monto > 0)
);

-- Los reportes financieros filtran por tenant + rango de fechas (+ sucursal opcional).
create index idx_gasto_tenant_fecha on gasto (tenant_id, fecha);
create index idx_gasto_sucursal_id on gasto (sucursal_id);

alter table gasto enable row level security;
alter table gasto force row level security;

create policy tenant_isolation on gasto
    using (tenant_id = nullif(current_setting('app.current_tenant_id', true), '')::uuid);

grant select, insert, update, delete on gasto to lavadero_app;
