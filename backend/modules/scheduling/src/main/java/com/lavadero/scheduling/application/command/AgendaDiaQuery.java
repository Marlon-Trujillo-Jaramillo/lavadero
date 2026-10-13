package com.lavadero.scheduling.application.command;

import com.lavadero.shared.security.AlcanceSucursal;
import java.time.Instant;
import java.util.UUID;

/** El cálculo de los límites del día (zona horaria, etc.) vive en el controller, no aquí. */
public record AgendaDiaQuery(
    UUID sucursalId, Instant desde, Instant hasta, AlcanceSucursal alcance) {}
