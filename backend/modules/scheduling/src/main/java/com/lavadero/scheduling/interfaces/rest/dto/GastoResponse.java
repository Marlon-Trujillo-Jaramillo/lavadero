package com.lavadero.scheduling.interfaces.rest.dto;

import com.lavadero.scheduling.application.dto.GastoDto;
import com.lavadero.scheduling.domain.model.gasto.CategoriaGasto;
import java.math.BigDecimal;
import java.time.Instant;
import java.time.LocalDate;
import java.util.UUID;

public record GastoResponse(
    UUID id,
    UUID sucursalId,
    LocalDate fecha,
    CategoriaGasto categoria,
    String descripcion,
    BigDecimal monto,
    String moneda,
    Instant creadoEn) {

  public static GastoResponse from(GastoDto d) {
    return new GastoResponse(
        d.id(),
        d.sucursalId(),
        d.fecha(),
        d.categoria(),
        d.descripcion(),
        d.monto(),
        d.moneda(),
        d.creadoEn());
  }
}
