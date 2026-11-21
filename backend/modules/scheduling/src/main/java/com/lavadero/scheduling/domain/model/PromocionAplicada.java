package com.lavadero.scheduling.domain.model;

import com.lavadero.shared.domain.Money;
import java.util.Objects;
import java.util.UUID;

/**
 * La promoción con la que se creó una reserva y el precio de lista de ese momento. El precio de la
 * reserva ya es el final (lo que se cobra); {@code precioLista - precio} es el descuento.
 */
public record PromocionAplicada(UUID promocionId, Money precioLista) {

  public PromocionAplicada {
    Objects.requireNonNull(promocionId, "promocionId no puede ser nulo");
    Objects.requireNonNull(precioLista, "precioLista no puede ser nulo");
  }
}
