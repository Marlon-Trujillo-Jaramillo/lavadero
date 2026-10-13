package com.lavadero.tenant.application.dto;

import java.math.BigDecimal;
import java.time.Instant;
import java.util.UUID;

public record PagoDto(
    UUID id,
    UUID subscriptionPlanId,
    BigDecimal monto,
    String moneda,
    String referencia,
    String estado,
    Instant creadoEn) {}
