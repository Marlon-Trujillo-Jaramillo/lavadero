package com.lavadero.identity.interfaces.rest.dto;

import static com.lavadero.identity.interfaces.rest.dto.LimitesCampos.*;

import jakarta.validation.constraints.Email;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Size;
import java.util.UUID;

public record CrearEmpleadoRequest(
    @NotBlank @Email @Size(max = EMAIL_MAX) String email,
    @NotBlank @Size(min = PASSWORD_MIN, max = PASSWORD_MAX) String password,
    @NotBlank @Size(max = NOMBRE_MAX) String nombre,
    UUID sucursalId) {}
