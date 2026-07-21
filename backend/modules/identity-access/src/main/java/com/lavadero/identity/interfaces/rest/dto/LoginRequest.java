package com.lavadero.identity.interfaces.rest.dto;

import jakarta.validation.constraints.NotBlank;

/** El tenant se resuelve por el header {@code X-Tenant-Slug} (opcional), no por el body. */
public record LoginRequest(@NotBlank String email, @NotBlank String password) {}
