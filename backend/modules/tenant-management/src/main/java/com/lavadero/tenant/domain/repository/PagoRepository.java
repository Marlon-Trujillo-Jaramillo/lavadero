package com.lavadero.tenant.domain.repository;

import com.lavadero.tenant.domain.model.Pago;
import java.util.List;
import java.util.Optional;
import java.util.UUID;

public interface PagoRepository {

  Optional<Pago> findById(UUID id);

  /** Correlaciona un evento de webhook con el pago que lo originó. */
  Optional<Pago> findByReferencia(String referencia);

  List<Pago> findAllDelTenantActual();

  Pago save(Pago pago);
}
