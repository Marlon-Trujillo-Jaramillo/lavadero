package com.lavadero.identity.interfaces.rest.dto;

import static com.lavadero.identity.interfaces.rest.dto.LimitesCampos.*;

import jakarta.validation.constraints.Email;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Pattern;
import jakarta.validation.constraints.Size;

public record OnboardingTenantRequest(
    @NotBlank @Size(max = NOMBRE_MAX) String tenantNombre,
    @NotBlank @Size(max = NIT_MAX) String tenantNit,
    @NotBlank @Size(min = SLUG_MIN, max = SLUG_MAX) @Pattern(regexp = "^[a-z0-9]+(-[a-z0-9]+)*$")
        String tenantSlug,
    @NotBlank @Email @Size(max = EMAIL_MAX) String adminEmail,
    @NotBlank @Size(min = PASSWORD_MIN, max = PASSWORD_MAX) String adminPassword,
    @NotBlank @Size(max = NOMBRE_MAX) String adminNombre) {}
