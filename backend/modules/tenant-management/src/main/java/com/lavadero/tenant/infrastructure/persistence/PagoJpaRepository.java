package com.lavadero.tenant.infrastructure.persistence;

import java.time.Instant;
import java.util.List;
import java.util.Optional;
import java.util.UUID;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;

/**
 * Repositorio Spring Data. Deliberadamente NO añade cláusulas manuales de aislamiento por tenant:
 * eso lo garantizan la política RLS de Postgres y el filtro de Hibernate a nivel de sesión.
 */
interface PagoJpaRepository extends JpaRepository<PagoJpaEntity, UUID> {

  Optional<PagoJpaEntity> findByReferencia(String referencia);

  List<PagoJpaEntity> findAllByOrderByCreadoEnDesc(Pageable pagina);

  Optional<PagoJpaEntity>
      findFirstBySubscriptionPlanIdAndEstadoAndCreadoEnGreaterThanEqualOrderByCreadoEnDesc(
          UUID subscriptionPlanId, String estado, Instant desde);
}
