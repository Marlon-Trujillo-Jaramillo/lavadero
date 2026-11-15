package com.lavadero.scheduling.application.dto;

import java.math.BigDecimal;
import java.time.Instant;
import java.util.UUID;

public record ReservaDto(
    UUID id,
    UUID sucursalId,
    UUID servicioId,
    UUID clienteId,
    Instant fechaHoraInicio,
    Instant fechaHoraFin,
    int duracionEstimadaMinutos,
    BigDecimal precio,
    String moneda,
    String estado,
    UUID vehiculoId,
    String vehiculoPlaca) {}
