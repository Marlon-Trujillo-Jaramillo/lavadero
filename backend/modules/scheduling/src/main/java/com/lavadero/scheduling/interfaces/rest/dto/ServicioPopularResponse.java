package com.lavadero.scheduling.interfaces.rest.dto;

import com.lavadero.scheduling.application.dto.ServicioPopularDto;
import java.util.UUID;

public record ServicioPopularResponse(UUID servicioId, String nombreServicio, long cantidad) {

  public static ServicioPopularResponse from(ServicioPopularDto dto) {
    return new ServicioPopularResponse(dto.servicioId(), dto.nombreServicio(), dto.cantidad());
  }
}
