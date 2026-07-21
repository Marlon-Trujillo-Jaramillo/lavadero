package com.lavadero.contracts.tenant;

import com.lavadero.shared.domain.DomainEvent;
import java.time.Instant;
import java.util.UUID;

/**
 * Publicado por `tenant-management` cuando el onboarding de un nuevo tenant se completa (tenant +
 * sucursal principal creados). Otros módulos (p. ej. `identity-access`, o en el futuro `billing`)
 * pueden reaccionar a este evento sin que `tenant-management` conozca sus detalles.
 */
public record TenantCreadoEvent(UUID tenantId, String slug, String nombre, Instant occurredOn)
    implements DomainEvent {

  public static TenantCreadoEvent of(UUID tenantId, String slug, String nombre) {
    return new TenantCreadoEvent(tenantId, slug, nombre, Instant.now());
  }
}
