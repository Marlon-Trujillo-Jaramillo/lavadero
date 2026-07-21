package com.lavadero.identity.interfaces.rest.dto;

import com.lavadero.identity.application.dto.UsuarioAutenticadoDto;
import java.util.Set;
import java.util.UUID;

public record UsuarioResponse(
    UUID id, String email, Set<String> roles, UUID tenantId, UUID sucursalId) {

  public static UsuarioResponse from(UsuarioAutenticadoDto dto) {
    return new UsuarioResponse(
        dto.id(), dto.email(), dto.roles(), dto.tenantId(), dto.sucursalId());
  }
}
