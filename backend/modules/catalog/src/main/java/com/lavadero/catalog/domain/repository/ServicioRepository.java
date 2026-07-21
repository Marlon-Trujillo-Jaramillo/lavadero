package com.lavadero.catalog.domain.repository;

import com.lavadero.catalog.domain.model.Servicio;
import java.util.List;
import java.util.Optional;
import java.util.UUID;

/**
 * Puerto de persistencia de {@link Servicio}. Igual que {@code SucursalRepository}
 * (tenant-management), {@code findAllDelTenantActual()} NO filtra manualmente por tenant: esa
 * responsabilidad es de la política RLS de la migración (V5__catalog.sql) + el filtro de sesión de
 * Hibernate, no de esta query.
 */
public interface ServicioRepository {

  Optional<Servicio> findById(UUID id);

  List<Servicio> findAllDelTenantActual();

  List<Servicio> findActivosDelTenantActual();

  Servicio save(Servicio servicio);
}
