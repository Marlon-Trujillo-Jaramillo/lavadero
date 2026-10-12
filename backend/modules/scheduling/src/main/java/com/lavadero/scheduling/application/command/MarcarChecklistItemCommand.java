package com.lavadero.scheduling.application.command;

import com.lavadero.scheduling.domain.model.ChecklistItemTipo;
import java.util.UUID;

public record MarcarChecklistItemCommand(
    UUID reservaId, ChecklistItemTipo tipo, boolean completado) {}
