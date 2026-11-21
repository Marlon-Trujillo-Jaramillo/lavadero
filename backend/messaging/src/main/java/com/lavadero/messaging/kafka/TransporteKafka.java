package com.lavadero.messaging.kafka;

import com.lavadero.messaging.EntradaOutbox;
import com.lavadero.messaging.TransporteEventos;
import java.nio.charset.StandardCharsets;
import java.util.concurrent.TimeUnit;
import org.apache.kafka.clients.producer.ProducerRecord;
import org.springframework.boot.autoconfigure.condition.ConditionalOnProperty;
import org.springframework.kafka.core.KafkaTemplate;
import org.springframework.stereotype.Component;

/**
 * Publica en el tópico del tipo, con la clave del evento (orden por reserva) y headers con el tipo,
 * el tenant y el id del evento. Espera la confirmación del broker (acks=all): el outbox solo marca
 * "publicado" lo que Kafka ya guardó.
 */
@Component
@ConditionalOnProperty(name = "lavadero.mensajeria.transporte", havingValue = "kafka")
class TransporteKafka implements TransporteEventos {

  static final long ESPERA_SEGUNDOS = 10;

  private final KafkaTemplate<String, String> kafka;

  TransporteKafka(KafkaTemplate<String, String> kafka) {
    this.kafka = kafka;
  }

  @Override
  public void enviar(EntradaOutbox entrada) throws Exception {
    ProducerRecord<String, String> mensaje =
        new ProducerRecord<>(entrada.topico(), entrada.clave(), entrada.payload());
    mensaje.headers().add(EncabezadosKafka.TIPO, bytes(entrada.tipo()));
    mensaje.headers().add(EncabezadosKafka.TENANT, bytes(entrada.tenantId().toString()));
    mensaje.headers().add(EncabezadosKafka.EVENTO_ID, bytes(entrada.id().toString()));
    kafka.send(mensaje).get(ESPERA_SEGUNDOS, TimeUnit.SECONDS);
  }

  private static byte[] bytes(String valor) {
    return valor.getBytes(StandardCharsets.UTF_8);
  }
}
