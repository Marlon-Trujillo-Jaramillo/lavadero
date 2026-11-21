package com.lavadero.inventory.application.usecase;

import com.lavadero.shared.application.exception.ValidationException;
import com.lavadero.shared.security.AlcanceSucursal;
import java.util.UUID;

/** El stock siempre es de una sucursal: el admin de sucursal usa la suya, el dueño elige una. */
final class SucursalDeInventario {

  private SucursalDeInventario() {}

  static UUID resolver(AlcanceSucursal alcance, UUID solicitada) {
    UUID sucursal = alcance.resolverFiltro(solicitada);
    if (sucursal == null) {
      throw new ValidationException("Elige una sucursal");
    }
    return sucursal;
  }
}
