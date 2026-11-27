package com.lavadero.scheduling.application.dto;

import com.lavadero.scheduling.domain.model.gasto.CategoriaGasto;
import java.math.BigDecimal;
import java.time.Instant;
import java.time.LocalDate;
import java.util.UUID;

public record GastoDto(
    UUID id,
    UUID sucursalId,
    LocalDate fecha,
    CategoriaGasto categoria,
    String descripcion,
    BigDecimal monto,
    String moneda,
    Instant creadoEn) {}
