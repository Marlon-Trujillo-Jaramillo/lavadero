package com.lavadero.tenant.infrastructure.persistence;

import com.lavadero.tenant.domain.model.Tenant;
import com.lavadero.tenant.domain.model.TenantEstado;
import com.lavadero.tenant.domain.repository.TenantRepository;
import java.util.List;
import java.util.Optional;
import java.util.UUID;
import org.springframework.data.domain.PageRequest;
import org.springframework.stereotype.Repository;

@Repository
class TenantRepositoryAdapter implements TenantRepository {

  /**
   * Tope defensivo para la búsqueda pública de tenants (endpoint sin autenticación, ver {@code
   * TenantController}): sin esto, {@code query=""} devuelve el directorio completo de lavaderos de
   * la plataforma en una sola llamada. El dominio no conoce "paginación" como concepto (es una
   * pantalla de búsqueda simple, no un listado paginado real) — este límite es un detalle de
   * infraestructura, no del caso de uso.
   */
  private static final int MAX_RESULTADOS_BUSQUEDA = 25;

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
    return jpaRepository
        .buscarActivosPorNombre(query, PageRequest.of(0, MAX_RESULTADOS_BUSQUEDA))
        .stream()
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
