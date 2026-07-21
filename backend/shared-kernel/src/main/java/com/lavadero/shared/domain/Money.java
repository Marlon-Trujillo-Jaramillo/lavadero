package com.lavadero.shared.domain;

import java.math.BigDecimal;
import java.math.RoundingMode;
import java.util.Currency;
import java.util.Objects;

/**
 * Value object monetario: monto + moneda. Todas las operaciones son seguras (inmutables, sin
 * doubles) y lanzan {@link IllegalArgumentException} ante operaciones entre monedas distintas, que
 * no tienen sentido de negocio sin una conversión explícita (fuera del alcance de esta fase).
 */
public final class Money {

  private static final int ESCALA = 2;

  private final BigDecimal monto;
  private final Currency moneda;

  private Money(BigDecimal monto, Currency moneda) {
    this.moneda = Objects.requireNonNull(moneda, "la moneda no puede ser nula");
    this.monto =
        Objects.requireNonNull(monto, "el monto no puede ser nulo")
            .setScale(ESCALA, RoundingMode.HALF_UP);
  }

  public static Money de(BigDecimal monto, Currency moneda) {
    return new Money(monto, moneda);
  }

  public static Money de(BigDecimal monto, String codigoMoneda) {
    return new Money(monto, Currency.getInstance(codigoMoneda));
  }

  public static Money cero(Currency moneda) {
    return new Money(BigDecimal.ZERO, moneda);
  }

  public static Money cop(BigDecimal monto) {
    return de(monto, "COP");
  }

  public Money sumar(Money otro) {
    verificarMismaMoneda(otro);
    return new Money(this.monto.add(otro.monto), this.moneda);
  }

  public Money restar(Money otro) {
    verificarMismaMoneda(otro);
    BigDecimal resultado = this.monto.subtract(otro.monto);
    if (resultado.signum() < 0) {
      throw new IllegalArgumentException("La resta produce un monto negativo");
    }
    return new Money(resultado, this.moneda);
  }

  public Money multiplicar(BigDecimal factor) {
    Objects.requireNonNull(factor, "el factor no puede ser nulo");
    if (factor.signum() < 0) {
      throw new IllegalArgumentException("El factor no puede ser negativo");
    }
    return new Money(this.monto.multiply(factor), this.moneda);
  }

  public boolean esMayorQue(Money otro) {
    verificarMismaMoneda(otro);
    return this.monto.compareTo(otro.monto) > 0;
  }

  public boolean esMayorOIgualQue(Money otro) {
    verificarMismaMoneda(otro);
    return this.monto.compareTo(otro.monto) >= 0;
  }

  private void verificarMismaMoneda(Money otro) {
    Objects.requireNonNull(otro, "el otro monto no puede ser nulo");
    if (!this.moneda.equals(otro.moneda)) {
      throw new IllegalArgumentException(
          "No se pueden operar montos de monedas distintas: %s vs %s"
              .formatted(this.moneda, otro.moneda));
    }
  }

  public BigDecimal monto() {
    return monto;
  }

  public Currency moneda() {
    return moneda;
  }

  @Override
  public boolean equals(Object o) {
    if (this == o) {
      return true;
    }
    if (!(o instanceof Money money)) {
      return false;
    }
    return monto.compareTo(money.monto) == 0 && moneda.equals(money.moneda);
  }

  @Override
  public int hashCode() {
    return Objects.hash(monto.stripTrailingZeros(), moneda);
  }

  @Override
  public String toString() {
    return "%s %s".formatted(monto, moneda.getCurrencyCode());
  }
}
