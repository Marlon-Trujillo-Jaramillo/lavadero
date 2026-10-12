package com.lavadero.identity.interfaces.rest.dto;

import jakarta.validation.constraints.NotBlank;
import java.util.UUID;

public record CrearEmpleadoRequest(
    @NotBlank String email, @NotBlank String password, @NotBlank String nombre, UUID sucursalId) {}
