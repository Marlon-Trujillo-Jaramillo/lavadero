package com.lavadero.inventory.application.command;

import com.lavadero.inventory.domain.model.LineaReceta;
import java.util.List;
import java.util.UUID;

public record DefinirRecetaCommand(UUID servicioId, List<LineaReceta> lineas) {}
