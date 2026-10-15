package com.lavadero.tenant.infrastructure.persistence;

import com.lavadero.shared.domain.Money;
import com.lavadero.tenant.domain.model.Pago;
import com.lavadero.tenant.domain.model.PagoEstado;
import com.lavadero.tenant.domain.repository.PagoRepository;
import java.time.Instant;
import java.util.List;
import java.util.Optional;
import java.util.UUID;
import org.springframework.data.domain.PageRequest;
import org.springframework.stereotype.Repository;
import org.springframework.transaction.annotation.Transactional;

@Repository
class PagoRepositoryAdapter implements PagoRepository {

  private final PagoJpaRepository jpaRepository;

  PagoRepositoryAdapter(PagoJpaRepository jpaRepository) {
    this.jpaRepository = jpaRepository;
  }

  @Override
  @Transactional(readOnly = true)
  public Optional<Pago> findById(UUID id) {
    return jpaRepository.findById(id).map(PagoRepositoryAdapter::toDomain);
  }

  @Override
  @Transactional(readOnly = true)
  public Optional<Pago> findByReferencia(String referencia) {
    return jpaRepository.findByReferencia(referencia).map(PagoRepositoryAdapter::toDomain);
  }

  @Override
  @Transactional(readOnly = true)
  public List<Pago> findRecientesDelTenantActual(int limite) {
    return jpaRepository.findAllByOrderByCreadoEnDesc(PageRequest.of(0, limite)).stream()
        .map(PagoRepositoryAdapter::toDomain)
        .toList();
  }

  @Override
  @Transactional(readOnly = true)
  public Optional<Pago> findPendienteDelPlanDesde(UUID subscriptionPlanId, Instant desde) {
    return jpaRepository
        .findFirstBySubscriptionPlanIdAndEstadoAndCreadoEnGreaterThanEqualOrderByCreadoEnDesc(
            subscriptionPlanId, PagoEstado.PENDIENTE.name(), desde)
        .map(PagoRepositoryAdapter::toDomain);
  }

  @Override
  @Transactional
  public Pago save(Pago pago) {
    PagoJpaEntity entity =
        new PagoJpaEntity(
            pago.getId(),
            pago.getTenantId(),
            pago.getSubscriptionPlanId(),
            pago.getMonto().monto(),
            pago.getMonto().moneda().getCurrencyCode(),
            pago.getReferencia(),
            pago.getEstado().name(),
            pago.getTransaccionExternaId().orElse(null),
            pago.getCreadoEn());
    jpaRepository.save(entity);
    return pago;
  }

  private static Pago toDomain(PagoJpaEntity entity) {
    return new Pago(
        entity.getId(),
        entity.getTenantId(),
        entity.getSubscriptionPlanId(),
        Money.de(entity.getMonto(), entity.getMoneda()),
        entity.getReferencia(),
        PagoEstado.valueOf(entity.getEstado()),
        entity.getTransaccionExternaId(),
        entity.getCreadoEn());
  }
}
