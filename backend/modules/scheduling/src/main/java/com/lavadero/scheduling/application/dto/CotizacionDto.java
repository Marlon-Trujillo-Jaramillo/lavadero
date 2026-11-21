package com.lavadero.scheduling.application.dto;

import java.math.BigDecimal;
import java.util.UUID;

/** {@code promocionId}/{@code promocionNombre} son {@code null} si no aplica ninguna. */
public record CotizacionDto(
    BigDecimal precioLista,
    BigDecimal descuento,
    BigDecimal precioFinal,
    String moneda,
    UUID promocionId,
    String promocionNombre) {}
