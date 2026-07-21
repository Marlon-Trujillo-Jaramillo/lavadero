-- Módulo identity-access: usuario (con tenant_id NULLABLE), sus roles
-- (usuario_rol) y refresh_token (solo se persiste el hash, nunca el token
-- en claro).
--
-- POLÍTICA RLS CON tenant_id NULLABLE (a diferencia de `sucursal` en V1,
-- donde tenant_id siempre es NOT NULL): `tenant_id` es nulo ÚNICAMENTE para
-- cuentas de plataforma (rol SUPER_ADMIN, ver Usuario.java). La política de
-- abajo cubre los dos escenarios:
--   1) Hay un tenant activo en la sesión (`app.current_tenant_id` seteado
--      vía `set_config(..., true)` por TenantAwareTransactionAspect, que
--      equivale a un `SET LOCAL` con alcance de transacción): solo son
--      visibles las filas de ESE tenant. Las filas SUPER_ADMIN (tenant_id
--      NULL) quedan invisibles: nunca deben mezclarse con los usuarios de
--      negocio de un tenant, ni siquiera para lecturas administrativas.
--   2) NO hay tenant activo (contexto de plataforma, p. ej. login de un
--      SUPER_ADMIN sin header X-Tenant-Slug, o el propio login intentando
--      resolver esa cuenta): solo son visibles las filas con tenant_id
--      NULL. Sin esta segunda rama, `tenant_id = NULL` evaluaría a
--      desconocido/false en SQL y ninguna fila sería visible nunca para
--      cuentas de plataforma.
-- `current_setting(..., true)` retorna NULL en vez de lanzar error cuando
-- la variable no está seteada (igual que en V1__tenant_management.sql).

create table usuario (
    id              uuid primary key,
    tenant_id       uuid references tenant (id),
    email           varchar(255) not null,
    nombre          varchar(255) not null,
    password_hash   varchar(255) not null,
    mfa_enabled     boolean not null default false,
    estado          varchar(20) not null,
    sucursal_id     uuid references sucursal (id)
);

create index idx_usuario_tenant_id on usuario (tenant_id);

-- Unicidad de email dentro de un mismo tenant. Postgres trata cada NULL
-- como distinto en un índice único normal, así que este índice NO impide
-- duplicados entre filas con tenant_id NULL (ver el siguiente índice
-- parcial para ese caso).
create unique index uq_usuario_tenant_email on usuario (tenant_id, email);

-- Unicidad de email entre cuentas de plataforma (tenant_id NULL).
create unique index uq_usuario_email_plataforma on usuario (email) where tenant_id is null;

alter table usuario enable row level security;
alter table usuario force row level security;

create policy tenant_isolation on usuario
    using (
        tenant_id = current_setting('app.current_tenant_id', true)::uuid
        or (
            current_setting('app.current_tenant_id', true) is null
            and tenant_id is null
        )
    );

-- Roles: en el dominio, `Usuario.roles` es un `Set<Rol>` (Rol es un enum
-- fijo, ver comentario de diseño en Rol.java: no hay permisos granulares
-- configurables en esta fase). Se persiste como tabla de colección simple,
-- mismo patrón que `subscription_plan_feature` en V1, no como catálogo con
-- FK propia.
create table usuario_rol (
    usuario_id  uuid not null references usuario (id) on delete cascade,
    rol         varchar(30) not null,
    primary key (usuario_id, rol)
);

-- Refresh tokens: NUNCA se guarda el valor en claro, solo su hash SHA-256
-- en base64 (ver TokenHasher). `creado_por_token_anterior_id` enlaza la
-- cadena de rotación para poder revocarla completa ante reuso (ver
-- RefreshTokenUseCase).
create table refresh_token (
    id                              uuid primary key,
    usuario_id                      uuid not null references usuario (id) on delete cascade,
    token_hash                      varchar(255) not null unique,
    expira_en                       timestamptz not null,
    revocado                        boolean not null default false,
    creado_por_token_anterior_id    uuid references refresh_token (id)
);

create index idx_refresh_token_usuario_id on refresh_token (usuario_id);
