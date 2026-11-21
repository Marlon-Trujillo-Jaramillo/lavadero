package com.lavadero.inventory.domain.model;

public enum TipoMovimiento {
  /** Compra o traslado que entra a la sucursal. */
  ENTRADA,
  /** Lo que gastó un lavado completado, según la receta del servicio. */
  CONSUMO,
  /** Corrección tras contar la bodega: la diferencia entre lo contado y lo que decía el sistema. */
  AJUSTE
}
