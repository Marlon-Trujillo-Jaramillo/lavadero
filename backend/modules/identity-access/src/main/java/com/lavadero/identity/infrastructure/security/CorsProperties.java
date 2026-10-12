package com.lavadero.identity.infrastructure.security;

import java.util.List;
import org.springframework.boot.context.properties.ConfigurationProperties;

/**
 * Orígenes permitidos para peticiones cross-origin (CORS) — necesarios porque {@code admin_web} es
 * una SPA de navegador que corre en un origen distinto al del backend.
 *
 * <p>Ver {@code application.yml}/{@code application-dev.yml} para los valores por entorno: en
 * producción deben venir de {@code LAVADERO_CORS_ALLOWED_ORIGINS} (orígenes exactos, p. ej. {@code
 * https://admin.lavadero.com}); en dev se usan {@code allowed-origin-patterns} con comodín porque
 * {@code flutter run -d chrome} asigna un puerto local variable en cada corrida.
 */
@ConfigurationProperties(prefix = "lavadero.security.cors")
public class CorsProperties {

  private List<String> allowedOrigins = List.of();

  private List<String> allowedOriginPatterns = List.of();

  public List<String> getAllowedOrigins() {
    return allowedOrigins;
  }

  public void setAllowedOrigins(List<String> allowedOrigins) {
    this.allowedOrigins = allowedOrigins;
  }

  public List<String> getAllowedOriginPatterns() {
    return allowedOriginPatterns;
  }

  public void setAllowedOriginPatterns(List<String> allowedOriginPatterns) {
    this.allowedOriginPatterns = allowedOriginPatterns;
  }
}
