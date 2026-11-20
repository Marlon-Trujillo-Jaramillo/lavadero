package com.lavadero.scheduling.application.dto;

import java.math.BigDecimal;
import java.time.Instant;
import java.util.UUID;

public record VisitaClienteDto(
    UUID reservaId,
    Instant fecha,
    String servicio,
    String sucursal,
    String estado,
    BigDecimal precio,
    String moneda,
    String placa) {}
