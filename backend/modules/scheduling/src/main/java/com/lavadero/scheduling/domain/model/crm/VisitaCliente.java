package com.lavadero.scheduling.domain.model.crm;

import com.lavadero.scheduling.domain.model.ReservaEstado;
import com.lavadero.shared.domain.Money;
import java.time.Instant;
import java.util.UUID;

/** Una reserva en el historial de la ficha del cliente. {@code placa} es opcional. */
public record VisitaCliente(
    UUID reservaId,
    Instant fecha,
    String servicio,
    String sucursal,
    ReservaEstado estado,
    Money precio,
    String placa) {}
