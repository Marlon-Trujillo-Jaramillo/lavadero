package com.lavadero.inventory.domain.repository;

import com.lavadero.inventory.domain.model.Insumo;
import java.util.List;
import java.util.Optional;
import java.util.UUID;

public interface InsumoRepository {

  Insumo save(Insumo insumo);

  Optional<Insumo> findById(UUID id);

  /** Activos, por nombre. */
  List<Insumo> listarActivos();

  boolean existeActivoConNombre(String nombre);
}
