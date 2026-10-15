package com.lavadero.scheduling.application.command;

import com.lavadero.shared.security.AlcanceSucursal;
import java.time.Instant;
import java.util.UUID;

/**
 * Rango [desde, hasta). {@code sucursalId} es un filtro opcional ({@code null} = todo el tenant);
 * con {@code alcance} restringido (ADMIN_SUCURSAL) se fuerza la sucursal propia.
 */
public record ResumenVentasQuery(
    Instant desde, Instant hasta, UUID sucursalId, AlcanceSucursal alcance) {}
