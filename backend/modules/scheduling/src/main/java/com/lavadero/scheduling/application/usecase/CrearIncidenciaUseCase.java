package com.lavadero.scheduling.application.usecase;

import com.lavadero.scheduling.application.command.CrearIncidenciaCommand;
import com.lavadero.scheduling.application.dto.IncidenciaDto;
import com.lavadero.scheduling.domain.model.Incidencia;
import com.lavadero.scheduling.domain.repository.IncidenciaRepository;
import com.lavadero.shared.application.UseCase;
import com.lavadero.shared.security.TenantContext;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

@Service
public class CrearIncidenciaUseCase implements UseCase<CrearIncidenciaCommand, IncidenciaDto> {

  private final IncidenciaRepository incidenciaRepository;

  public CrearIncidenciaUseCase(IncidenciaRepository incidenciaRepository) {
    this.incidenciaRepository = incidenciaRepository;
  }

  @Override
  @Transactional
  public IncidenciaDto execute(CrearIncidenciaCommand input) {
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
