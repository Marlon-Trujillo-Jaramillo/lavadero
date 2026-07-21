package com.lavadero.identity.infrastructure.security;

import java.util.Set;
import java.util.UUID;

/**
 * Claims ya validados de un JWT, expuestos como el "details" de la {@link
 * org.springframework.security.core.Authentication} en el SecurityContext. {@code tenantId} y
 * {@code sucursalId} pueden ser {@code null} (usuarios de plataforma / sin sucursal asignada).
 */
public record JwtAuthenticatedPrincipal(
    UUID usuarioId, UUID tenantId, UUID sucursalId, Set<String> roles, String jti) {}
