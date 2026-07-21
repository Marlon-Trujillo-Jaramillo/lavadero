package com.lavadero.tenant.application.command;

import java.util.UUID;

public record CrearTenantCommand(String nombre, String nit, String slug, UUID subscriptionPlanId) {}
