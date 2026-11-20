package com.lavadero.scheduling.application.usecase;

import com.lavadero.scheduling.application.command.ArchivarVehiculoCommand;
import com.lavadero.scheduling.domain.model.Vehiculo;
import com.lavadero.scheduling.domain.repository.VehiculoRepository;
import com.lavadero.shared.application.UseCase;
import com.lavadero.shared.application.exception.NotFoundException;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

/**
 * Quita un vehículo de "Mis vehículos" sin borrarlo (las reservas pasadas lo referencian). Si es de
 * otro cliente responde 404, no 403: no confirma que ese id exista.
 */
@Service
public class ArchivarVehiculoUseCase implements UseCase<ArchivarVehiculoCommand, Void> {

  private final VehiculoRepository vehiculoRepository;

  public ArchivarVehiculoUseCase(VehiculoRepository vehiculoRepository) {
    this.vehiculoRepository = vehiculoRepository;
  }

  @Override
  @Transactional
  public Void execute(ArchivarVehiculoCommand input) {
    Vehiculo vehiculo =
        vehiculoRepository
            .findById(input.vehiculoId())
            .filter(v -> v.perteneceA(input.clienteId()) && v.isActivo())
            .orElseThrow(() -> NotFoundException.de("Vehículo", input.vehiculoId()));
    vehiculo.archivar();
    vehiculoRepository.save(vehiculo);
    return null;
  }
}
