package com.lavadero.identity.interfaces.rest.dto;

import jakarta.validation.constraints.NotBlank;

/** El tenant es obligatorio aquí y se resuelve por el header {@code X-Tenant-Slug}. */
public record RegisterRequest(
    @NotBlank String email, @NotBlank String password, @NotBlank String nombre) {}
