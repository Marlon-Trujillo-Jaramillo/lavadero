package com.lavadero.tenant.interfaces.rest.dto;

import com.lavadero.tenant.application.dto.CheckoutPagoDto;
import java.util.UUID;

/**
 * Parámetros del Web Checkout de Wompi: el cliente abre {@code urlCheckout} con {@code
 * public-key=llavePublica}, {@code currency=moneda}, {@code amount-in-cents=montoEnCentavos},
 * {@code reference=referencia}, {@code signature:integrity=firmaIntegridad} y, si viene, {@code
 * redirect-url=urlRedireccion}.
 */
public record CheckoutPagoResponse(
    UUID pagoId,
    String urlCheckout,
    String llavePublica,
    String referencia,
    long montoEnCentavos,
    String moneda,
    String firmaIntegridad,
    String urlRedireccion) {

  public static CheckoutPagoResponse from(CheckoutPagoDto dto) {
    return new CheckoutPagoResponse(
        dto.pagoId(),
        dto.urlCheckout(),
        dto.llavePublica(),
        dto.referencia(),
        dto.montoEnCentavos(),
        dto.moneda(),
        dto.firmaIntegridad(),
        dto.urlRedireccion());
  }
}
