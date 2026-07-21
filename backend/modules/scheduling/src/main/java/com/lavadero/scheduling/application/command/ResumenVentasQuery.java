package com.lavadero.scheduling.application.command;

import java.time.Instant;

public record ResumenVentasQuery(Instant desde, Instant hasta) {}
