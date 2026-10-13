package com.lavadero.scheduling.application.usecase;

import com.lavadero.scheduling.application.command.CrearIncidenciaCommand;
import com.lavadero.scheduling.application.dto.IncidenciaDto;
import com.lavadero.scheduling.domain.model.Incidencia;
import com.lavadero.scheduling.domain.model.Reserva;
import com.lavadero.scheduling.domain.repository.IncidenciaRepository;
import com.lavadero.scheduling.domain.repository.ReservaRepository;
import com.lavadero.shared.application.UseCase;
import com.lavadero.shared.application.exception.NotFoundException;
import com.lavadero.shared.application.exception.ValidationException;
import com.lavadero.shared.security.TenantContext;
import com.lavadero.tenant.application.usecase.ObtenerSucursalPorIdUseCase;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

/**
 * Registra una incidencia del staff. Resuelve sucursal y reserva antes de insertar: las FKs de
 * Postgres no pasan por RLS, así que sin esta lectura (que sí la aplica) una incidencia podría
 * apuntar a la sucursal o reserva de otro tenant.
 */
@Service
public class CrearIncidenciaUseCase implements UseCase<CrearIncidenciaCommand, IncidenciaDto> {

  private final IncidenciaRepository incidenciaRepository;
  private final ReservaRepository reservaRepository;
  private final ObtenerSucursalPorIdUseCase obtenerSucursalPorIdUseCase;

  public CrearIncidenciaUseCase(
      IncidenciaRepository incidenciaRepository,
      ReservaRepository reservaRepository,
      ObtenerSucursalPorIdUseCase obtenerSucursalPorIdUseCase) {
    this.incidenciaRepository = incidenciaRepository;
    this.reservaRepository = reservaRepository;
    this.obtenerSucursalPorIdUseCase = obtenerSucursalPorIdUseCase;
  }

  @Override
  @Transactional
  public IncidenciaDto execute(CrearIncidenciaCommand input) {
    input.alcance().verificar(input.sucursalId());
    obtenerSucursalPorIdUseCase.execute(input.sucursalId());
    if (input.reservaId() != null) {
      Reserva reserva =
          reservaRepository
              .findById(input.reservaId())
              .orElseThrow(() -> NotFoundException.de("Reserva", input.reservaId()));
      if (!reserva.getSucursalId().equals(input.sucursalId())) {
        throw new ValidationException("La reserva no pertenece a esa sucursal");
      }
    }

    Incidencia incidencia =
        Incidencia.nueva(
            TenantContext.requerido(),
            input.sucursalId(),
            input.reservaId(),
            input.reportadoPorUsuarioId(),
            input.categoria(),
            input.descripcion());
    return IncidenciaMapper.toDto(incidenciaRepository.save(incidencia));
  }
}
