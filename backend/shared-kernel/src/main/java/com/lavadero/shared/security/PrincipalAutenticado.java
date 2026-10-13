package com.lavadero.shared.security;

import java.util.Set;
import java.util.UUID;

/**
 * Claims ya validados de un JWT, expuestos como principal de la {@code Authentication} en el
 * SecurityContext. {@code tenantId} y {@code sucursalId} pueden ser {@code null} (usuarios de
 * plataforma / sin sucursal asignada).
 *
 * <p>Vive en shared-kernel (no en identity-access) porque los controladores y comandos de otros
 * módulos lo consumen: importarlo desde la infraestructura de identity-access acoplaba módulos.
 */
public record PrincipalAutenticado(
    UUID usuarioId, UUID tenantId, UUID sucursalId, Set<String> roles, String jti) {}
