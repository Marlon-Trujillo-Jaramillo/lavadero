package com.lavadero.shared.application.exception;

/** Una regla de validación de negocio o de entrada no se cumple. */
public class ValidationException extends ApplicationException {

  public ValidationException(String message) {
    super(message);
  }
}
