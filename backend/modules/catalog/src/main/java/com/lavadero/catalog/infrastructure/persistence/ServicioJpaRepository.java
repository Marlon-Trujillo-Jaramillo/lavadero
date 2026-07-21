package com.lavadero.catalog.infrastructure.persistence;

import java.util.List;
import java.util.UUID;
import org.springframework.data.jpa.repository.JpaRepository;

/**
 * Repositorio Spring Data. Deliberadamente NO añade una cláusula {@code WHERE tenant_id = ...}
 * manual ni {@code WHERE activo = ...}: el aislamiento por tenant lo garantizan RLS + el filtro de
 * Hibernate; el filtrado por activos se hace en memoria sobre {@code findAll()} en el adaptador,
 * mismo patrón minimalista que {@code SucursalJpaRepository}.
 */
interface ServicioJpaRepository extends JpaRepository<ServicioJpaEntity, UUID> {

  List<ServicioJpaEntity> findAll();
}
