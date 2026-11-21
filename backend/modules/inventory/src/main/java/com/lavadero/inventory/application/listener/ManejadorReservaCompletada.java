package com.lavadero.inventory.application.listener;

import com.lavadero.contracts.scheduling.ReservaCompletadaEvent;
import com.lavadero.inventory.application.usecase.RegistrarConsumoDeReservaUseCase;
import com.lavadero.messaging.ManejadorEvento;
import org.springframework.stereotype.Component;

/**
 * Descuenta los insumos cuando llega {@link ReservaCompletadaEvent} desde el outbox (Kafka o el
 * mismo proceso; ver `messaging`). El consumo ya no es atómico con la completación sino eventual:
 * lo garantiza el outbox, que se escribe en la transacción de la reserva. El caso de uso es
 * idempotente, porque la entrega es "al menos una vez".
 */
@Component
class ManejadorReservaCompletada implements ManejadorEvento<ReservaCompletadaEvent> {

  private final RegistrarConsumoDeReservaUseCase registrarConsumo;

  ManejadorReservaCompletada(RegistrarConsumoDeReservaUseCase registrarConsumo) {
    this.registrarConsumo = registrarConsumo;
  }

  @Override
  public Class<ReservaCompletadaEvent> tipo() {
    return ReservaCompletadaEvent.class;
  }

  @Override
  public void manejar(ReservaCompletadaEvent evento) {
    registrarConsumo.execute(evento);
  }
}
