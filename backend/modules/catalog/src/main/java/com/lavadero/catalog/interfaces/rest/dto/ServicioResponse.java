package com.lavadero.catalog.interfaces.rest.dto;

import com.lavadero.catalog.application.dto.ServicioDto;
import java.math.BigDecimal;
import java.util.UUID;

public record ServicioResponse(
    UUID id,
    String nombre,
    String descripcion,
    int duracionEstimadaMinutos,
    BigDecimal precio,
    String moneda,
    boolean activo) {

  public static ServicioResponse from(ServicioDto dto) {
    return new ServicioResponse(
        dto.id(),
        dto.nombre(),
        dto.descripcion(),
        dto.duracionEstimadaMinutos(),
        dto.precio(),
        dto.moneda(),
        dto.activo());
  }
}
