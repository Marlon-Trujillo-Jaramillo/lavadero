package com.lavadero.inventory.domain.model;

/**
 * Unidad en la que se compra, se cuenta y se consume un insumo. Se usa la unidad más pequeña
 * (mililitros, gramos) para que la receta sea un número entero o casi: "40 ml de shampoo".
 */
public enum UnidadMedida {
  ML,
  G,
  UNIDAD
}
