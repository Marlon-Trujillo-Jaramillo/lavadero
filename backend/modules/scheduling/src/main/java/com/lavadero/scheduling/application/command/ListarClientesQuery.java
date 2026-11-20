package com.lavadero.scheduling.application.command;

import com.lavadero.scheduling.domain.model.crm.OrdenClientes;
import com.lavadero.scheduling.domain.model.crm.SegmentoCliente;
import com.lavadero.shared.security.AlcanceSucursal;
import java.util.UUID;

/**
 * Lista del CRM. {@code segmento}, {@code busqueda} y {@code sucursalId} son opcionales; con {@code
 * alcance} restringido (ADMIN_SUCURSAL) se fuerza la sucursal propia.
 */
public record ListarClientesQuery(
    SegmentoCliente segmento,
    String busqueda,
    OrdenClientes orden,
    UUID sucursalId,
    int pagina,
    int tamano,
    AlcanceSucursal alcance) {}
