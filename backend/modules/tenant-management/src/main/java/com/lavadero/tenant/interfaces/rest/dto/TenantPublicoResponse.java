package com.lavadero.tenant.interfaces.rest.dto;

import com.lavadero.tenant.application.dto.TenantResumenDto;
import java.util.UUID;

/** Respuesta pública: nunca expone NIT, plan ni estado interno del tenant. */
public record TenantPublicoResponse(UUID id, String slug, String nombre) {

  public static TenantPublicoResponse from(TenantResumenDto dto) {
    return new TenantPublicoResponse(dto.id(), dto.slug(), dto.nombre());
  }
}
