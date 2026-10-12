package com.lavadero.scheduling.interfaces.rest;

import com.lavadero.scheduling.application.command.MarcarChecklistItemCommand;
import com.lavadero.scheduling.application.usecase.MarcarChecklistItemUseCase;
import com.lavadero.scheduling.application.usecase.ObtenerChecklistUseCase;
import com.lavadero.scheduling.domain.model.ChecklistItemTipo;
import com.lavadero.scheduling.interfaces.rest.dto.ChecklistItemResponse;
import com.lavadero.scheduling.interfaces.rest.dto.MarcarChecklistItemRequest;
import java.util.List;
import java.util.UUID;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PatchMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RestController;

/** Checklist de servicio de una reserva — ver docs/specs/006-checklist-incidencias.md. */
@RestController
public class ChecklistController {

  private final ObtenerChecklistUseCase obtenerChecklistUseCase;
  private final MarcarChecklistItemUseCase marcarChecklistItemUseCase;

  public ChecklistController(
      ObtenerChecklistUseCase obtenerChecklistUseCase,
      MarcarChecklistItemUseCase marcarChecklistItemUseCase) {
    this.obtenerChecklistUseCase = obtenerChecklistUseCase;
    this.marcarChecklistItemUseCase = marcarChecklistItemUseCase;
  }

  @GetMapping("/api/v1/agenda/reservas/{id}/checklist")
  @PreAuthorize("hasAnyRole('EMPLEADO','ADMIN_SUCURSAL','ADMIN_TENANT')")
  public List<ChecklistItemResponse> obtener(@PathVariable UUID id) {
    return obtenerChecklistUseCase.execute(id).stream().map(ChecklistItemResponse::from).toList();
  }

  @PatchMapping("/api/v1/agenda/reservas/{id}/checklist/{tipo}")
  @PreAuthorize("hasAnyRole('EMPLEADO','ADMIN_SUCURSAL','ADMIN_TENANT')")
  public List<ChecklistItemResponse> marcar(
      @PathVariable UUID id,
      @PathVariable ChecklistItemTipo tipo,
      @RequestBody MarcarChecklistItemRequest request) {
    return marcarChecklistItemUseCase
        .execute(new MarcarChecklistItemCommand(id, tipo, request.completado()))
        .stream()
        .map(ChecklistItemResponse::from)
        .toList();
  }
}
