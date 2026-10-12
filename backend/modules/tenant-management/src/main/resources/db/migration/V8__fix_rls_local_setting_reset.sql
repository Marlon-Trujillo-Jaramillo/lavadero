-- BUG DE PRODUCCIÓN (encontrado probando login de SUPER_ADMIN por primera vez
-- en la historia del proyecto — nunca antes ejercitado, ni por tests ni
-- manualmente): `set_config('app.current_tenant_id', <uuid>, true)` fija el
-- valor con alcance LOCAL a la transacción (tercer argumento `true`, ver
-- `TenantAwareTransactionAspect`). Postgres SÍ revierte ese valor al
-- terminar la transacción (commit o rollback) — pero para un parámetro de
-- sesión "custom" (no una extensión), el valor al que revierte NO es NULL
-- sino '' (string vacío), una vez que el parámetro fue tocado alguna vez en
-- esa conexión física.
--
-- Como HikariCP reutiliza conexiones entre requests, cualquier conexión que
-- ya sirvió una transacción de un tenant normal queda con
-- `app.current_tenant_id = ''` una vez esa transacción termina. Si esa misma
-- conexión luego sirve una operación de PLATAFORMA (SUPER_ADMIN, con
-- `TenantContext` vacío — el aspecto no vuelve a fijar nada), esta política
-- intentaba `''::uuid`, lo cual Postgres rechaza con "invalid input syntax
-- for type uuid" y tumba la transacción con un 500.
--
-- Mismo fix aplicado también a `usuario` (identity-access, V9), `servicio`
-- (catalog, V10) y `reserva` (scheduling, V11) — cada uno en su propio
-- módulo porque los tests de integración de cada módulo corren Flyway solo
-- contra SUS propias migraciones (`classpath:db/migration` combinado de
-- todos los módulos solo ocurre en `bootstrap`), así que un solo archivo
-- tocando tablas de varios módulos rompería el aislamiento de esos tests.
--
-- Fix: `nullif(..., '')` antes del cast — trata '' igual que NULL, que es la
-- semántica que la política siempre quiso expresar.
drop policy tenant_isolation on sucursal;
create policy tenant_isolation on sucursal
    using (tenant_id = nullif(current_setting('app.current_tenant_id', true), '')::uuid);
