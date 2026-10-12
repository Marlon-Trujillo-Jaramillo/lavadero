-- `usuario.sucursal_id` (V2__identity_access.sql) es un FK sin índice — el único caso restante
-- que no seguía la convención del proyecto de indexar toda FK/columna de lookup (ver
-- architecture-guardian). No es crítico hoy porque `ListarEmpleadosUseCase` todavía no filtra por
-- sucursal, pero esa es exactamente la mejora pendiente para que ADMIN_SUCURSAL solo vea su propio
-- staff — cuando se agregue ese filtro, esta tabla ya no hará un seq scan para resolverlo.
create index idx_usuario_sucursal_id on usuario (sucursal_id);
