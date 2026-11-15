package com.lavadero.bootstrap.web;

import jakarta.servlet.FilterChain;
import jakarta.servlet.ServletException;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import java.io.IOException;
import java.util.concurrent.TimeUnit;
import java.util.function.LongSupplier;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.core.Ordered;
import org.springframework.core.annotation.Order;
import org.springframework.stereotype.Component;
import org.springframework.web.filter.OncePerRequestFilter;

/**
 * Deja un WARN por cada petición que supere el umbral ({@code
 * lavadero.observability.slow-request-ms}, 500 ms por defecto) con método, ruta, estado y duración.
 * Es el "rastrea las peticiones lentas" gratuito: el detalle por endpoint ya lo da Actuator ({@code
 * http.server.requests}), y esto avisa en el log del caso puntual sin montar OpenTelemetry. Se
 * registra la ruta sin query string para no dejar datos personales en el log.
 */
@Component
@Order(Ordered.HIGHEST_PRECEDENCE)
public class PeticionesLentasFilter extends OncePerRequestFilter {

  private static final Logger LOG = LoggerFactory.getLogger(PeticionesLentasFilter.class);

  private final long umbralMs;
  private final LongSupplier relojNanos;

  @Autowired
  public PeticionesLentasFilter(
      @Value("${lavadero.observability.slow-request-ms:500}") long umbralMs) {
    this(umbralMs, System::nanoTime);
  }

  PeticionesLentasFilter(long umbralMs, LongSupplier relojNanos) {
    this.umbralMs = umbralMs;
    this.relojNanos = relojNanos;
  }

  @Override
  protected void doFilterInternal(
      HttpServletRequest request, HttpServletResponse response, FilterChain chain)
      throws ServletException, IOException {
    long inicio = relojNanos.getAsLong();
    try {
      chain.doFilter(request, response);
    } finally {
      long duracionMs = TimeUnit.NANOSECONDS.toMillis(relojNanos.getAsLong() - inicio);
      if (duracionMs >= umbralMs) {
        LOG.warn(
            "Petición lenta: {} {} -> {} en {} ms (umbral {} ms)",
            request.getMethod(),
            request.getRequestURI(),
            response.getStatus(),
            duracionMs,
            umbralMs);
      }
    }
  }
}
