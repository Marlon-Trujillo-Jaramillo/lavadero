package com.lavadero.inventory.application.command;

import com.lavadero.shared.security.AlcanceSucursal;
import java.math.BigDecimal;
import java.util.UUID;

/**
 * Entrada (cantidad que llega), ajuste (cantidad contada) o mínimo (umbral de alerta) de un insumo
 * en una sucursal. Un ADMIN_SUCURSAL solo puede tocar la suya.
 */
public record CambioStockCommand(
    UUID insumoId, UUID sucursalId, BigDecimal cantidad, String nota, AlcanceSucursal alcance) {}
