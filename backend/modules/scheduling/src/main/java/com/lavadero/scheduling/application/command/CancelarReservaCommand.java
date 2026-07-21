package com.lavadero.scheduling.application.command;

import java.util.UUID;

/**
 * {@code solicitanteId}/{@code solicitanteEsStaff} vienen de {@code JwtAuthenticatedPrincipal} en
 * el controller: solo el cliente dueño de la reserva o personal del lavadero pueden cancelarla (ver
 * {@code CancelarReservaUseCase}).
 */
public record CancelarReservaCommand(
    UUID reservaId, UUID solicitanteId, boolean solicitanteEsStaff) {}
