package com.lavadero.scheduling.application.command;

import java.time.Instant;
import java.util.UUID;

/** {@code codigoCupon} es opcional. */
public record CotizarReservaQuery(UUID servicioId, Instant fechaHoraInicio, String codigoCupon) {}
