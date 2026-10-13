package com.lavadero.tenant.application.usecase;

import com.lavadero.tenant.application.dto.PagoDto;
import com.lavadero.tenant.domain.model.Pago;

/** Mapeo compartido dominio→DTO de {@link Pago}. */
final class PagoMapper {

  private PagoMapper() {}

  static PagoDto toDto(Pago pago) {
    return new PagoDto(
        pago.getId(),
        pago.getSubscriptionPlanId(),
        pago.getMonto().monto(),
        pago.getMonto().moneda().getCurrencyCode(),
        pago.getReferencia(),
        pago.getEstado().name(),
        pago.getCreadoEn());
  }
}
