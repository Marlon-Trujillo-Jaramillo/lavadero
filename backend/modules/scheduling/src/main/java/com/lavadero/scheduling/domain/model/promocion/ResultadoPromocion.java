package com.lavadero.scheduling.domain.model.promocion;

import com.lavadero.shared.domain.Money;

/**
 * Qué generó una promoción: reservas hechas con ella (sin contar canceladas), cuántas se
 * completaron, lo que se cobró en ellas y lo que se dejó de cobrar (descuento otorgado).
 */
public record ResultadoPromocion(
    long reservas, long completadas, Money ingresos, Money descuentoOtorgado) {}
