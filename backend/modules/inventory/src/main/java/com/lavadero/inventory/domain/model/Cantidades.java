package com.lavadero.inventory.domain.model;

import java.math.BigDecimal;
import java.util.Objects;

/** Reglas comunes de cantidades de inventario: hasta 3 decimales y un tope razonable. */
public final class Cantidades {

  static final BigDecimal MAXIMA = new BigDecimal("100000000");
  static final int DECIMALES = 3;

  private Cantidades() {}

  public static BigDecimal positiva(BigDecimal valor, String campo) {
    BigDecimal v = noNegativa(valor, campo);
    if (v.signum() == 0) {
      throw new IllegalArgumentException(campo + " debe ser mayor que cero");
    }
    return v;
  }

  public static BigDecimal noNegativa(BigDecimal valor, String campo) {
    Objects.requireNonNull(valor, campo + " no puede ser nulo");
    if (valor.signum() < 0) {
      throw new IllegalArgumentException(campo + " no puede ser negativa");
    }
    if (valor.stripTrailingZeros().scale() > DECIMALES) {
      throw new IllegalArgumentException(campo + " admite hasta " + DECIMALES + " decimales");
    }
    if (valor.compareTo(MAXIMA) > 0) {
      throw new IllegalArgumentException(campo + " es demasiado grande");
    }
    return valor;
  }
}
