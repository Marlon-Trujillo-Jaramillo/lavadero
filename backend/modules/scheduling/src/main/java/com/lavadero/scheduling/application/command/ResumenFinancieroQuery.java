package com.lavadero.scheduling.application.command;

import com.lavadero.shared.security.AlcanceSucursal;
import java.time.LocalDate;
import java.util.UUID;

/** Ingresos vs. gastos del rango [desde, hasta] inclusive, para la utilidad del periodo. */
public record ResumenFinancieroQuery(
    LocalDate desde, LocalDate hasta, UUID sucursalId, AlcanceSucursal alcance) {}
