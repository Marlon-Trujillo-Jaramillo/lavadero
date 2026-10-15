package com.lavadero.tenant.application.command;

import java.util.UUID;

/**
 * Solo el plan elegido: el monto sale del plan guardado y el tenant de {@code TenantContext} (JWT),
 * nunca del cliente.
 */
public record IniciarPagoSuscripcionCommand(UUID subscriptionPlanId) {}
