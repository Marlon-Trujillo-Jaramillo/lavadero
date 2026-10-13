package com.lavadero.tenant.application.dto;

import java.util.UUID;

/** Lo que el cliente necesita para abrir el Web Checkout de la pasarela, ya firmado. */
public record CheckoutPagoDto(
    UUID pagoId,
    String urlCheckout,
    String llavePublica,
    String referencia,
    long montoEnCentavos,
    String moneda,
    String firmaIntegridad,
    String urlRedireccion) {}
