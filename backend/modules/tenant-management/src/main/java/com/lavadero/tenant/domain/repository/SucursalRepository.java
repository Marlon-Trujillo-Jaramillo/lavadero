package com.lavadero.tenant.domain.repository;

import com.lavadero.tenant.domain.model.Sucursal;
import java.util.List;
import java.util.Optional;
import java.util.UUID;

/**
 * Puerto de persistencia para {@link Sucursal}. Todas las consultas quedan naturalmente acotadas al
 * tenant actual por la política RLS de Postgres (ver migración V1) más el filtro de Hibernate
 * (defensa en profundidad configurada en `identity-access`) — el adaptador NO añade un `WHERE
 * tenant_id = ...` manual: confía en esas dos capas.
 */
public interface SucursalRepository {

  Optional<Sucursal> findById(UUID id);

  List<Sucursal> findAllDelTenantActual();

  Sucursal save(Sucursal sucursal);
}
