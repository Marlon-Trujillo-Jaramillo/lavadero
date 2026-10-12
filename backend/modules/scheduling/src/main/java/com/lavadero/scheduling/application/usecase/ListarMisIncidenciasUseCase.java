package com.lavadero.scheduling.application.usecase;

import com.lavadero.scheduling.application.dto.IncidenciaDto;
import com.lavadero.scheduling.domain.repository.IncidenciaRepository;
import com.lavadero.shared.application.UseCase;
import java.util.List;
import java.util.UUID;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

/** Incidencias reportadas por el usuario actual — mismo patrón que {@code ListarMisReservasUseCase}. */
@Service
public class ListarMisIncidenciasUseCase implements UseCase<UUID, List<IncidenciaDto>> {

  private final IncidenciaRepository incidenciaRepository;

  public ListarMisIncidenciasUseCase(IncidenciaRepository incidenciaRepository) {
    this.incidenciaRepository = incidenciaRepository;
  }

  @Override
  @Transactional(readOnly = true)
  public List<IncidenciaDto> execute(UUID usuarioId) {
    return incidenciaRepository.findByReportadoPorUsuarioId(usuarioId).stream()
        .map(IncidenciaMapper::toDto)
        .toList();
  }
}
