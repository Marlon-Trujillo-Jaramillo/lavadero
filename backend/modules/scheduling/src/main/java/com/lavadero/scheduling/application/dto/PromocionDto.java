package com.lavadero.scheduling.application.dto;

import java.math.BigDecimal;
import java.time.Instant;
import java.time.LocalDate;
import java.time.LocalTime;
import java.util.List;
import java.util.UUID;

/** Una promoción con sus resultados (cero si aún no tiene reservas). */
public record PromocionDto(
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
    BigDecimal descuentoOtorgado) {}
