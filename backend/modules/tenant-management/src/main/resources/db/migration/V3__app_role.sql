-- Rol de aplicación NO-superusuario para las conexiones JPA/Hikari en
-- runtime. CRÍTICO para que Row Level Security realmente aísle tenants:
-- Postgres SIEMPRE bypasea RLS para superusuarios, incluso con `FORCE ROW
-- LEVEL SECURITY` (esa cláusula solo fuerza la política para el DUEÑO de
-- la tabla cuando NO es superusuario; a un superusuario nunca lo fuerza).
-- El rol que corre esta migración (`lavadero`, ver application-dev.yml /
-- infra/docker-compose.yml) es superusuario porque es el bootstrap user de
-- la imagen oficial de Postgres — sirve para migraciones DDL, pero JAMÁS
-- debe usarse para las queries de negocio o RLS queda completamente
-- bypaseado (ver SucursalRlsIntegrationTest, que reprodujo justo este bug).
--
-- La contraseña de desarrollo/test se versiona en claro a propósito, igual
-- que 'lavadero'/'lavadero' en infra/docker-compose.yml: es un valor
-- descartable de entorno local, nunca reusado en un ambiente real (ahí
-- debe inyectarse vía secret manager, mismo patrón que
-- LAVADERO_SECURITY_JWT_SECRET).
do $$
begin
    if not exists (select 1 from pg_roles where rolname = 'lavadero_app') then
        create role lavadero_app login password 'lavadero_app' nosuperuser;
    end if;
end
$$;

grant usage on schema public to lavadero_app;

grant select, insert, update, delete
    on tenant, subscription_plan, subscription_plan_feature, sucursal
    to lavadero_app;
