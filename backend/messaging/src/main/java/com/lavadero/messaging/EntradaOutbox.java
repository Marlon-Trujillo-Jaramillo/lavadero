package com.lavadero.messaging;

import java.util.UUID;

/** Un evento pendiente de publicar, tal como está en el outbox. */
public record EntradaOutbox(
    UUID id,
    UUID tenantId,
    String tipo,
    String topico,
    String clave,
    String payload,
    int intentos) {}
