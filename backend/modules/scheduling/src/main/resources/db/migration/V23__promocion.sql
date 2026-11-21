-- Promociones: cupones con código y precios por horario (franjas de baja demanda), y la promoción
-- aplicada en cada reserva. Ver docs/specs/011-promociones.md.

create table promocion (
    id                  uuid primary key,
    tenant_id           uuid not null references tenant (id),
    nombre              varchar(60) not null,
    tipo                varchar(10) not null,     -- CUPON | HORARIO
    codigo              varchar(20),              -- solo CUPON, normalizado en mayúsculas
    tipo_descuento      varchar(12) not null,     -- PORCENTAJE | MONTO_FIJO
    valor_descuento     numeric(12, 2) not null,
    moneda              varchar(3),               -- solo MONTO_FIJO
    -- Solo HORARIO: días como máscara de bits (lunes = 1, martes = 2, miércoles = 4 ... domingo = 64)
    -- y franja [hora_desde, hora_hasta) en hora local del lavadero.
    dias_semana         integer,
    hora_desde          time,
    hora_hasta          time,
    vigente_desde       date not null,
    vigente_hasta       date not null,
    usos_maximos        integer,                  -- null = ilimitado
    usos                integer not null default 0,
    activa              boolean not null default true,
    creada_en           timestamptz not null,
    constraint ck_promocion_tipo check (tipo in ('CUPON', 'HORARIO')),
    constraint ck_promocion_cupon_con_codigo check ((tipo = 'CUPON') = (codigo is not null)),
    constraint ck_promocion_horario_con_franja check (
        (tipo = 'HORARIO') = (dias_semana is not null and hora_desde is not null and hora_hasta is not null)),
    constraint ck_promocion_vigencia check (vigente_desde <= vigente_hasta),
    -- Respaldo en la base de datos del límite de usos que reservarUso() aplica con un UPDATE condicional.
    constraint ck_promocion_usos check (usos >= 0 and (usos_maximos is null or usos <= usos_maximos))
);

create index idx_promocion_tenant_id on promocion (tenant_id);

-- Un código de cupón activo es único dentro del lavadero (dos lavaderos pueden usar "BIENVENIDA").
create unique index uq_promocion_codigo_activo
    on promocion (tenant_id, codigo)
    where activa and codigo is not null;

alter table promocion enable row level security;
alter table promocion force row level security;

create policy tenant_isolation on promocion
    using (tenant_id = nullif(current_setting('app.current_tenant_id', true), '')::uuid);

grant select, insert, update, delete on promocion to lavadero_app;

-- La reserva guarda la promoción aplicada y el precio de lista: `precio` sigue siendo lo que se
-- cobra (los reportes de ventas no cambian) y `precio_lista - precio` es el descuento.
alter table reserva add column promocion_id uuid references promocion (id);
alter table reserva add column precio_lista numeric(12, 2);

create index idx_reserva_promocion_id on reserva (promocion_id);
