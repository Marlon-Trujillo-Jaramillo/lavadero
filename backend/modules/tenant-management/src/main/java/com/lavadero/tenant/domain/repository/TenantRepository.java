package com.lavadero.tenant.domain.repository;

import com.lavadero.tenant.domain.model.Tenant;
import java.util.List;
import java.util.Optional;
import java.util.UUID;

/**
 * Puerto de persistencia para {@link Tenant}. La implementación (adaptador JPA) vive en
 * `infrastructure/persistence`; `domain` no conoce Spring Data ni JPA.
 */
public interface TenantRepository {

  Optional<Tenant> findById(UUID id);

  Optional<Tenant> findBySlug(String slug);

  boolean existsBySlug(String slug);

  List<Tenant> buscarActivosPorNombre(String query);

  Tenant save(Tenant tenant);
}
