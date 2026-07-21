package com.lavadero.tenant.interfaces.rest.dto;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Pattern;
import java.util.UUID;

public record CrearTenantRequest(
    @NotBlank String nombre,
    @NotBlank String nit,
    @NotBlank @Pattern(regexp = "^[a-z0-9]+(-[a-z0-9]+)*$") String slug,
    UUID subscriptionPlanId) {}
