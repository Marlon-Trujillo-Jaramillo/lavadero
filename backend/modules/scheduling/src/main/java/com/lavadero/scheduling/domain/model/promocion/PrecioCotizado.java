package com.lavadero.scheduling.domain.model.promocion;

import com.lavadero.shared.domain.Money;
import java.util.Optional;

/** Precio de una reserva antes de crearla: lista, descuento y lo que se cobra. */
public record PrecioCotizado(
    Money precioLista, Money descuento, Money precioFinal, Promocion promocion) {

  public Optional<Promocion> getPromocion() {
    return Optional.ofNullable(promocion);
  }
}
