package com.lavadero.inventory.application.dto;

import java.math.BigDecimal;
import java.time.Instant;
import java.util.UUID;

public record MovimientoDto(
    UUID id,
    String tipo,
    BigDecimal cantidad,
    BigDecimal saldo,
    UUID reservaId,
    String nota,
    Instant creadoEn) {}
