package com.lavadero.shared.application.exception;

/** Se superó un límite de intentos (p. ej. bloqueo temporal de login); se traduce a HTTP 429. */
public class DemasiadosIntentosException extends ApplicationException {

  public DemasiadosIntentosException(String message) {
    super(message);
  }
}
