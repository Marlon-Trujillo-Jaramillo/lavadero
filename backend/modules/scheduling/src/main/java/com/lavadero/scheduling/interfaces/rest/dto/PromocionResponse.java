package com.lavadero.scheduling.interfaces.rest.dto;

import com.lavadero.scheduling.application.dto.PromocionDto;
import java.math.BigDecimal;
import java.time.Instant;
import java.time.LocalDate;
import java.time.LocalTime;
import java.util.List;
import java.util.UUID;

public record PromocionResponse(
    UUID id,
    String nombre,
    String tipo,
    String codigo,
    String tipoDescuento,
    BigDecimal valorDescuento,
    String moneda,
    List<String> dias,
    LocalTime horaDesde,
    LocalTime horaHasta,
    LocalDate vigenteDesde,
    LocalDate vigenteHasta,
    Integer usosMaximos,
    int usos,
    boolean activa,
    Instant creadaEn,
    long reservas,
    long completadas,
    BigDecimal ingresos,
    BigDecimal descuentoOtorgado) {

  public static PromocionResponse from(PromocionDto d) {
    return new PromocionResponse(
        d.id(),
        d.nombre(),
        d.tipo(),
        d.codigo(),
        d.tipoDescuento(),
        d.valorDescuento(),
        d.moneda(),
        d.dias(),
        d.horaDesde(),
        d.horaHasta(),
        d.vigenteDesde(),
        d.vigenteHasta(),
        d.usosMaximos(),
        d.usos(),
        d.activa(),
        d.creadaEn(),
        d.reservas(),
        d.completadas(),
        d.ingresos(),
        d.descuentoOtorgado());
  }
}
