package com.lavadero.scheduling.domain.model.crm;

import java.util.List;
import java.util.Map;

/**
 * Una página de clientes, el total que cumple el filtro y cuántos hay en cada segmento. El conteo
 * por segmento respeta la búsqueda y la sucursal, pero no el filtro de segmento: así los chips de
 * la pantalla muestran cuántos hay en cada uno mientras se mira otro.
 */
public record PaginaClientes(
    List<ClienteResumen> clientes, long total, Map<SegmentoCliente, Long> porSegmento) {}
