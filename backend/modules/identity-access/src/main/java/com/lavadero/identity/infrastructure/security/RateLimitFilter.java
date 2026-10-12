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
import java.util.Set;
import org.springframework.web.filter.OncePerRequestFilter;

/**
 * Rate limiting en memoria (Bucket4j) para los endpoints más sensibles a fuerza bruta/abuso ({@code
 * /api/v1/auth/login}, {@code /api/v1/auth/refresh}, {@code /api/v1/auth/register} y {@code
 * /api/v1/onboarding/tenants}). En memoria es aceptable en esta fase (un solo proceso, sin Redis
 * todavía); si el backend se escala horizontalmente, este filtro debe migrar a un backend
 * distribuido (Bucket4j soporta Redis vía `bucket4j-redis`, ya presente en
 * `infra/docker-compose.yml` para cuando llegue esa fase).
 *
 * <p>Límite: 5 intentos/minuto por IP y por ruta protegida. Excedido el límite, responde 429 sin
 * llegar a ejecutar el controlador.
 *
 * <p>Los buckets se guardan en una cache con eviction por inactividad ({@code expireAfterAccess}),
 * no en un mapa simple: una IP que deja de pegarle al endpoint no debe ocupar memoria para siempre.
 * El TTL (10 min) es varias veces la ventana del límite (1 min), así que una entrada solo se libera
 * cuando ya hace rato que el bucket estaría completamente recargado de todos modos — no cambia el
 * comportamiento del rate limiting para un cliente activo.
 */
public class RateLimitFilter extends OncePerRequestFilter {

  private static final Set<String> RUTAS_LIMITADAS =
      Set.of(
          "/api/v1/auth/login",
          "/api/v1/auth/refresh",
          "/api/v1/auth/register",
          "/api/v1/onboarding/tenants");
  private static final int CAPACIDAD = 5;
  private static final Duration VENTANA = Duration.ofMinutes(1);
  private static final Duration TTL_INACTIVIDAD = Duration.ofMinutes(10);

  private final Cache<String, Bucket> buckets =
      Caffeine.newBuilder().expireAfterAccess(TTL_INACTIVIDAD).build();

  @Override
  protected void doFilterInternal(
      HttpServletRequest request, HttpServletResponse response, FilterChain filterChain)
      throws ServletException, IOException {

    String path = request.getRequestURI();
    if (!RUTAS_LIMITADAS.contains(path)) {
      filterChain.doFilter(request, response);
      return;
    }

    String clave = path + ":" + resolverIp(request);
    Bucket bucket = buckets.get(clave, k -> nuevoBucket());

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

  private Bucket nuevoBucket() {
    @SuppressWarnings("deprecation")
    Bandwidth limite = Bandwidth.simple(CAPACIDAD, VENTANA);
    return Bucket.builder().addLimit(limite).build();
  }

  private String resolverIp(HttpServletRequest request) {
    String forwarded = request.getHeader("X-Forwarded-For");
    if (forwarded != null && !forwarded.isBlank()) {
      return forwarded.split(",")[0].trim();
    }
    return request.getRemoteAddr();
  }
}
