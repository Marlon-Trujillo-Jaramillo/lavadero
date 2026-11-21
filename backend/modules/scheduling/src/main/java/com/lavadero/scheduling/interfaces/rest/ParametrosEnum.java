package com.lavadero.scheduling.interfaces.rest;

import com.lavadero.shared.application.exception.ValidationException;
import java.util.Arrays;
import java.util.Locale;
import java.util.stream.Collectors;

/**
 * Convierte texto de la API a un enum. Un valor desconocido es un 400 que lista los valores
 * válidos; si Spring hiciera la conversión, sería un error de conversión que acaba en 500.
 */
final class ParametrosEnum {

  private ParametrosEnum() {}

  /** {@code null} o vacío → {@code null} (sin filtro). Ignora mayúsculas y espacios. */
  static <E extends Enum<E>> E opcional(Class<E> tipo, String valor, String parametro) {
    if (valor == null || valor.isBlank()) {
      return null;
    }
    try {
      return Enum.valueOf(tipo, valor.trim().toUpperCase(Locale.ROOT));
    } catch (IllegalArgumentException e) {
      String validos =
          Arrays.stream(tipo.getEnumConstants()).map(Enum::name).collect(Collectors.joining(", "));
      throw new ValidationException("'%s' debe ser uno de: %s".formatted(parametro, validos));
    }
  }

  static <E extends Enum<E>> E requerido(Class<E> tipo, String valor, String parametro) {
    E resultado = opcional(tipo, valor, parametro);
    if (resultado == null) {
      throw new ValidationException("'%s' es obligatorio".formatted(parametro));
    }
    return resultado;
  }
}
