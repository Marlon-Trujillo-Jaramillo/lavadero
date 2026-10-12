package com.lavadero.tenant.infrastructure.payment;

import org.springframework.boot.context.properties.ConfigurationProperties;

/**
 * Credenciales de Wompi. Ver {@code application.yml}: todas vacías por defecto (sin cuenta de
 * Wompi creada todavía, mismo patrón que {@code SENTRY_DSN}) — con esto vacío, {@link
 * WompiPaymentGateway} rechaza limpiamente cualquier intento de checkout en vez de fallar el
 * arranque o, peor, fingir éxito.
 */
@ConfigurationProperties(prefix = "lavadero.payments.wompi")
public class WompiProperties {

  private String publicKey = "";
  private String privateKey = "";
  private String eventsSecret = "";
  private String baseUrl = "https://production.wompi.co/v1";

  /** A dónde vuelve el usuario tras pagar (URL de `admin_web`). */
  private String redirectUrl = "";

  public boolean isConfigured() {
    return !privateKey.isBlank() && !eventsSecret.isBlank();
  }

  public String getPublicKey() {
    return publicKey;
  }

  public void setPublicKey(String publicKey) {
    this.publicKey = publicKey;
  }

  public String getPrivateKey() {
    return privateKey;
  }

  public void setPrivateKey(String privateKey) {
    this.privateKey = privateKey;
  }

  public String getEventsSecret() {
    return eventsSecret;
  }

  public void setEventsSecret(String eventsSecret) {
    this.eventsSecret = eventsSecret;
  }

  public String getBaseUrl() {
    return baseUrl;
  }

  public void setBaseUrl(String baseUrl) {
    this.baseUrl = baseUrl;
  }

  public String getRedirectUrl() {
    return redirectUrl;
  }

  public void setRedirectUrl(String redirectUrl) {
    this.redirectUrl = redirectUrl;
  }
}
