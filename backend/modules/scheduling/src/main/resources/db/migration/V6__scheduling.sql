-- Módulo scheduling: reservas de un servicio del catálogo en una sucursal,
-- para un cliente, en un horario. Precio y duración quedan congelados en la
-- fila (copiados del servicio al momento de reservar) — ver
-- docs/specs/002-agenda-reservas.md.

create table reserva (
    id                          uuid primary key,
    tenant_id                   uuid not null references tenant (id),
    sucursal_id                 uuid not null references sucursal (id),
    servicio_id                 uuid not null references servicio (id),
    cliente_id                  uuid not null references usuario (id),
    fecha_hora_inicio           timestamptz not null,
    fecha_hora_fin              timestamptz not null,
    duracion_estimada_minutos   integer not null,
    precio                      numeric(12, 2) not null,
    moneda                      varchar(3) not null,
    estado                      varchar(20) not null
);

create index idx_reserva_tenant_id on reserva (tenant_id);

-- Índice compuesto para las dos queries reales de este módulo: la agenda
-- de una sucursal en un rango (día) y la validación de solapamiento de
-- horarios al crear una reserva nueva (ver ReservaJpaRepository).
create index idx_reserva_sucursal_horario on reserva (sucursal_id, fecha_hora_inicio, fecha_hora_fin);

-- Row Level Security: mismo mecanismo que sucursal/usuario/servicio.
alter table reserva enable row level security;
alter table reserva force row level security;

create policy tenant_isolation on reserva
    using (tenant_id = current_setting('app.current_tenant_id', true)::uuid);

grant select, insert, update, delete on reserva to lavadero_app;
