package com.lavadero.scheduling.application.command;

import com.lavadero.shared.security.AlcanceSucursal;
import java.time.LocalDate;
import java.util.UUID;

/**
 * Rango [desde, hasta] inclusive. {@code sucursalId} opcional; {@code alcance} fuerza la propia.
 */
public record ListarGastosQuery(
    LocalDate desde, LocalDate hasta, UUID sucursalId, AlcanceSucursal alcance) {}
