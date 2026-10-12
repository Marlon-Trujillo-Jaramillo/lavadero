-- Cobro de planes de suscripción (Wompi) — antes de esto no existía ninguna forma de cobrarle a
-- un tenant: `subscription_plan` era solo un catálogo administrable. `tenant_id` es NOT NULL
-- (a diferencia de `usuario`/`refresh_token`): un pago siempre pertenece a un tenant de negocio,
-- nunca a una cuenta de plataforma. Mismo patrón RLS que `sucursal`/`servicio`/`reserva`.
create table pago (
    id                      uuid primary key,
    tenant_id               uuid not null references tenant (id),
    subscription_plan_id    uuid not null references subscription_plan (id),
    monto                   numeric(12, 2) not null,
    moneda                  varchar(3) not null,
    referencia              varchar(64) not null,
    estado                  varchar(20) not null,
    transaccion_externa_id  varchar(128),
    creado_en               timestamptz not null
);

create index idx_pago_tenant_id on pago (tenant_id);

-- La referencia es lo único que Wompi devuelve en el webhook para correlacionar con este pago —
-- debe ser única globalmente, no solo por tenant.
create unique index uq_pago_referencia on pago (referencia);

alter table pago enable row level security;
alter table pago force row level security;

create policy tenant_isolation on pago
    using (tenant_id = nullif(current_setting('app.current_tenant_id', true), '')::uuid);

grant select, insert, update, delete on pago to lavadero_app;
