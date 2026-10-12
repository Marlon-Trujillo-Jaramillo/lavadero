package com.lavadero.tenant.interfaces.rest.dto;

import jakarta.validation.constraints.DecimalMin;
import jakarta.validation.constraints.Min;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import java.math.BigDecimal;
import java.util.List;

public record ActualizarSubscriptionPlanRequest(
    @NotBlank String nombre,
    @NotNull @DecimalMin(value = "0", inclusive = false) BigDecimal precio,
    @Min(1) int maxSucursales,
    @Min(1) int maxEmpleados,
    List<String> features) {}
