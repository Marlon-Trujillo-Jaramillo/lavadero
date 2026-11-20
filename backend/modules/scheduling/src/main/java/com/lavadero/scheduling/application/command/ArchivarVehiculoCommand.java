package com.lavadero.scheduling.application.command;

import java.util.UUID;

public record ArchivarVehiculoCommand(UUID clienteId, UUID vehiculoId) {}
