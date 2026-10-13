package com.lavadero.scheduling.application.command;

import com.lavadero.scheduling.domain.model.ChecklistItemTipo;
import com.lavadero.shared.security.AlcanceSucursal;
import java.util.UUID;

public record MarcarChecklistItemCommand(
    UUID reservaId, ChecklistItemTipo tipo, boolean completado, AlcanceSucursal alcance) {}
