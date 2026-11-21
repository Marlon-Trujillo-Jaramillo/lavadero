package com.lavadero.inventory.application.command;

import com.lavadero.shared.security.AlcanceSucursal;
import java.util.UUID;

/** {@code insumoId} solo lo usa el kardex de un insumo. */
public record InventarioQuery(UUID sucursalId, UUID insumoId, AlcanceSucursal alcance) {}
