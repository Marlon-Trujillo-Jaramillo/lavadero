package com.lavadero.shared.application.exception;

/** El actor autenticado no tiene permiso para realizar la operación solicitada. */
public class ForbiddenException extends ApplicationException {

  public ForbiddenException(String message) {
    super(message);
  }
}
