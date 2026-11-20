package com.lavadero.scheduling.domain.model.crm;

import com.lavadero.shared.domain.Money;
import java.time.Instant;
import java.util.UUID;

/**
 * Una fila del CRM: lo que el lavadero sabe de un cliente, calculado a partir de sus reservas. Es
 * un modelo de lectura (sin identidad propia ni ciclo de vida), igual que {@code ResumenVentas}.
 * Las fechas de visita son {@code null} si nunca completó un servicio; {@code proximaReserva} es
 * {@code null} si no tiene una pendiente.
 */
public record ClienteResumen(
    UUID id,
    String nombre,
    String email,
    int visitas,
    Money gastoTotal,
    Instant primeraVisita,
    Instant ultimaVisita,
    Instant proximaReserva,
    int vehiculosActivos,
    SegmentoCliente segmento) {}
