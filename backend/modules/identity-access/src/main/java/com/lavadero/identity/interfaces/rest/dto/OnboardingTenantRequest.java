package com.lavadero.identity.interfaces.rest.dto;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Pattern;

public record OnboardingTenantRequest(
    @NotBlank String tenantNombre,
    @NotBlank String tenantNit,
    @NotBlank @Pattern(regexp = "^[a-z0-9]+(-[a-z0-9]+)*$") String tenantSlug,
    @NotBlank String adminEmail,
    @NotBlank String adminPassword,
    @NotBlank String adminNombre) {}
