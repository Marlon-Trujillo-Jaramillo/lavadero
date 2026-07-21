package com.lavadero.catalog.infrastructure.persistence;

import com.lavadero.catalog.domain.model.Servicio;
import com.lavadero.catalog.domain.repository.ServicioRepository;
import com.lavadero.shared.domain.Money;
import java.util.List;
import java.util.Optional;
import java.util.UUID;
import org.springframework.stereotype.Repository;
import org.springframework.transaction.annotation.Transactional;

/**
 * Adaptador de {@link ServicioRepository}. Cada método se anota explícitamente
 * {@code @Transactional} (no confía en la transaccionalidad implícita de Spring Data) para que
 * {@code TenantAwareTransactionAspect} (identity-access) se dispare siempre — mismo motivo que
 * {@code SucursalRepositoryAdapter}.
 */
@Repository
class ServicioRepositoryAdapter implements ServicioRepository {

  private final ServicioJpaRepository jpaRepository;

  ServicioRepositoryAdapter(ServicioJpaRepository jpaRepository) {
    this.jpaRepository = jpaRepository;
  }

  @Override
  @Transactional(readOnly = true)
  public Optional<Servicio> findById(UUID id) {
    return jpaRepository.findById(id).map(ServicioRepositoryAdapter::toDomain);
  }

  @Override
  @Transactional(readOnly = true)
  public List<Servicio> findAllDelTenantActual() {
    return jpaRepository.findAll().stream().map(ServicioRepositoryAdapter::toDomain).toList();
  }

  @Override
  @Transactional(readOnly = true)
  public List<Servicio> findActivosDelTenantActual() {
    return jpaRepository.findAll().stream()
        .filter(ServicioJpaEntity::isActivo)
        .map(ServicioRepositoryAdapter::toDomain)
        .toList();
  }

  @Override
  @Transactional
  public Servicio save(Servicio servicio) {
    ServicioJpaEntity entity =
        new ServicioJpaEntity(
            servicio.getId(),
            servicio.getTenantId(),
            servicio.getNombre(),
            servicio.getDescripcion(),
            servicio.getDuracionEstimadaMinutos(),
            servicio.getPrecio().monto(),
            servicio.getPrecio().moneda().getCurrencyCode(),
            servicio.isActivo());
    jpaRepository.save(entity);
    return servicio;
  }

  private static Servicio toDomain(ServicioJpaEntity entity) {
    return new Servicio(
        entity.getId(),
        entity.getTenantId(),
        entity.getNombre(),
        entity.getDescripcion(),
        entity.getDuracionEstimadaMinutos(),
        Money.de(entity.getPrecio(), entity.getMoneda()),
        entity.isActivo());
  }
}
