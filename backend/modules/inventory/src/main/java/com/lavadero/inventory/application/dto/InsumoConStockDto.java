package com.lavadero.inventory.application.dto;

import java.math.BigDecimal;
import java.util.UUID;

/** Un insumo con su stock en la sucursal consultada (cero si nunca tuvo movimientos ahí). */
public record InsumoConStockDto(
    UUID id,
    String nombre,
    String unidad,
    BigDecimal costoUnitario,
    String moneda,
    UUID sucursalId,
    BigDecimal cantidad,
    BigDecimal minimo,
    boolean bajoMinimo) {}
