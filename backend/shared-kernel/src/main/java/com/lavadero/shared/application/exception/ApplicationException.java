package com.lavadero.shared.application.exception;

/**
 * Raíz de la jerarquía de excepciones de aplicación. El manejo centralizado (traducción a
 * respuestas HTTP consistentes) vive en un {@code @RestControllerAdvice} de `bootstrap` (capa
 * `interfaces`), nunca aquí: `application` no debe conocer HTTP.
 */
public abstract class ApplicationException extends RuntimeException {

  protected ApplicationException(String message) {
    super(message);
  }

  protected ApplicationException(String message, Throwable cause) {
    super(message, cause);
  }
}
