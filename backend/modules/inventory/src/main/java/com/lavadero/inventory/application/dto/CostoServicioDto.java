package com.lavadero.inventory.application.dto;

import java.math.BigDecimal;
import java.util.List;
import java.util.UUID;

/**
 * Cuánto cuestan los insumos de un servicio y qué margen deja. {@code margenPorcentaje} es {@code
 * null} si el servicio no tiene precio (no se divide por cero).
 */
public record CostoServicioDto(
    UUID servicioId,
    String nombre,
    boolean activo,
    BigDecimal precio,
    String moneda,
    List<Linea> lineas,
    BigDecimal costoInsumos,
    BigDecimal margen,
    Integer margenPorcentaje) {

  public record Linea(
      UUID insumoId, String insumo, String unidad, BigDecimal cantidad, BigDecimal costo) {}
}
