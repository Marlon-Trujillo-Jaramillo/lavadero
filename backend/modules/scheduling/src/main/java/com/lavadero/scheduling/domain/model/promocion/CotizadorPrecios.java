package com.lavadero.scheduling.domain.model.promocion;

import com.lavadero.shared.domain.Money;
import java.time.Instant;
import java.util.Comparator;
import java.util.List;

/**
 * Elige la promoción de una reserva. Las promociones no se acumulan: entre las que aplican (las
 * franjas horarias activas y, si el cliente escribió uno, su cupón) gana la que más descuenta. Así
 * un cupón nunca empeora el precio que el cliente ya tenía por reservar en hora valle.
 */
public final class CotizadorPrecios {

  private CotizadorPrecios() {}

  public static PrecioCotizado cotizar(
      Money precioLista, Instant inicio, List<Promocion> candidatas) {
    return candidatas.stream()
        .filter(p -> p.aplicaA(inicio))
        .map(p -> new PrecioCotizado(precioLista, p.descuentoSobre(precioLista), null, p))
        .max(Comparator.comparing(c -> c.descuento().monto()))
        .filter(c -> c.descuento().monto().signum() > 0)
        .map(
            c ->
                new PrecioCotizado(
                    precioLista, c.descuento(), precioLista.restar(c.descuento()), c.promocion()))
        .orElseGet(
            () ->
                new PrecioCotizado(
                    precioLista, Money.cero(precioLista.moneda()), precioLista, null));
  }
}
