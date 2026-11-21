-- Inventario de insumos: catálogo de insumos, stock por sucursal, receta de cada servicio y el
-- kardex de movimientos. Ver docs/specs/012-inventario.md.

create table insumo (
    id                  uuid primary key,
    tenant_id           uuid not null references tenant (id),
    nombre              varchar(60) not null,
    unidad              varchar(10) not null,            -- ML | G | UNIDAD
    costo_unitario      numeric(12, 4) not null,         -- por unidad: 1 ml de shampoo cuesta centavos
    moneda              varchar(3) not null,
    activo              boolean not null default true,
    creado_en           timestamptz not null,
    constraint ck_insumo_costo check (costo_unitario >= 0)
);

create index idx_insumo_tenant_id on insumo (tenant_id);
create unique index uq_insumo_nombre_activo on insumo (tenant_id, lower(nombre)) where activo;

-- Una fila por insumo y sucursal. La cantidad puede quedar negativa: un lavado no se bloquea porque
-- el conteo del sistema vaya atrasado frente a la bodega real (ver la spec).
create table stock_insumo (
    tenant_id           uuid not null references tenant (id),
    insumo_id           uuid not null references insumo (id),
    sucursal_id         uuid not null references sucursal (id),
    cantidad            numeric(14, 3) not null default 0,
    minimo              numeric(14, 3) not null default 0,
    primary key (insumo_id, sucursal_id),
    constraint ck_stock_minimo check (minimo >= 0)
);

create index idx_stock_insumo_tenant_id on stock_insumo (tenant_id);
create index idx_stock_insumo_sucursal_id on stock_insumo (sucursal_id);

-- Receta: cuánto de cada insumo gasta un servicio.
create table consumo_servicio (
    tenant_id           uuid not null references tenant (id),
    servicio_id         uuid not null references servicio (id),
    insumo_id           uuid not null references insumo (id),
    cantidad            numeric(14, 3) not null,
    primary key (servicio_id, insumo_id),
    constraint ck_consumo_cantidad check (cantidad > 0)
);

create index idx_consumo_servicio_tenant_id on consumo_servicio (tenant_id);
create index idx_consumo_servicio_insumo_id on consumo_servicio (insumo_id);

-- Kardex: cada cambio de stock con su motivo. `reserva_id` no lleva FK a `reserva` a propósito:
-- inventory no depende de scheduling (solo escucha su evento), así que tampoco su esquema.
create table movimiento_inventario (
    id                  uuid primary key,
    tenant_id           uuid not null references tenant (id),
    insumo_id           uuid not null references insumo (id),
    sucursal_id         uuid not null references sucursal (id),
    tipo                varchar(10) not null,            -- ENTRADA | CONSUMO | AJUSTE
    cantidad            numeric(14, 3) not null,         -- con signo: + entra, - sale
    saldo               numeric(14, 3) not null,         -- stock después del movimiento
    reserva_id          uuid,
    nota                varchar(120),
    creado_en           timestamptz not null,
    constraint ck_movimiento_tipo check (tipo in ('ENTRADA', 'CONSUMO', 'AJUSTE'))
);

create index idx_movimiento_tenant_id on movimiento_inventario (tenant_id);
create index idx_movimiento_insumo_sucursal_fecha
    on movimiento_inventario (insumo_id, sucursal_id, creado_en desc);
create index idx_movimiento_sucursal_id on movimiento_inventario (sucursal_id);
-- Idempotencia: una reserva descuenta cada insumo una sola vez aunque el evento llegue dos veces
-- (hoy no pasa; con Kafka la entrega es "al menos una vez").
create unique index uq_movimiento_consumo_reserva
    on movimiento_inventario (reserva_id, insumo_id)
    where tipo = 'CONSUMO';

alter table insumo enable row level security;
alter table insumo force row level security;
create policy tenant_isolation on insumo
    using (tenant_id = nullif(current_setting('app.current_tenant_id', true), '')::uuid);

alter table stock_insumo enable row level security;
alter table stock_insumo force row level security;
create policy tenant_isolation on stock_insumo
    using (tenant_id = nullif(current_setting('app.current_tenant_id', true), '')::uuid);

alter table consumo_servicio enable row level security;
alter table consumo_servicio force row level security;
create policy tenant_isolation on consumo_servicio
    using (tenant_id = nullif(current_setting('app.current_tenant_id', true), '')::uuid);

alter table movimiento_inventario enable row level security;
alter table movimiento_inventario force row level security;
create policy tenant_isolation on movimiento_inventario
    using (tenant_id = nullif(current_setting('app.current_tenant_id', true), '')::uuid);

grant select, insert, update, delete on insumo, stock_insumo, consumo_servicio,
    movimiento_inventario to lavadero_app;
