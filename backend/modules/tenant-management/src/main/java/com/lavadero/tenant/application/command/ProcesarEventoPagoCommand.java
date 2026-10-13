package com.lavadero.tenant.application.command;

/**
 * Cuerpo crudo del webhook, byte a byte como llegó: la verificación de la firma se hace sobre él,
 * así que no puede pasar antes por un mapeo a DTO.
 */
public record ProcesarEventoPagoCommand(String payloadCrudo) {}
