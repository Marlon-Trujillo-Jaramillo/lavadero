package com.lavadero.scheduling.application.usecase;

import com.lavadero.scheduling.application.command.ReservaStaffCommand;
import com.lavadero.scheduling.application.dto.ChecklistItemDto;
import com.lavadero.scheduling.domain.repository.ChecklistItemRepository;
import com.lavadero.scheduling.domain.repository.ReservaRepository;
import com.lavadero.shared.application.UseCase;
import java.util.List;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

@Service
public class ObtenerChecklistUseCase
    implements UseCase<ReservaStaffCommand, List<ChecklistItemDto>> {

  private final ReservaRepository reservaRepository;
  private final ChecklistItemRepository checklistItemRepository;

  public ObtenerChecklistUseCase(
      ReservaRepository reservaRepository, ChecklistItemRepository checklistItemRepository) {
    this.reservaRepository = reservaRepository;
    this.checklistItemRepository = checklistItemRepository;
  }

  @Override
  @Transactional(readOnly = true)
  public List<ChecklistItemDto> execute(ReservaStaffCommand input) {
    ReservaDelAlcance.cargar(reservaRepository, input.reservaId(), input.alcance());
    return ChecklistMapper.listaCompleta(input.reservaId(), checklistItemRepository);
  }
}
