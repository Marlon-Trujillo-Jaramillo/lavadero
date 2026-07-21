package com.lavadero.tenant.infrastructure.persistence;

import com.lavadero.tenant.domain.model.Tenant;
import com.lavadero.tenant.domain.model.TenantEstado;
import com.lavadero.tenant.domain.repository.TenantRepository;
import java.util.List;
import java.util.Optional;
import java.util.UUID;
import org.springframework.stereotype.Repository;

@Repository
class TenantRepositoryAdapter implements TenantRepository {

  private final TenantJpaRepository jpaRepository;

  TenantRepositoryAdapter(TenantJpaRepository jpaRepository) {
    this.jpaRepository = jpaRepository;
  }

  @Override
  public Optional<Tenant> findById(UUID id) {
    return jpaRepository.findById(id).map(TenantRepositoryAdapter::toDomain);
  }

  @Override
  public Optional<Tenant> findBySlug(String slug) {
    return jpaRepository.findBySlug(slug).map(TenantRepositoryAdapter::toDomain);
  }

  @Override
  public boolean existsBySlug(String slug) {
    return jpaRepository.existsBySlug(slug);
  }

  @Override
  public List<Tenant> buscarActivosPorNombre(String query) {
    return jpaRepository.buscarActivosPorNombre(query).stream()
        .map(TenantRepositoryAdapter::toDomain)
        .toList();
  }

  @Override
  public Tenant save(Tenant tenant) {
    TenantJpaEntity entity =
        new TenantJpaEntity(
            tenant.getId(),
            tenant.getNombre(),
            tenant.getNit(),
            tenant.getSlug(),
            tenant.getEstado().name(),
            tenant.getSubscriptionPlanId(),
            tenant.getFechaCreacion());
    jpaRepository.save(entity);
    return tenant;
  }

  private static Tenant toDomain(TenantJpaEntity entity) {
    return new Tenant(
        entity.getId(),
        entity.getNombre(),
        entity.getNit(),
        entity.getSlug(),
        TenantEstado.valueOf(entity.getEstado()),
        entity.getSubscriptionPlanId(),
        entity.getFechaCreacion());
  }
}
