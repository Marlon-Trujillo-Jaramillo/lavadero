-- Ver V8__fix_rls_local_setting_reset.sql (tenant-management) para la
-- explicación completa del bug: `set_config(..., true)` revierte a '' (no
-- NULL) al terminar la transacción que lo fijó, y esa '' persiste en la
-- conexión pooled hasta la siguiente request que sí fije un tenant. Rompía
-- específicamente el login de SUPER_ADMIN (tenantId null) cuando reutilizaba
-- una conexión recién usada por un tenant normal.
drop policy tenant_isolation on usuario;
create policy tenant_isolation on usuario
    using (
        tenant_id = nullif(current_setting('app.current_tenant_id', true), '')::uuid
        or (
            nullif(current_setting('app.current_tenant_id', true), '') is null
            and tenant_id is null
        )
    );
