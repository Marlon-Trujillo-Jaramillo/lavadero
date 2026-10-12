package com.lavadero.identity.application.command;

public record OnboardingTenantCommand(
    String tenantNombre,
    String tenantNit,
    String tenantSlug,
    String adminEmail,
    String adminPassword,
    String adminNombre) {}
