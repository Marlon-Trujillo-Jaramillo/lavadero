package com.lavadero.inventory.interfaces.rest.dto;

import jakarta.validation.constraints.DecimalMin;
import jakarta.validation.constraints.Digits;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Size;
import java.math.BigDecimal;

/** {@code unidad}: ML | G | UNIDAD. {@code costoUnitario}: lo que cuesta 1 ml, 1 g o 1 unidad. */
public record CrearInsumoRequest(
    @NotBlank(message = "El nombre es obligatorio")
        @Size(max = 60, message = "El nombre admite hasta 60 caracteres")
        String nombre,
    @NotBlank(message = "La unidad es obligatoria") String unidad,
    @NotNull(message = "El costo es obligatorio")
        @DecimalMin(value = "0", message = "El costo no puede ser negativo")
        @Digits(integer = 8, fraction = 4, message = "Costo inválido")
        BigDecimal costoUnitario) {}
