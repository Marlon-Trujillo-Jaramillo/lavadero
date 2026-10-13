package com.lavadero.tenant.interfaces.rest.dto;

import jakarta.validation.constraints.NotNull;
import java.util.UUID;

/** Sin monto a propósito: el precio sale del plan guardado en el servidor. */
public record IniciarPagoSuscripcionRequest(@NotNull UUID subscriptionPlanId) {}
