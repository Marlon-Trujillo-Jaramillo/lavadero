package com.lavadero.catalog.application.command;

import java.util.UUID;

public record CambiarEstadoServicioCommand(UUID servicioId, boolean activo) {}
