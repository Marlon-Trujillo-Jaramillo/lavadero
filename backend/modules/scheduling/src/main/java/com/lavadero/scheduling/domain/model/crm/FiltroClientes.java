package com.lavadero.scheduling.domain.model.crm;

import java.time.Instant;
import java.util.UUID;

/**
 * Criterios de la lista del CRM. {@code segmento}, {@code busqueda} y {@code sucursalId} son
 * opcionales ({@code null} = sin filtro). Con {@code sucursalId} solo cuentan las reservas de esa
 * sucursal y solo aparecen clientes que han reservado en ella. {@code ahora} se pasa explícito para
 * que la segmentación sea reproducible en los tests.
 */
public record FiltroClientes(
    SegmentoCliente segmento,
    String busqueda,
    OrdenClientes orden,
    UUID sucursalId,
    int pagina,
    int tamano,
    Instant ahora) {}
