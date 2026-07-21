package com.lavadero.catalog.interfaces.rest.dto;

import jakarta.validation.constraints.DecimalMin;
import jakarta.validation.constraints.Min;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import java.math.BigDecimal;

public record CrearServicioRequest(
    @NotBlank String nombre,
    String descripcion,
    @Min(1) int duracionEstimadaMinutos,
    @NotNull @DecimalMin(value = "0", inclusive = false) BigDecimal precio) {}
