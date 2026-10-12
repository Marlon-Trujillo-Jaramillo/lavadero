package com.lavadero.tenant.infrastructure.persistence;

import java.util.List;
import java.util.Optional;
import java.util.UUID;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

interface TenantJpaRepository extends JpaRepository<TenantJpaEntity, UUID> {

  Optional<TenantJpaEntity> findBySlug(String slug);

  boolean existsBySlug(String slug);

  @Query(
      "select t from TenantJpaEntity t "
          + "where t.estado = 'ACTIVO' and lower(t.nombre) like lower(concat('%', :query, '%')) "
          + "order by t.nombre")
  List<TenantJpaEntity> buscarActivosPorNombre(@Param("query") String query, Pageable pageable);
}
