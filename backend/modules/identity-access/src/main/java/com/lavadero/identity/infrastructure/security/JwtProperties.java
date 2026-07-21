package com.lavadero.identity.infrastructure.security;

import java.time.Duration;
import org.springframework.boot.context.properties.ConfigurationProperties;

/**
 * Propiedades de firma/emisión de JWT. Ver {@code application.yml} (bootstrap) para el valor real
 * de {@code secret} en cada entorno: en producción debe venir de un secret manager, nunca
 * hardcodeado ni versionado.
 */
@ConfigurationProperties(prefix = "lavadero.security.jwt")
public class JwtProperties {

  /** Clave secreta HS256, codificada en Base64, mínimo 256 bits. */
  private String secret;

  private Duration accessTokenTtl = Duration.ofMinutes(15);

  private String issuer = "lavadero";

  public String getSecret() {
    return secret;
  }

  public void setSecret(String secret) {
    this.secret = secret;
  }

  public Duration getAccessTokenTtl() {
    return accessTokenTtl;
  }

  public void setAccessTokenTtl(Duration accessTokenTtl) {
    this.accessTokenTtl = accessTokenTtl;
  }

  public String getIssuer() {
    return issuer;
  }

  public void setIssuer(String issuer) {
    this.issuer = issuer;
  }
}
