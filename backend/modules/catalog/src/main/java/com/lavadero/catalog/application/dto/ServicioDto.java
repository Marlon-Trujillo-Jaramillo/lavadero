package com.lavadero.catalog.application.dto;

import java.math.BigDecimal;
import java.util.UUID;

public record ServicioDto(
    UUID id,
    String nombre,
    String descripcion,
    int duracionEstimadaMinutos,
    BigDecimal precio,
    String moneda,
    boolean activo) {}
