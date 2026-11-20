package com.lavadero.scheduling.domain.model.promocion;

import com.lavadero.shared.domain.Money;
import java.math.BigDecimal;
import java.math.RoundingMode;
import java.util.Currency;
import java.util.Objects;
import java.util.Set;

/**
 * Cuánto descuenta una promoción. Un porcentaje va de 1 a {@value #PORCENTAJE_MAXIMO} (regalar el
 * servicio no es una promoción, es un error de digitación). Un monto fijo nunca deja el precio en
 * negativo: como mucho lo deja en cero.
 */
public record Descuento(TipoDescuento tipo, BigDecimal valor, Currency moneda) {

  public static final int PORCENTAJE_MAXIMO = 90;

  /**
   * Monedas que en la práctica se cobran sin centavos, aunque ISO 4217 les dé dos decimales (Java
   * dice 2 para COP). Misma lista que {@code Formato} en las apps.
   */
  private static final Set<String> SIN_CENTAVOS = Set.of("COP", "CLP", "PYG", "JPY");

  public Descuento {
    Objects.requireNonNull(tipo, "tipo no puede ser nulo");
    Objects.requireNonNull(valor, "valor no puede ser nulo");
    if (tipo == TipoDescuento.PORCENTAJE) {
      if (valor.compareTo(BigDecimal.ONE) < 0
          || valor.compareTo(BigDecimal.valueOf(PORCENTAJE_MAXIMO)) > 0
          || valor.stripTrailingZeros().scale() > 0) {
        throw new IllegalArgumentException(
            "El porcentaje debe ser un número entero entre 1 y " + PORCENTAJE_MAXIMO);
      }
      moneda = null;
    } else {
      Objects.requireNonNull(moneda, "un monto fijo necesita moneda");
      if (valor.signum() <= 0) {
        throw new IllegalArgumentException("El monto del descuento debe ser mayor que cero");
      }
    }
  }

  public static Descuento porcentaje(int porcentaje) {
    return new Descuento(TipoDescuento.PORCENTAJE, BigDecimal.valueOf(porcentaje), null);
  }

  public static Descuento montoFijo(Money monto) {
    return new Descuento(TipoDescuento.MONTO_FIJO, monto.monto(), monto.moneda());
  }

  /**
   * Lo que se descuenta de {@code precioLista}. Un porcentaje se redondea a la unidad mínima de la
   * moneda (pesos enteros en COP).
   */
  public Money calcular(Money precioLista) {
    Currency monedaPrecio = precioLista.moneda();
    if (tipo == TipoDescuento.PORCENTAJE) {
      int decimales =
          SIN_CENTAVOS.contains(monedaPrecio.getCurrencyCode())
              ? 0
              : Math.max(monedaPrecio.getDefaultFractionDigits(), 0);
      BigDecimal monto =
          precioLista
              .monto()
              .multiply(valor)
              .divide(BigDecimal.valueOf(100), decimales, RoundingMode.HALF_UP);
      return Money.de(monto, monedaPrecio);
    }
    if (!moneda.equals(monedaPrecio)) {
      throw new IllegalArgumentException(
          "El descuento está en %s y el precio en %s".formatted(moneda, monedaPrecio));
    }
    return Money.de(valor.min(precioLista.monto()), monedaPrecio);
  }
}
