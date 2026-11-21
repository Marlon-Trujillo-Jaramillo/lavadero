package com.lavadero.inventory.application.listener;

import com.lavadero.contracts.scheduling.ReservaCompletadaEvent;
import com.lavadero.inventory.application.usecase.RegistrarConsumoDeReservaUseCase;
import org.springframework.stereotype.Component;
import org.springframework.transaction.event.TransactionPhase;
import org.springframework.transaction.event.TransactionalEventListener;

/**
 * Escucha {@link ReservaCompletadaEvent} ANTES del commit de la transacción que completó la
 * reserva: el descuento de insumos y el cambio de estado se confirman juntos o ninguno (no hay un
 * lavado completado sin su consumo, ni un consumo de un lavado que al final no se completó). La
 * fase de Kafka cambiará esto por un outbox y un consumidor asíncrono; el caso de uso ya es
 * idempotente para esa entrega "al menos una vez".
 */
@Component
class ConsumoAlCompletarReserva {

  private final RegistrarConsumoDeReservaUseCase registrarConsumo;

  ConsumoAlCompletarReserva(RegistrarConsumoDeReservaUseCase registrarConsumo) {
    this.registrarConsumo = registrarConsumo;
  }

  @TransactionalEventListener(phase = TransactionPhase.BEFORE_COMMIT)
  void alCompletar(ReservaCompletadaEvent evento) {
    registrarConsumo.execute(evento);
  }
}
