package com.lavadero.scheduling.domain.repository;

import com.lavadero.scheduling.domain.model.Placa;
import com.lavadero.scheduling.domain.model.Vehiculo;
import java.util.List;
import java.util.Optional;
import java.util.UUID;

public interface VehiculoRepository {

  /** Vehículos activos del cliente, del más reciente al más antiguo (acotado por RLS al tenant). */
  List<Vehiculo> findActivosByClienteId(UUID clienteId);

  Optional<Vehiculo> findById(UUID id);

  boolean existeActivoConPlaca(UUID clienteId, Placa placa);

  Vehiculo save(Vehiculo vehiculo);
}
