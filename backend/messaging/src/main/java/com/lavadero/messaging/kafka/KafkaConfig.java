package com.lavadero.messaging.kafka;

import com.lavadero.contracts.CatalogoEventos;
import org.apache.kafka.clients.admin.NewTopic;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.boot.autoconfigure.condition.ConditionalOnProperty;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.kafka.config.TopicBuilder;
import org.springframework.kafka.core.KafkaAdmin;
import org.springframework.kafka.core.KafkaTemplate;
import org.springframework.kafka.listener.DeadLetterPublishingRecoverer;
import org.springframework.kafka.listener.DefaultErrorHandler;
import org.springframework.util.backoff.ExponentialBackOff;

/**
 * Tópicos (uno por tipo de evento, más su {@code .DLT}) y manejo de errores del consumidor:
 * reintentos con backoff exponencial y, si siguen fallando, el mensaje va a la cola de muertos con
 * su error en los headers. Un JSON ilegible no se reintenta: no se va a arreglar solo.
 */
@Configuration
@ConditionalOnProperty(name = "lavadero.mensajeria.transporte", havingValue = "kafka")
public class KafkaConfig {

  static final String SUFIJO_DLT = ".DLT";

  /** Público: lo usa el {@code @KafkaListener} de {@link ConsumidorKafka} por SpEL. */
  public static String[] topicos() {
    return CatalogoEventos.todos().stream()
        .map(CatalogoEventos.Tipo::topico)
        .toArray(String[]::new);
  }

  @Bean
  KafkaAdmin.NewTopics topicosLavadero(
      @Value("${lavadero.mensajeria.kafka.particiones:3}") int particiones,
      @Value("${lavadero.mensajeria.kafka.replicas:1}") short replicas) {
    return new KafkaAdmin.NewTopics(
        CatalogoEventos.todos().stream()
            .flatMap(
                t ->
                    java.util.stream.Stream.of(
                        TopicBuilder.name(t.topico())
                            .partitions(particiones)
                            .replicas(replicas)
                            .build(),
                        TopicBuilder.name(t.topico() + SUFIJO_DLT)
                            .partitions(1)
                            .replicas(replicas)
                            .build()))
            .toArray(NewTopic[]::new));
  }

  @Bean
  DefaultErrorHandler manejadorErroresKafka(
      KafkaTemplate<String, String> kafka,
      @Value("${lavadero.mensajeria.kafka.reintentos:3}") int reintentos) {
    DeadLetterPublishingRecoverer aDlt =
        new DeadLetterPublishingRecoverer(
            kafka,
            (mensaje, error) ->
                new org.apache.kafka.common.TopicPartition(mensaje.topic() + SUFIJO_DLT, 0));
    ExponentialBackOff backoff = new ExponentialBackOff(500, 2.0);
    backoff.setMaxAttempts(reintentos);
    DefaultErrorHandler handler = new DefaultErrorHandler(aDlt, backoff);
    handler.addNotRetryableExceptions(IllegalArgumentException.class);
    return handler;
  }
}
