package com.lavadero.tenant.infrastructure.payment;

import org.springframework.boot.context.properties.ConfigurationProperties;

/**
 * Credenciales de Wompi. Ver {@code application.yml}: todas vacías por defecto (sin cuenta de Wompi
 * creada todavía, mismo patrón que {@code SENTRY_DSN}) — con esto vacío, {@link
 * WompiPaymentGateway} rechaza limpiamente cualquier intento de checkout y todo webhook (falla
 * cerrado) en vez de fallar el arranque o, peor, fingir éxito.
 *
 * <p>Son tres secretos distintos en el dashboard de Wompi: la llave pública (va al cliente), el
 * secreto de integridad (firma el checkout, nunca sale del backend) y el secreto de eventos (firma
 * los webhooks).
 */
@ConfigurationProperties(prefix = "lavadero.payments.wompi")
public class WompiProperties {

  private String publicKey = "";
  private String integritySecret = "";
  private String eventsSecret = "";
  private String checkoutUrl = "https://checkout.wompi.co/p/";

  /** A dónde vuelve el usuario tras pagar (URL de `admin_web`). Informativo: manda el webhook. */
  private String redirectUrl = "";

  public boolean isCheckoutConfigurado() {
    return !publicKey.isBlank() && !integritySecret.isBlank();
  }

  public boolean isEventosConfigurados() {
    return !eventsSecret.isBlank();
  }

  public String getPublicKey() {
    return publicKey;
  }

  public void setPublicKey(String publicKey) {
    this.publicKey = publicKey;
  }

  public String getIntegritySecret() {
    return integritySecret;
  }

  public void setIntegritySecret(String integritySecret) {
    this.integritySecret = integritySecret;
  }

  public String getEventsSecret() {
    return eventsSecret;
  }

  public void setEventsSecret(String eventsSecret) {
    this.eventsSecret = eventsSecret;
  }

  public String getCheckoutUrl() {
    return checkoutUrl;
  }

  public void setCheckoutUrl(String checkoutUrl) {
    this.checkoutUrl = checkoutUrl;
  }

  public String getRedirectUrl() {
    return redirectUrl;
  }

  public void setRedirectUrl(String redirectUrl) {
    this.redirectUrl = redirectUrl;
  }
}
