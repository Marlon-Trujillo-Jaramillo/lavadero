package com.lavadero.scheduling.application.dto;

import java.math.BigDecimal;
import java.time.Instant;
import java.util.UUID;

public record ClienteResumenDto(
    UUID id,
    String nombre,
    String email,
    int visitas,
    BigDecimal gastoTotal,
    String moneda,
    Instant primeraVisita,
    Instant ultimaVisita,
    Instant proximaReserva,
    int vehiculosActivos,
    String segmento) {}
