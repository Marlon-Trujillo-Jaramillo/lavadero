package com.lavadero.tenant.interfaces.rest.dto;

import jakarta.validation.constraints.Min;
import jakarta.validation.constraints.NotBlank;

public record ActualizarSucursalRequest(
    @NotBlank String nombre, String direccion, @Min(1) int capacidadSimultanea) {}
