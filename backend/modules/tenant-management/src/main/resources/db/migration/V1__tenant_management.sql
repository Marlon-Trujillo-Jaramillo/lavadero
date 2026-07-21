-- Módulo tenant-management: tablas de plataforma (tenant, subscription_plan)
-- y la primera tabla de negocio con tenant_id (sucursal).
--
-- DECISIÓN DE DISEÑO: `tenant` y `subscription_plan` son datos de
-- PLATAFORMA (no pertenecen a un tenant, son la raíz), por lo tanto NO
-- llevan RLS. `sucursal` sí es un dato de negocio de un tenant específico
-- y por tanto SÍ tiene RLS habilitado.

create extension if not exists "pgcrypto";

create table tenant (
    id                    uuid primary key,
    nombre                varchar(255) not null,
    nit                   varchar(50) not null,
    slug                  varchar(100) not null unique,
    estado                varchar(20) not null,
    subscription_plan_id  uuid not null,
    fecha_creacion        timestamptz not null default now()
);

create index idx_tenant_estado on tenant (estado);

create table subscription_plan (
    id               uuid primary key,
    nombre           varchar(100) not null,
    precio           numeric(12, 2) not null,
    moneda           varchar(3) not null,
    max_sucursales   integer not null,
    max_empleados    integer not null
);

create table subscription_plan_feature (
    subscription_plan_id uuid not null references subscription_plan (id) on delete cascade,
    feature               varchar(100) not null
);

alter table tenant
    add constraint fk_tenant_subscription_plan
    foreign key (subscription_plan_id) references subscription_plan (id);

-- Plan por defecto sembrado para desarrollo/onboarding.
insert into subscription_plan (id, nombre, precio, moneda, max_sucursales, max_empleados)
values ('00000000-0000-0000-0000-000000000001', 'Starter', 99000.00, 'COP', 1, 5);

insert into subscription_plan_feature (subscription_plan_id, feature)
values ('00000000-0000-0000-0000-000000000001', 'agenda_basica'),
       ('00000000-0000-0000-0000-000000000001', 'facturacion_basica');

create table sucursal (
    id                     uuid primary key,
    tenant_id              uuid not null references tenant (id),
    nombre                 varchar(255) not null,
    direccion              varchar(255),
    capacidad_simultanea   integer not null default 1
);

create index idx_sucursal_tenant_id on sucursal (tenant_id);

-- Row Level Security: aislamiento real a nivel de base de datos. La
-- aplicación fija `app.current_tenant_id` en cada transacción de negocio
-- (ver TenantAwareTransactionAspect en identity-access) leyendo el tenant
-- del JWT ya validado. `current_setting(..., true)` retorna NULL en vez de
-- lanzar error si la variable no está seteada, para no romper operaciones
-- de plataforma que no tienen tenant (p. ej. SUPER_ADMIN listando tenants).
alter table sucursal enable row level security;
alter table sucursal force row level security;

create policy tenant_isolation on sucursal
    using (tenant_id = current_setting('app.current_tenant_id', true)::uuid);
