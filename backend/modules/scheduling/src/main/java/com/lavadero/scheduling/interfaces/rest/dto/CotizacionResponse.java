package com.lavadero.scheduling.interfaces.rest.dto;

import com.lavadero.scheduling.application.dto.CotizacionDto;
import java.math.BigDecimal;
import java.util.UUID;

public record CotizacionResponse(
    BigDecimal precioLista,
    BigDecimal descuento,
    BigDecimal precioFinal,
    String moneda,
    UUID promocionId,
    String promocionNombre) {

  public static CotizacionResponse from(CotizacionDto d) {
    return new CotizacionResponse(
        d.precioLista(),
        d.descuento(),
        d.precioFinal(),
        d.moneda(),
        d.promocionId(),
        d.promocionNombre());
  }
}
