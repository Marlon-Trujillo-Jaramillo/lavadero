package com.lavadero.scheduling.application.dto;

import java.math.BigDecimal;

/** {@code utilidad = ingresos - gastos}; puede ser negativa (se perdió plata en el periodo). */
public record ResumenFinancieroDto(
    BigDecimal ingresos, BigDecimal gastos, BigDecimal utilidad, String moneda) {}
