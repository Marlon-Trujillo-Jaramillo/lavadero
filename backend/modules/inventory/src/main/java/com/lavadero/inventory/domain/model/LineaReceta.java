package com.lavadero.inventory.domain.model;

import java.math.BigDecimal;
import java.util.Objects;
import java.util.UUID;

/** Cuánto de un insumo gasta un servicio cada vez que se completa. */
public record LineaReceta(UUID insumoId, BigDecimal cantidad) {

  public LineaReceta {
    Objects.requireNonNull(insumoId, "insumoId no puede ser nulo");
    cantidad = Cantidades.positiva(cantidad, "La cantidad de la receta");
  }
}
