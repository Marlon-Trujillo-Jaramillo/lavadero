package com.lavadero.messaging;

/**
 * Cómo sale un evento del outbox. Si lanza, el relay lo deja pendiente y lo reintenta más tarde.
 * Implementaciones: {@code TransporteKafka} y {@code TransporteLocal} (mismo proceso, para correr
 * el backend sin un broker).
 */
public interface TransporteEventos {

  void enviar(EntradaOutbox entrada) throws Exception;
}
