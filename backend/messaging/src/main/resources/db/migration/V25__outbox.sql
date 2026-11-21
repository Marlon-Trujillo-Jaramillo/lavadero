-- Outbox transaccional: el evento se guarda en la MISMA transacción que el cambio de negocio que lo
-- origina, y un relay lo publica después (Kafka o en el mismo proceso). Si la transacción se
-- revierte, el evento nunca existió; si Kafka está caído, el evento espera aquí y se reintenta.
-- Ver docs/specs/013-eventos-kafka.md.

create table outbox_evento (
    id                  uuid primary key,
    tenant_id           uuid not null references tenant (id),
    tipo                varchar(60) not null,       -- nombre estable, ver CatalogoEventos
    clave               varchar(100) not null,      -- clave de partición en Kafka
    payload             jsonb not null,
    creado_en           timestamptz not null,
    publicado_en        timestamptz,
    intentos            integer not null default 0,
    proximo_intento     timestamptz not null,
    ultimo_error        varchar(500)
);

create index idx_outbox_evento_tenant_id on outbox_evento (tenant_id);
-- La consulta del relay: pendientes cuyo próximo intento ya llegó, en orden de creación.
create index idx_outbox_evento_pendientes
    on outbox_evento (proximo_intento, creado_en)
    where publicado_en is null;

-- RLS con una excepción deliberada y acotada: el relay corre sin tenant (es un proceso del
-- sistema, no una petición) y tiene que ver los eventos de todos los lavaderos. Con un tenant
-- fijado, la política es la misma de todas las tablas: solo los de ese tenant. Ningún endpoint
-- consulta esta tabla, y el payload solo lleva ids.
alter table outbox_evento enable row level security;
alter table outbox_evento force row level security;

create policy tenant_isolation on outbox_evento
    using (
        nullif(current_setting('app.current_tenant_id', true), '') is null
        or tenant_id = nullif(current_setting('app.current_tenant_id', true), '')::uuid
    )
    with check (
        tenant_id = nullif(current_setting('app.current_tenant_id', true), '')::uuid
        or nullif(current_setting('app.current_tenant_id', true), '') is null
    );

grant select, insert, update, delete on outbox_evento to lavadero_app;
