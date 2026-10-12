package com.lavadero.identity.interfaces.rest.dto;

import com.lavadero.identity.application.dto.EmpleadoDto;
import java.util.UUID;

public record EmpleadoResponse(
    UUID id, String email, String nombre, UUID sucursalId, String estado) {

  public static EmpleadoResponse from(EmpleadoDto dto) {
    return new EmpleadoResponse(
        dto.id(), dto.email(), dto.nombre(), dto.sucursalId(), dto.estado());
  }
}
