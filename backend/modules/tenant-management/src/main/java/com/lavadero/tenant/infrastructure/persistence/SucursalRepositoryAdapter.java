package com.lavadero.tenant.infrastructure.persistence;

import com.lavadero.tenant.domain.model.Sucursal;
import com.lavadero.tenant.domain.repository.SucursalRepository;
import java.util.List;
import java.util.Optional;
import java.util.UUID;
import org.springframework.stereotype.Repository;
import org.springframework.transaction.annotation.Transactional;

/**
 * Adaptador de {@link SucursalRepository}. Los métodos se anotan explícitamente
 * {@code @Transactional} (en vez de confiar solo en la transaccionalidad por defecto de Spring
 * Data) para garantizar que, sin importar desde qué bean se invoquen, {@code
 * TenantAwareTransactionAspect} (identity-access) se dispare y aplique `SET LOCAL
 * app.current_tenant_id` + el filtro de Hibernate con el valor vigente de {@code TenantContext}
 * justo antes de tocar la base de datos.
 */
@Repository
class SucursalRepositoryAdapter implements SucursalRepository {

  private final SucursalJpaRepository jpaRepository;

  SucursalRepositoryAdapter(SucursalJpaRepository jpaRepository) {
    this.jpaRepository = jpaRepository;
  }

  @Override
  @Transactional(readOnly = true)
  public Optional<Sucursal> findById(UUID id) {
    return jpaRepository.findById(id).map(SucursalRepositoryAdapter::toDomain);
  }

  @Override
  @Transactional(readOnly = true)
  public List<Sucursal> findAllDelTenantActual() {
    return jpaRepository.findAll().stream().map(SucursalRepositoryAdapter::toDomain).toList();
  }

  @Override
  @Transactional
  public Sucursal save(Sucursal sucursal) {
    SucursalJpaEntity entity =
        new SucursalJpaEntity(
            sucursal.getId(),
            sucursal.getTenantId(),
            sucursal.getNombre(),
            sucursal.getDireccion(),
            sucursal.getCapacidadSimultanea());
    jpaRepository.save(entity);
    return sucursal;
  }

  private static Sucursal toDomain(SucursalJpaEntity entity) {
    return new Sucursal(
        entity.getId(),
        entity.getTenantId(),
        entity.getNombre(),
        entity.getDireccion(),
        entity.getCapacidadSimultanea());
  }
}
