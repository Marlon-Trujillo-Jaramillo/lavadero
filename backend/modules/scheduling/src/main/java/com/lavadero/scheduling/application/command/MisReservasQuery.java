package com.lavadero.scheduling.application.command;

import java.time.Instant;
import java.util.UUID;

/**
 * {@code clienteId} viene del JWT. {@code desde} es opcional (solo reservas que inician en o
 * después); {@code limite} ya viene acotado por el controller.
 */
public record MisReservasQuery(UUID clienteId, Instant desde, int limite) {}
