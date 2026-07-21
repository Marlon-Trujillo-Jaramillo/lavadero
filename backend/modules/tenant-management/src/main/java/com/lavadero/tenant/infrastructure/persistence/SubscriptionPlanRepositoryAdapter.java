package com.lavadero.tenant.infrastructure.persistence;

import com.lavadero.shared.domain.Money;
import com.lavadero.tenant.domain.model.SubscriptionPlan;
import com.lavadero.tenant.domain.repository.SubscriptionPlanRepository;
import java.util.Currency;
import java.util.Optional;
import java.util.UUID;
import org.springframework.stereotype.Repository;

@Repository
class SubscriptionPlanRepositoryAdapter implements SubscriptionPlanRepository {

  private final SubscriptionPlanJpaRepository jpaRepository;

  SubscriptionPlanRepositoryAdapter(SubscriptionPlanJpaRepository jpaRepository) {
    this.jpaRepository = jpaRepository;
  }

  @Override
  public Optional<SubscriptionPlan> findById(UUID id) {
    return jpaRepository.findById(id).map(SubscriptionPlanRepositoryAdapter::toDomain);
  }

  @Override
  public Optional<SubscriptionPlan> findDefault() {
    // Plan sembrado por la migración V1 (ver INSERT en V1__tenant_management.sql).
    return jpaRepository.findAll().stream()
        .findFirst()
        .map(SubscriptionPlanRepositoryAdapter::toDomain);
  }

  @Override
  public SubscriptionPlan save(SubscriptionPlan plan) {
    SubscriptionPlanJpaEntity entity =
        new SubscriptionPlanJpaEntity(
            plan.getId(),
            plan.getNombre(),
            plan.getPrecio().monto(),
            plan.getPrecio().moneda().getCurrencyCode(),
            plan.getMaxSucursales(),
            plan.getMaxEmpleados(),
            plan.getFeatures());
    jpaRepository.save(entity);
    return plan;
  }

  private static SubscriptionPlan toDomain(SubscriptionPlanJpaEntity entity) {
    return new SubscriptionPlan(
        entity.getId(),
        entity.getNombre(),
        Money.de(entity.getPrecio(), Currency.getInstance(entity.getMoneda())),
        entity.getMaxSucursales(),
        entity.getMaxEmpleados(),
        entity.getFeatures());
  }
}
