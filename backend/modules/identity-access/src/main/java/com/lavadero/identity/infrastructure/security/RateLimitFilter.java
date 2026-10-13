package com.lavadero.identity.infrastructure.security;

import com.github.benmanes.caffeine.cache.Cache;
import com.github.benmanes.caffeine.cache.Caffeine;
import io.github.bucket4j.Bandwidth;
import io.github.bucket4j.Bucket;
import jakarta.servlet.FilterChain;
import jakarta.servlet.ServletException;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import java.io.IOException;
import java.time.Duration;
import java.util.Map;
import org.springframework.web.filter.OncePerRequestFilter;

/**
 * Rate limiting en memoria (Bucket4j) para los endpoints más sensibles a fuerza bruta/abuso ({@code
 * /api/v1/auth/login}, {@code /api/v1/auth/refresh}, {@code /api/v1/auth/register} y {@code
 * /api/v1/onboarding/tenants}). En memoria es aceptable en esta fase (un solo proceso, sin Redis
 * todavía); si el backend se escala horizontalmente, este filtro debe migrar a un backend
 * distribuido (Bucket4j soporta Redis vía `bucket4j-redis`, ya presente en
 * `infra/docker-compose.yml` para cuando llegue esa fase).
 *
 * <p>Límite por IP y por ruta, configurable por ruta ({@link #LIMITES}): 5/minuto para auth y
 * onboarding; 120/minuto para el webhook público de Wompi (la pasarela puede mandar ráfagas
 * legítimas, pero sin tope cualquiera podría forzar a verificar firmas sin fin). Excedido el
 * límite, responde 429 sin llegar a ejecutar el controlador.
 *
 * <p>Los buckets se guardan en una cache con eviction por inactividad ({@code expireAfterAccess}),
 * no en un mapa simple: una IP que deja de pegarle al endpoint no debe ocupar memoria para siempre.
 * El TTL (10 min) es varias veces la ventana del límite (1 min), así que una entrada solo se libera
 * cuando ya hace rato que el bucket estaría completamente recargado de todos modos — no cambia el
 * comportamiento del rate limiting para un cliente activo.
 */
public class RateLimitFilter extends OncePerRequestFilter {

  /** Capacidad de un bucket por IP+ruta, que se recarga entera cada {@code ventana}. */
  record Limite(int capacidad, Duration ventana) {}

  private static final Limite ESTRICTO = new Limite(5, Duration.ofMinutes(1));

  static final Map<String, Limite> LIMITES =
      Map.of(
          "/api/v1/auth/login", ESTRICTO,
          "/api/v1/auth/refresh", ESTRICTO,
          "/api/v1/auth/register", ESTRICTO,
          "/api/v1/onboarding/tenants", ESTRICTO,
          "/api/v1/pagos/webhook/wompi", new Limite(120, Duration.ofMinutes(1)));

  private static final Duration TTL_INACTIVIDAD = Duration.ofMinutes(10);

  private final Cache<String, Bucket> buckets =
      Caffeine.newBuilder().expireAfterAccess(TTL_INACTIVIDAD).build();

  @Override
  protected void doFilterInternal(
      HttpServletRequest request, HttpServletResponse response, FilterChain filterChain)
      throws ServletException, IOException {

    String path = request.getRequestURI();
    Limite limite = LIMITES.get(path);
    if (limite == null) {
      filterChain.doFilter(request, response);
      return;
    }

    // getRemoteAddr y no X-Forwarded-For: ese header lo controla el cliente, y rotarlo daba
    // un bucket nuevo por request. Detrás de un proxy, `server.forward-headers-strategy: native`
    // (application.yml) hace que Tomcat lo resuelva solo si viene de un proxy interno.
    String clave = path + ":" + request.getRemoteAddr();
    Bucket bucket = buckets.get(clave, k -> nuevoBucket(limite));

    if (bucket.tryConsume(1)) {
      filterChain.doFilter(request, response);
    } else {
      response.setStatus(429);
      response.setContentType("application/json");
      response
          .getWriter()
          .write(
              "{\"error\":\"too_many_requests\",\"message\":\"Demasiados intentos, intenta más tarde\"}");
    }
  }

  private static Bucket nuevoBucket(Limite limite) {
    @SuppressWarnings("deprecation")
    Bandwidth ancho = Bandwidth.simple(limite.capacidad(), limite.ventana());
    return Bucket.builder().addLimit(ancho).build();
  }
}
