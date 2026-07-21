package com.lavadero.shared.application.exception;

/** Un recurso solicitado no existe (o no es visible para el tenant actual). */
public class NotFoundException extends ApplicationException {

  public NotFoundException(String message) {
    super(message);
  }

  public static NotFoundException de(String tipo, Object id) {
    return new NotFoundException("%s no encontrado: %s".formatted(tipo, id));
  }
}
