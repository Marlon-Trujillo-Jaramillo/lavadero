package com.lavadero.scheduling.application.usecase;

import com.lavadero.scheduling.application.dto.ChecklistItemDto;
import com.lavadero.scheduling.domain.model.ChecklistItem;
import com.lavadero.scheduling.domain.model.ChecklistItemTipo;
import com.lavadero.scheduling.domain.repository.ChecklistItemRepository;
import java.util.Arrays;
import java.util.List;
import java.util.Map;
import java.util.UUID;
import java.util.function.Function;
import java.util.stream.Collectors;

/**
 * Construye la lista completa de los 5 tipos fijos para una reserva, combinando lo guardado
 * (algunos tipos pueden no tener fila todavía) con el default `completado=false` — no se
 * pre-siembran filas para cada tipo al crear la reserva.
 */
final class ChecklistMapper {

  private ChecklistMapper() {}

  static List<ChecklistItemDto> listaCompleta(
      UUID reservaId, ChecklistItemRepository checklistItemRepository) {
    Map<ChecklistItemTipo, ChecklistItem> guardados =
        checklistItemRepository.findByReservaId(reservaId).stream()
            .collect(Collectors.toMap(ChecklistItem::getTipo, Function.identity()));

    return Arrays.stream(ChecklistItemTipo.values())
        .map(
            tipo -> {
              ChecklistItem guardado = guardados.get(tipo);
              return new ChecklistItemDto(
                  tipo.name(),
                  tipo.getLabel(),
                  guardado != null && guardado.isCompletado(),
                  guardado != null ? guardado.getCompletadoEn() : null);
            })
        .toList();
  }
}
