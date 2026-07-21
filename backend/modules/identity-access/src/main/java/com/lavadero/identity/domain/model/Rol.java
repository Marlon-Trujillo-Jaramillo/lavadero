package com.lavadero.identity.domain.model;

/**
 * Roles de la plataforma. DECISIÓN DE DISEÑO: se modela como enum simple (no como entidad con
 * permisos granulares) porque en esta fase el conjunto de roles es fijo, conocido en tiempo de
 * compilación y no hay requisito de permisos configurables por tenant; un enum es más simple, más
 * seguro (no se puede insertar un rol inválido) y suficiente. Si en el futuro se necesitan permisos
 * granulares/configurables por tenant, este enum puede evolucionar a una entidad `Rol` con una
 * tabla `permiso` asociada sin romper la API pública de `Usuario` (que expone {@code Set<Rol>}).
 */
public enum Rol {
  CLIENTE,
  EMPLEADO,
  ADMIN_SUCURSAL,
  ADMIN_TENANT,
  SUPER_ADMIN
}
