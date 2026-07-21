-- `refresh_token` no tenía `tenant_id`: al refrescar tokens (endpoint
-- público, sin JWT todavía) hay que leer `usuario` por id, tabla con RLS
-- + FORCE — sin saber el tenant de antemano, esa lectura queda bloqueada
-- (huevo-y-gallina: para saber el tenant había que leer usuario, que
-- exige ya saber el tenant). Se denormaliza aquí (poblado al emitir el
-- token, ver TokenIssuer) para poder fijar app.current_tenant_id ANTES de
-- leer usuario en RefreshTokenUseCase. Nullable, igual que
-- usuario.tenant_id (nulo solo para refresh tokens de un SUPER_ADMIN).
alter table refresh_token add column tenant_id uuid references tenant (id);

create index idx_refresh_token_tenant_id on refresh_token (tenant_id);
