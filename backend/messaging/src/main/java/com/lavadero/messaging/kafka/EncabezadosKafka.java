package com.lavadero.messaging.kafka;

/** Headers de los mensajes de Lavadero en Kafka. */
final class EncabezadosKafka {

  static final String TIPO = "lavadero-tipo";
  static final String TENANT = "lavadero-tenant";
  static final String EVENTO_ID = "lavadero-evento-id";

  private EncabezadosKafka() {}
}
