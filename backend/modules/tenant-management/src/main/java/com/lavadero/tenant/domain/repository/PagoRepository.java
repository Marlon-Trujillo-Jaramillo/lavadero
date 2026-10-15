package com.lavadero.tenant.domain.repository;

import com.lavadero.tenant.domain.model.Pago;
import java.time.Instant;
import java.util.List;
import java.util.Optional;
import java.util.UUID;

public interface PagoRepository {

  Optional<Pago> findById(UUID id);

  /** Correlaciona un evento de webhook con el pago que lo originó. */
  Optional<Pago> findByReferencia(String referencia);

  /** Pagos del tenant actual, más recientes primero, como mucho {@code limite}. */
  List<Pago> findRecientesDelTenantActual(int limite);

  /**
   * El pago PENDIENTE más reciente del tenant actual para ese plan creado en o después de {@code
   * desde} — para reusarlo en vez de crear uno nuevo en cada clic de "pagar".
   */
  Optional<Pago> findPendienteDelPlanDesde(UUID subscriptionPlanId, Instant desde);

  Pago save(Pago pago);
}
