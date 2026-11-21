package com.lavadero.scheduling.application.command;

import com.lavadero.scheduling.domain.model.promocion.TipoDescuento;
import com.lavadero.scheduling.domain.model.promocion.TipoPromocion;
import java.math.BigDecimal;
import java.time.DayOfWeek;
import java.time.LocalDate;
import java.time.LocalTime;
import java.util.Set;

/**
 * {@code codigo} y {@code usosMaximos} son de un CUPON; {@code dias}, {@code horaDesde} y {@code
 * horaHasta}, de un precio por HORARIO. {@code moneda} solo cuenta para un MONTO_FIJO.
 */
public record CrearPromocionCommand(
    String nombre,
    TipoPromocion tipo,
    String codigo,
    TipoDescuento tipoDescuento,
    BigDecimal valorDescuento,
    String moneda,
    Set<DayOfWeek> dias,
    LocalTime horaDesde,
    LocalTime horaHasta,
    LocalDate vigenteDesde,
    LocalDate vigenteHasta,
    Integer usosMaximos) {}
