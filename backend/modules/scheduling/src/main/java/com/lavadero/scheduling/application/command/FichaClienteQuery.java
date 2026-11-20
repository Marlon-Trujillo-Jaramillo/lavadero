package com.lavadero.scheduling.application.command;

import com.lavadero.shared.security.AlcanceSucursal;
import java.util.UUID;

public record FichaClienteQuery(UUID clienteId, UUID sucursalId, AlcanceSucursal alcance) {}
