-- Ver V8__fix_rls_local_setting_reset.sql (tenant-management) para la
-- explicación completa del bug de `set_config(..., true)` revirtiendo a ''
-- en vez de NULL.
drop policy tenant_isolation on reserva;
create policy tenant_isolation on reserva
    using (tenant_id = nullif(current_setting('app.current_tenant_id', true), '')::uuid);
