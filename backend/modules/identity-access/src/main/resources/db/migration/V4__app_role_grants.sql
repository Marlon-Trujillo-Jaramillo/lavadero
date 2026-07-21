-- Extiende al rol de aplicación (creado en V3__app_role.sql, módulo
-- tenant-management) los grants sobre las tablas de este módulo. Ver ese
-- archivo para el porqué de este rol no-superusuario: sin él, RLS queda
-- completamente bypaseado.
grant select, insert, update, delete
    on usuario, usuario_rol, refresh_token
    to lavadero_app;
