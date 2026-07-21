package com.lavadero.contracts.identity;

import com.lavadero.shared.domain.DomainEvent;
import java.time.Instant;
import java.util.UUID;

/**
 * Publicado por `identity-access` cuando un usuario nuevo (típicamente rol CLIENTE via
 * auto-registro) queda creado en un tenant. Pensado para que módulos futuros (p. ej. notificaciones
 * de bienvenida, CRM) reaccionen sin acoplarse al módulo de identidad.
 */
public record UsuarioRegistradoEvent(
    UUID usuarioId, UUID tenantId, String email, Instant occurredOn) implements DomainEvent {

  public static UsuarioRegistradoEvent of(UUID usuarioId, UUID tenantId, String email) {
    return new UsuarioRegistradoEvent(usuarioId, tenantId, email, Instant.now());
  }
}
