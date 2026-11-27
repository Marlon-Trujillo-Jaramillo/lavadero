package com.lavadero.scheduling.interfaces.rest.dto;

import jakarta.validation.constraints.Digits;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Positive;
import jakarta.validation.constraints.Size;
import java.math.BigDecimal;
import java.time.LocalDate;
import java.util.UUID;

/** {@code categoria}: ARRIENDO | NOMINA | INSUMOS | SERVICIOS_PUBLICOS | MANTENIMIENTO | OTRO. */
public record RegistrarGastoRequest(
    UUID sucursalId,
    @NotNull(message = "La fecha es obligatoria") LocalDate fecha,
    @NotBlank(message = "La categoría es obligatoria") String categoria,
    @NotBlank(message = "La descripción es obligatoria")
        @Size(max = 120, message = "La descripción admite hasta 120 caracteres")
        String descripcion,
    @NotNull(message = "El monto es obligatorio")
        @Positive(message = "El monto debe ser mayor que cero")
        @Digits(integer = 10, fraction = 2, message = "Monto inválido")
        BigDecimal monto,
    String moneda) {}
