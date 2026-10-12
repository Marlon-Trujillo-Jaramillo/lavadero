package com.lavadero.scheduling.application.usecase;

import com.lavadero.scheduling.application.dto.ChecklistItemDto;
import com.lavadero.scheduling.domain.repository.ChecklistItemRepository;
import com.lavadero.scheduling.domain.repository.ReservaRepository;
import com.lavadero.shared.application.UseCase;
import com.lavadero.shared.application.exception.NotFoundException;
import java.util.List;
import java.util.UUID;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

@Service
public class ObtenerChecklistUseCase implements UseCase<UUID, List<ChecklistItemDto>> {

  private final ReservaRepository reservaRepository;
  private final ChecklistItemRepository checklistItemRepository;

  public ObtenerChecklistUseCase(
      ReservaRepository reservaRepository, ChecklistItemRepository checklistItemRepository) {
    this.reservaRepository = reservaRepository;
    this.checklistItemRepository = checklistItemRepository;
  }

  @Override
  @Transactional(readOnly = true)
  public List<ChecklistItemDto> execute(UUID reservaId) {
    reservaRepository.findById(reservaId).orElseThrow(() -> NotFoundException.de("Reserva", reservaId));
    return ChecklistMapper.listaCompleta(reservaId, checklistItemRepository);
  }
}
