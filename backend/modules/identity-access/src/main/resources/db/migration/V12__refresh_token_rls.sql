-- `refresh_token` ganó `tenant_id` en V7__refresh_token_tenant_id.sql pero
-- nunca activó Row Level Security: la única tabla tenant-scoped del
-- proyecto que quedaba sin la barrera real (RLS), en contra de lo que
-- ADR 0001 declara como el mecanismo infranqueable de aislamiento. Hoy no
-- era explotable (las queries filtran por hash único o por un usuarioId ya
-- de confianza), pero es la misma clase de hueco silencioso que causó el
-- incidente de julio: nada a nivel de base de datos impedía una fuga si
-- una query futura ensanchara ese filtro.
--
-- Mismo patrón two-branch que `usuario` (V2__identity_access.sql,
-- corregido en V9__fix_rls_local_setting_reset.sql): tenant_id es nullable
-- (nulo solo para refresh tokens de un SUPER_ADMIN), y se escribe
-- directamente con el `nullif(..., '')` de la corrección de V9 — no hace
-- falta reproducir aquí el bug ya conocido y luego corregirlo en dos pasos.
alter table refresh_token enable row level security;
alter table refresh_token force row level security;

create policy tenant_isolation on refresh_token
    using (
        tenant_id = nullif(current_setting('app.current_tenant_id', true), '')::uuid
        or (
            nullif(current_setting('app.current_tenant_id', true), '') is null
            and tenant_id is null
        )
    );
