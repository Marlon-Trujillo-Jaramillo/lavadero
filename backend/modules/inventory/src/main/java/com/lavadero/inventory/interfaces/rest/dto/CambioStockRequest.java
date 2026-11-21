package com.lavadero.inventory.interfaces.rest.dto;

import jakarta.validation.constraints.Digits;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Size;
import java.math.BigDecimal;
import java.util.UUID;

/** Entrada, ajuste (cantidad contada) o mínimo, según el endpoint. */
public record CambioStockRequest(
    UUID sucursalId,
    @NotNull(message = "La cantidad es obligatoria")
        @Digits(integer = 9, fraction = 3, message = "Cantidad inválida")
        BigDecimal cantidad,
    @Size(max = 120, message = "La nota admite hasta 120 caracteres") String nota) {}
