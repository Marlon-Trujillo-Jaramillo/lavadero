package com.lavadero.scheduling.application.usecase;

import com.lavadero.scheduling.application.command.MarcarChecklistItemCommand;
import com.lavadero.scheduling.application.dto.ChecklistItemDto;
import com.lavadero.scheduling.domain.model.ChecklistItem;
import com.lavadero.scheduling.domain.repository.ChecklistItemRepository;
import com.lavadero.scheduling.domain.repository.ReservaRepository;
import com.lavadero.shared.application.UseCase;
import com.lavadero.shared.security.TenantContext;
import java.util.List;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

@Service
public class MarcarChecklistItemUseCase
    implements UseCase<MarcarChecklistItemCommand, List<ChecklistItemDto>> {

  private final ReservaRepository reservaRepository;
  private final ChecklistItemRepository checklistItemRepository;

  public MarcarChecklistItemUseCase(
      ReservaRepository reservaRepository, ChecklistItemRepository checklistItemRepository) {
    this.reservaRepository = reservaRepository;
    this.checklistItemRepository = checklistItemRepository;
  }

  @Override
  @Transactional
  public List<ChecklistItemDto> execute(MarcarChecklistItemCommand input) {
    ReservaDelAlcance.cargar(reservaRepository, input.reservaId(), input.alcance());

    ChecklistItem item =
        checklistItemRepository
            .findByReservaIdAndTipo(input.reservaId(), input.tipo())
            .orElseGet(
                () ->
                    ChecklistItem.nuevo(
                        TenantContext.requerido(), input.reservaId(), input.tipo()));
    item.marcar(input.completado());
    checklistItemRepository.save(item);

    return ChecklistMapper.listaCompleta(input.reservaId(), checklistItemRepository);
  }
}
