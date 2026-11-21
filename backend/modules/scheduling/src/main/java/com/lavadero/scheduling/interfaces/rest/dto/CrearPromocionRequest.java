package com.lavadero.scheduling.interfaces.rest.dto;

import jakarta.validation.constraints.Digits;
import jakarta.validation.constraints.Max;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Positive;
import jakarta.validation.constraints.Size;
import java.math.BigDecimal;
import java.time.LocalDate;
import java.time.LocalTime;
import java.util.List;

/**
 * {@code tipo}: CUPON | HORARIO. {@code tipoDescuento}: PORCENTAJE | MONTO_FIJO. {@code dias}:
 * MONDAY ... SUNDAY. Horas en formato {@code HH:mm}, hora local del lavadero.
 */
public record CrearPromocionRequest(
    @NotBlank(message = "El nombre es obligatorio")
        @Size(max = 60, message = "El nombre admite hasta 60 caracteres")
        String nombre,
    @NotBlank(message = "El tipo es obligatorio") String tipo,
    @Size(max = 20, message = "El código admite hasta 20 caracteres") String codigo,
    @NotBlank(message = "El tipo de descuento es obligatorio") String tipoDescuento,
    @NotNull(message = "El valor del descuento es obligatorio")
        @Positive(message = "El descuento debe ser mayor que cero")
        @Digits(integer = 10, fraction = 2, message = "Valor de descuento inválido")
        BigDecimal valorDescuento,
    @Size(max = 7) List<String> dias,
    LocalTime horaDesde,
    LocalTime horaHasta,
    @NotNull(message = "La fecha de inicio es obligatoria") LocalDate vigenteDesde,
    @NotNull(message = "La fecha final es obligatoria") LocalDate vigenteHasta,
    @Positive(message = "El máximo de usos debe ser al menos 1")
        @Max(value = 1_000_000, message = "El máximo de usos es demasiado alto")
        Integer usosMaximos) {}
