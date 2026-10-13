package com.lavadero.scheduling.interfaces.rest;

import com.lavadero.shared.application.exception.ValidationException;
import java.time.Duration;
import java.time.Instant;
import java.time.LocalDate;
import java.time.ZoneOffset;

/**
 * Convierte los {@code LocalDate} de query params (ISO, interpretados en UTC) a límites de día. Un
 * año absurdo ({@code +999999999-12-31}) se rechaza con 400 aquí: si no, revienta al convertirlo o
 * al pasarlo a Postgres (500).
 */
final class FechasConsulta {

  private static final int ANIO_MINIMO = 2000;
  private static final int ANIO_MAXIMO = 2100;

  private FechasConsulta() {}

  static Instant inicioDelDia(LocalDate fecha, String parametro) {
    if (fecha.getYear() < ANIO_MINIMO || fecha.getYear() > ANIO_MAXIMO) {
      throw new ValidationException(
          "'%s' debe estar entre %d y %d".formatted(parametro, ANIO_MINIMO, ANIO_MAXIMO));
    }
    return fecha.atStartOfDay(ZoneOffset.UTC).toInstant();
  }

  /** Inicio del día siguiente: límite exclusivo para incluir {@code fecha} completa. */
  static Instant finDelDia(LocalDate fecha, String parametro) {
    return inicioDelDia(fecha, parametro).plus(Duration.ofDays(1));
  }
}
