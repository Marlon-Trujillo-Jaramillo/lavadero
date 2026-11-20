package com.lavadero.scheduling.domain.model;

import java.util.Locale;
import java.util.regex.Pattern;

/**
 * Placa de un vehículo, normalizada: mayúsculas y sin espacios ni guiones ("abc-123" → "ABC123").
 * Acepta de 5 a 8 letras o números: cubre carros (ABC123), motos (ABC12D) y placas especiales o
 * extranjeras sin atarse a un solo formato.
 */
public record Placa(String valor) {

  private static final Pattern FORMATO = Pattern.compile("^[A-Z0-9]{5,8}$");

  public Placa {
    if (valor == null || !FORMATO.matcher(valor).matches()) {
      throw new IllegalArgumentException(
          "La placa debe tener de 5 a 8 letras o números (ej. ABC123)");
    }
  }

  /** Normaliza lo que escribió el usuario y valida el resultado. */
  public static Placa de(String texto) {
    String normalizada =
        texto == null ? null : texto.replaceAll("[\\s-]", "").toUpperCase(Locale.ROOT);
    return new Placa(normalizada);
  }

  @Override
  public String toString() {
    return valor;
  }
}
