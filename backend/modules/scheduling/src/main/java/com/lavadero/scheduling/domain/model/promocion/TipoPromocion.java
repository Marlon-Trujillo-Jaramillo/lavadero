package com.lavadero.scheduling.domain.model.promocion;

/** Cómo se activa una promoción. */
public enum TipoPromocion {
  /** El cliente escribe un código al reservar. */
  CUPON,
  /** Se aplica sola a las reservas que caen en una franja (días + horas) de baja demanda. */
  HORARIO
}
