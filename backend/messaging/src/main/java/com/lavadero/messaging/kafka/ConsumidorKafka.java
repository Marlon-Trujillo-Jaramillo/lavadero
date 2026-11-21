package com.lavadero.messaging.kafka;

import com.lavadero.messaging.DespachadorEventos;
import java.nio.charset.StandardCharsets;
import org.apache.kafka.clients.consumer.ConsumerRecord;
import org.apache.kafka.common.header.Header;
import org.springframework.boot.autoconfigure.condition.ConditionalOnProperty;
import org.springframework.kafka.annotation.KafkaListener;
import org.springframework.stereotype.Component;

/**
 * Lee los tópicos de {@code CatalogoEventos} y entrega cada mensaje al despachador. Si el manejador
 * falla, el error handler de {@link KafkaConfig} reintenta y, agotados los reintentos, manda el
 * mensaje al tópico {@code .DLT} para revisarlo sin frenar la partición.
 */
@Component
@ConditionalOnProperty(name = "lavadero.mensajeria.transporte", havingValue = "kafka")
class ConsumidorKafka {

  private final DespachadorEventos despachador;

  ConsumidorKafka(DespachadorEventos despachador) {
    this.despachador = despachador;
  }

  @KafkaListener(
      topics = "#{T(com.lavadero.messaging.kafka.KafkaConfig).topicos()}",
      groupId = "${lavadero.mensajeria.kafka.grupo:lavadero-backend}")
  void recibir(ConsumerRecord<String, String> mensaje) {
    Header tipo = mensaje.headers().lastHeader(EncabezadosKafka.TIPO);
    if (tipo == null) {
      throw new IllegalArgumentException("Mensaje sin header " + EncabezadosKafka.TIPO);
    }
    despachador.despachar(new String(tipo.value(), StandardCharsets.UTF_8), mensaje.value());
  }
}
