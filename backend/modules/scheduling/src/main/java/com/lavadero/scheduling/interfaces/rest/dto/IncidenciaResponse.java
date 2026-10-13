package com.lavadero.scheduling.interfaces.rest.dto;

import com.lavadero.scheduling.application.dto.IncidenciaDto;
import java.time.Instant;
import java.util.UUID;

public record IncidenciaResponse(
    UUID id,
    UUID sucursalId,
    UUID reservaId,
    String categoria,
    String descripcion,
    Instant creadoEn) {

  public static IncidenciaResponse from(IncidenciaDto dto) {
    return new IncidenciaResponse(
        dto.id(),
        dto.sucursalId(),
        dto.reservaId(),
        dto.categoria(),
        dto.descripcion(),
        dto.creadoEn());
  }
}
