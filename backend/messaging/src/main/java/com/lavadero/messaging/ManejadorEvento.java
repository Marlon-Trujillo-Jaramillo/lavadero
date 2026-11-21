package com.lavadero.messaging;

import com.lavadero.contracts.EventoIntegracion;

/**
 * Lo que implementa un módulo para recibir un evento de integración. Se llama igual sin importar el
 * transporte (Kafka o en el mismo proceso), con el {@code TenantContext} del evento ya fijado.
 *
 * <p>La entrega es "al menos una vez": el mismo evento puede llegar dos veces (un reintento tras un
 * fallo, un rebalanceo de Kafka). Todo manejador tiene que ser idempotente.
 */
public interface ManejadorEvento<E extends EventoIntegracion> {

  Class<E> tipo();

  void manejar(E evento);
}
