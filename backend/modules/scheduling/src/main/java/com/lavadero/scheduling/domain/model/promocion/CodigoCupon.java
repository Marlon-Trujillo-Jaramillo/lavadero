package com.lavadero.scheduling.domain.model.promocion;

import java.util.Locale;
import java.util.Objects;
import java.util.regex.Pattern;

/**
 * Código de un cupón. Se normaliza (sin espacios, en mayúsculas: {@code " verano-24 "} → {@code
 * VERANO-24}) para que el cliente no falle por cómo lo escribe. 4 a 20 letras, números o guiones.
 */
public record CodigoCupon(String valor) {

  private static final Pattern FORMATO = Pattern.compile("^[A-Z0-9-]{4,20}$");

  public CodigoCupon {
    Objects.requireNonNull(valor, "el código no puede ser nulo");
    if (!FORMATO.matcher(valor).matches()) {
      throw new IllegalArgumentException(
          "El código del cupón debe tener de 4 a 20 letras, números o guiones");
    }
  }

  public static CodigoCupon de(String texto) {
    Objects.requireNonNull(texto, "el código no puede ser nulo");
    return new CodigoCupon(texto.replaceAll("\\s+", "").toUpperCase(Locale.ROOT));
  }
}
