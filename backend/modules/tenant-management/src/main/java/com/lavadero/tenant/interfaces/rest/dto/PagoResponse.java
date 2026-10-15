package com.lavadero.tenant.interfaces.rest.dto;

import com.lavadero.tenant.application.dto.PagoDto;
import java.math.BigDecimal;
import java.time.Instant;
import java.util.UUID;

public record PagoResponse(
    UUID id,
    UUID subscriptionPlanId,
    BigDecimal monto,
    String moneda,
    String referencia,
    String estado,
    Instant creadoEn) {

  public static PagoResponse from(PagoDto dto) {
    return new PagoResponse(
        dto.id(),
        dto.subscriptionPlanId(),
        dto.monto(),
        dto.moneda(),
        dto.referencia(),
        dto.estado(),
        dto.creadoEn());
  }
}
