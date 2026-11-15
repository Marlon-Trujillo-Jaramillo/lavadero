package com.lavadero.identity.interfaces.rest.dto;

import static com.lavadero.identity.interfaces.rest.dto.LimitesCampos.*;

import jakarta.validation.constraints.Email;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Size;

/** El tenant es obligatorio aquí y se resuelve por el header {@code X-Tenant-Slug}. */
public record RegisterRequest(
    @NotBlank @Email @Size(max = EMAIL_MAX) String email,
    @NotBlank @Size(min = PASSWORD_MIN, max = PASSWORD_MAX) String password,
    @NotBlank @Size(max = NOMBRE_MAX) String nombre) {}
