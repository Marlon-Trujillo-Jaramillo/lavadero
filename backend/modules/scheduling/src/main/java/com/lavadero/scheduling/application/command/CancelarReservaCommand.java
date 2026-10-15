package com.lavadero.scheduling.application.command;

import com.lavadero.shared.security.AlcanceSucursal;
import java.util.UUID;

/**
 * {@code solicitanteId}/{@code solicitanteEsStaff} vienen de {@code PrincipalAutenticado} en el
 * controller: solo el cliente dueño de la reserva o personal del lavadero pueden cancelarla (ver
 * {@code CancelarReservaUseCase}). Un ADMIN_SUCURSAL, además, solo en su sucursal ({@code
 * alcance}).
 */
public record CancelarReservaCommand(
    UUID reservaId, UUID solicitanteId, boolean solicitanteEsStaff, AlcanceSucursal alcance) {}
