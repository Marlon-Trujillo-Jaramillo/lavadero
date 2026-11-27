package com.lavadero.scheduling.application.usecase;

import com.lavadero.shared.application.exception.ValidationException;
import java.time.LocalDate;
import java.time.temporal.ChronoUnit;

/** Validación común de rangos de reportes (desde <= hasta, máximo 366 días). */
final class RangoReporte {

  private static final long MAX_DIAS = 366;

  private RangoReporte() {}

  static void validar(LocalDate desde, LocalDate hasta) {
    if (desde.isAfter(hasta)) {
      throw new ValidationException("'desde' no puede ser posterior a 'hasta'");
    }
    if (ChronoUnit.DAYS.between(desde, hasta) > MAX_DIAS) {
      throw new ValidationException("El rango del reporte no puede superar 366 días");
    }
  }
}
