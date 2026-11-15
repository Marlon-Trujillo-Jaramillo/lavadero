-- Vehículos del cliente ("Mis vehículos") y el vehículo elegido en cada reserva.
-- Ver docs/specs/009-mis-vehiculos.md.

create table vehiculo (
    id              uuid primary key,
    tenant_id       uuid not null references tenant (id),
    cliente_id      uuid not null references usuario (id),
    placa           varchar(8) not null,
    tipo            varchar(20) not null,
    marca           varchar(40),
    color           varchar(30),
    activo          boolean not null default true,
    creado_en       timestamptz not null
);

create index idx_vehiculo_tenant_id on vehiculo (tenant_id);
create index idx_vehiculo_cliente_id on vehiculo (cliente_id);

-- Un cliente no puede tener dos vehículos ACTIVOS con la misma placa en el mismo lavadero. Los
-- archivados no cuentan: puede volver a registrar un carro que había quitado.
create unique index uq_vehiculo_cliente_placa_activo
    on vehiculo (tenant_id, cliente_id, placa)
    where activo;

-- Row Level Security: misma política que el resto de tablas de negocio, ya con el `nullif` de
-- V9/V10/V11/V18 (una conexión del pool que tuvo tenant puede volver con '' en vez de NULL).
alter table vehiculo enable row level security;
alter table vehiculo force row level security;

create policy tenant_isolation on vehiculo
    using (tenant_id = nullif(current_setting('app.current_tenant_id', true), '')::uuid);

grant select, insert, update, delete on vehiculo to lavadero_app;

-- La reserva guarda el vehículo elegido (opcional) y una copia de su placa, igual que ya congela
-- precio y duración: la agenda la muestra sin joins y el historial no cambia si el cliente archiva
-- el vehículo después.
alter table reserva add column vehiculo_id uuid references vehiculo (id);
alter table reserva add column vehiculo_placa varchar(8);

create index idx_reserva_vehiculo_id on reserva (vehiculo_id);
