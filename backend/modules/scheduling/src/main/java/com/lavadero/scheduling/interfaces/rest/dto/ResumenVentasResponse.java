package com.lavadero.scheduling.interfaces.rest.dto;

import com.lavadero.scheduling.application.dto.ResumenVentasDto;
import java.math.BigDecimal;
import java.util.List;

public record ResumenVentasResponse(
    BigDecimal ingresosTotales,
    String moneda,
    int totalReservasCompletadas,
    List<ServicioPopularResponse> serviciosMasPedidos) {

  public static ResumenVentasResponse from(ResumenVentasDto dto) {
    return new ResumenVentasResponse(
        dto.ingresosTotales(),
        dto.moneda(),
        dto.totalReservasCompletadas(),
        dto.serviciosMasPedidos().stream().map(ServicioPopularResponse::from).toList());
  }
}
