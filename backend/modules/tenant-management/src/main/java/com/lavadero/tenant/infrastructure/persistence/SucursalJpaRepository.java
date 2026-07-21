package com.lavadero.tenant.infrastructure.persistence;

import java.util.List;
import java.util.UUID;
import org.springframework.data.jpa.repository.JpaRepository;

/**
 * Repositorio Spring Data. Deliberadamente NO añade una cláusula {@code WHERE tenant_id = ...}
 * manual: el aislamiento lo garantizan la política RLS de Postgres y el filtro de Hibernate
 * habilitado a nivel de sesión (ver {@code TenantAwareTransactionAspect} en identity-access). Esto
 * es lo que el test de integración con Testcontainers verifica end-to-end.
 */
interface SucursalJpaRepository extends JpaRepository<SucursalJpaEntity, UUID> {

  List<SucursalJpaEntity> findAll();
}
