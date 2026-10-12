package com.lavadero.tenant.domain.model;

import java.util.Optional;
import java.util.UUID;

/**
 * Genera y parsea la referencia enviada a la pasarela de pago. Embebe el {@code tenantId} a
 * propósito: el webhook de confirmación (endpoint público, sin JWT, sin {@code TenantContext}
 * poblado) necesita saber a qué tenant pertenece el pago ANTES de poder leer la fila (RLS + FORCE
 * en `pago` exige `tenant_id` ya fijado) — mismo problema "huevo y gallina" que motivó denormalizar
 * `tenant_id` en `refresh_token` (ver V7__refresh_token_tenant_id.sql, identity-access).
 *
 * <p>Separador {@code _} deliberado: un UUID solo usa hex y guiones, así que partir por guion bajo
 * es inequívoco.
 */
public final class PagoReferencia {

  private static final String PREFIJO = "pago";

  private PagoReferencia() {}

  public static String generar(UUID tenantId) {
    return PREFIJO + "_" + tenantId + "_" + UUID.randomUUID().toString().substring(0, 8);
  }

  public static Optional<UUID> extraerTenantId(String referencia) {
    if (referencia == null) {
      return Optional.empty();
    }
    String[] partes = referencia.split("_");
    if (partes.length != 3 || !PREFIJO.equals(partes[0])) {
      return Optional.empty();
    }
    try {
      return Optional.of(UUID.fromString(partes[1]));
    } catch (IllegalArgumentException e) {
      return Optional.empty();
    }
  }
}
