package com.lavadero.scheduling.interfaces.rest.dto;

import com.lavadero.scheduling.application.dto.ResumenFinancieroDto;
import java.math.BigDecimal;

public record ResumenFinancieroResponse(
    BigDecimal ingresos, BigDecimal gastos, BigDecimal utilidad, String moneda) {

  public static ResumenFinancieroResponse from(ResumenFinancieroDto d) {
    return new ResumenFinancieroResponse(d.ingresos(), d.gastos(), d.utilidad(), d.moneda());
  }
}
