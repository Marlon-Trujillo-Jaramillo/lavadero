package com.lavadero.inventory.domain.model;

import java.math.BigDecimal;
import java.util.UUID;

/**
 * Existencias de un insumo en una sucursal. {@code cantidad} puede ser negativa si se gastó más de
 * lo registrado: es una señal para contar la bodega, no un error.
 */
public record StockInsumo(UUID insumoId, UUID sucursalId, BigDecimal cantidad, BigDecimal minimo) {

  /** Bajo mínimo solo si hay un mínimo definido (mayor que cero). */
  public boolean bajoMinimo() {
    return minimo.signum() > 0 && cantidad.compareTo(minimo) <= 0;
  }

  public static StockInsumo vacio(UUID insumoId, UUID sucursalId) {
    return new StockInsumo(insumoId, sucursalId, BigDecimal.ZERO, BigDecimal.ZERO);
  }
}
