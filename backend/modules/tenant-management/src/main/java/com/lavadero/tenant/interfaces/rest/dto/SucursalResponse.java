package com.lavadero.tenant.interfaces.rest.dto;

import com.lavadero.tenant.application.dto.SucursalDto;
import java.util.UUID;

public record SucursalResponse(UUID id, String nombre, String direccion, int capacidadSimultanea) {

  public static SucursalResponse from(SucursalDto dto) {
    return new SucursalResponse(dto.id(), dto.nombre(), dto.direccion(), dto.capacidadSimultanea());
  }
}
