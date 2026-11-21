package com.lavadero.messaging;

import org.springframework.boot.autoconfigure.condition.ConditionalOnProperty;
import org.springframework.stereotype.Component;
import org.springframework.transaction.PlatformTransactionManager;
import org.springframework.transaction.TransactionDefinition;
import org.springframework.transaction.support.TransactionTemplate;

/**
 * Entrega el evento a sus manejadores en el mismo proceso. Es el transporte por defecto: el backend
 * corre en local sin Kafka y con la misma garantía (outbox + reintentos + manejadores
 * idempotentes).
 *
 * <p>Cada entrega va en su PROPIA transacción ({@code REQUIRES_NEW}), no en la del relay: si un
 * manejador falla, se revierte solo su trabajo y el relay anota el fallo de ese evento y sigue con
 * el lote, como pasaría con Kafka.
 */
@Component
@ConditionalOnProperty(
    name = "lavadero.mensajeria.transporte",
    havingValue = "local",
    matchIfMissing = true)
class TransporteLocal implements TransporteEventos {

  private final DespachadorEventos despachador;
  private final TransactionTemplate txNueva;

  TransporteLocal(DespachadorEventos despachador, PlatformTransactionManager transactionManager) {
    this.despachador = despachador;
    this.txNueva = new TransactionTemplate(transactionManager);
    this.txNueva.setPropagationBehavior(TransactionDefinition.PROPAGATION_REQUIRES_NEW);
  }

  @Override
  public void enviar(EntradaOutbox entrada) {
    txNueva.executeWithoutResult(
        status -> despachador.despachar(entrada.tipo(), entrada.payload()));
  }
}
