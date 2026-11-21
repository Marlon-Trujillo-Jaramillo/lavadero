package com.lavadero.scheduling.interfaces.rest.dto;

import com.lavadero.scheduling.application.dto.ReservaDto;
import java.math.BigDecimal;
import java.time.Instant;
import java.util.UUID;

public record ReservaResponse(
    UUID id,
    UUID sucursalId,
    UUID servicioId,
    UUID clienteId,
    Instant fechaHoraInicio,
    Instant fechaHoraFin,
    int duracionEstimadaMinutos,
    BigDecimal precio,
    String moneda,
    String estado,
    UUID vehiculoId,
    String vehiculoPlaca,
    UUID promocionId,
    BigDecimal precioLista) {

  public static ReservaResponse from(ReservaDto dto) {
    return new ReservaResponse(
        dto.id(),
        dto.sucursalId(),
        dto.servicioId(),
        dto.clienteId(),
        dto.fechaHoraInicio(),
        dto.fechaHoraFin(),
        dto.duracionEstimadaMinutos(),
        dto.precio(),
        dto.moneda(),
        dto.estado(),
        dto.vehiculoId(),
        dto.vehiculoPlaca(),
        dto.promocionId(),
        dto.precioLista());
  }
}
