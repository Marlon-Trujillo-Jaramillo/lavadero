package com.lavadero.tenant.infrastructure.payment;

import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.lavadero.shared.application.exception.ValidationException;
import com.lavadero.tenant.application.port.PaymentGateway;
import com.lavadero.tenant.domain.model.Pago;
import java.math.BigDecimal;
import java.nio.charset.StandardCharsets;
import java.security.MessageDigest;
import java.security.NoSuchAlgorithmException;
import java.util.LinkedHashMap;
import java.util.Locale;
import java.util.Map;
import java.util.Optional;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.boot.context.properties.EnableConfigurationProperties;
import org.springframework.core.ParameterizedTypeReference;
import org.springframework.http.MediaType;
import org.springframework.stereotype.Component;
import org.springframework.web.client.RestClient;
import org.springframework.web.client.RestClientException;

/**
 * Adaptador de {@link PaymentGateway} contra la API de Wompi (pasarela colombiana: PSE, tarjetas,
 * Nequi — ver decisión en spec de auditoría técnica/negocio 2026-08-18).
 *
 * <p>IMPORTANTE — sin cuenta Wompi real disponible al escribir esto: la forma de la petición de
 * "Payment Links" (endpoint, campos {@code amount_in_cents}/{@code single_use}/{@code reference})
 * y el mecanismo de verificación del webhook (checksum embebido en {@code signature.checksum},
 * calculado como SHA-256 de la concatenación de los valores de {@code signature.properties} +
 * {@code timestamp} + {@code eventsSecret} — NO un HMAC del payload crudo, ni un header de firma:
 * Wompi no envía firma por header) están implementados según la documentación pública conocida de
 * Wompi al momento de escribir esto, pero NUNCA se probaron contra un webhook real. Antes de
 * aceptar pagos reales: (1) confirmar contra la documentación vigente en https://docs.wompi.co que
 * el checksum se calcula así, y (2) probar un pago real en el ambiente sandbox de Wompi de punta a
 * punta.
 */
@Component
@EnableConfigurationProperties(WompiProperties.class)
public class WompiPaymentGateway implements PaymentGateway {

  private static final Logger log = LoggerFactory.getLogger(WompiPaymentGateway.class);

  private final WompiProperties properties;
  private final RestClient restClient;
  private final ObjectMapper objectMapper;

  public WompiPaymentGateway(WompiProperties properties, ObjectMapper objectMapper) {
    this.properties = properties;
    this.restClient = RestClient.create();
    this.objectMapper = objectMapper;
  }

  @Override
  public CheckoutLink crearLinkDePago(Pago pago, String nombrePlan) {
    if (!properties.isConfigured()) {
      throw new ValidationException(
          "Los pagos todavía no están configurados en este ambiente (falta la cuenta de Wompi)");
    }

    Map<String, Object> body = new LinkedHashMap<>();
    body.put("name", nombrePlan);
    body.put("description", "Suscripción Lavadero - " + nombrePlan);
    body.put("single_use", true);
    body.put("collect_shipping", false);
    body.put("currency", pago.getMonto().moneda().getCurrencyCode());
    body.put(
        "amount_in_cents",
        pago.getMonto().monto().multiply(BigDecimal.valueOf(100)).longValueExact());
    body.put("reference", pago.getReferencia());
    if (!properties.getRedirectUrl().isBlank()) {
      body.put("redirect_url", properties.getRedirectUrl());
    }

    try {
      Map<String, Object> response =
          restClient
              .post()
              .uri(properties.getBaseUrl() + "/payment_links")
              .header("Authorization", "Bearer " + properties.getPrivateKey())
              .contentType(MediaType.APPLICATION_JSON)
              .body(body)
              .retrieve()
              .body(new ParameterizedTypeReference<Map<String, Object>>() {});
      @SuppressWarnings("unchecked")
      Map<String, Object> data = (Map<String, Object>) response.get("data");
      String linkId = String.valueOf(data.get("id"));
      return new CheckoutLink("https://checkout.wompi.co/l/" + linkId);
    } catch (RestClientException e) {
      log.error("Error creando link de pago en Wompi (referencia={})", pago.getReferencia(), e);
      throw new ValidationException("No se pudo generar el link de pago, intenta más tarde");
    }
  }

  @Override
  public boolean firmaValida(String payloadCrudo) {
    if (!properties.isConfigured()) {
      return false;
    }
    try {
      JsonNode raiz = objectMapper.readTree(payloadCrudo);
      JsonNode firma = raiz.path("signature");
      String checksumRecibido = firma.path("checksum").asText(null);
      String timestamp = raiz.path("timestamp").asText(null);
      if (checksumRecibido == null || checksumRecibido.isBlank() || timestamp == null) {
        return false;
      }

      JsonNode data = raiz.path("data");
      StringBuilder concatenado = new StringBuilder();
      for (JsonNode propiedad : firma.path("properties")) {
        concatenado.append(valorEnRuta(data, propiedad.asText()));
      }
      concatenado.append(timestamp).append(properties.getEventsSecret());

      String calculado = sha256Hex(concatenado.toString());
      return MessageDigest.isEqual(
          calculado.getBytes(StandardCharsets.UTF_8),
          checksumRecibido.toLowerCase(Locale.ROOT).getBytes(StandardCharsets.UTF_8));
    } catch (Exception e) {
      log.warn("No se pudo verificar la firma del webhook de Wompi", e);
      return false;
    }
  }

  /** Navega un {@link JsonNode} por una ruta tipo {@code "transaction.id"}. */
  private static String valorEnRuta(JsonNode raiz, String rutaConPuntos) {
    JsonNode actual = raiz;
    for (String segmento : rutaConPuntos.split("\\.")) {
      actual = actual.path(segmento);
    }
    return actual.asText("");
  }

  @Override
  public Optional<ResultadoTransaccion> parsearEventoTransaccion(String payloadCrudo) {
    try {
      JsonNode transaccion = objectMapper.readTree(payloadCrudo).path("data").path("transaction");
      if (transaccion.isMissingNode()) {
        return Optional.empty();
      }
      String referencia = transaccion.path("reference").asText(null);
      String idExterno = transaccion.path("id").asText(null);
      String estado = transaccion.path("status").asText("");
      if (referencia == null || idExterno == null) {
        return Optional.empty();
      }
      return Optional.of(
          new ResultadoTransaccion(referencia, idExterno, "APPROVED".equalsIgnoreCase(estado)));
    } catch (Exception e) {
      log.warn("No se pudo parsear el payload del webhook de Wompi", e);
      return Optional.empty();
    }
  }

  private static String sha256Hex(String data) {
    try {
      MessageDigest digest = MessageDigest.getInstance("SHA-256");
      byte[] hash = digest.digest(data.getBytes(StandardCharsets.UTF_8));
      StringBuilder hex = new StringBuilder(hash.length * 2);
      for (byte b : hash) {
        hex.append(String.format("%02x", b));
      }
      return hex.toString();
    } catch (NoSuchAlgorithmException e) {
      throw new IllegalStateException("No se pudo calcular SHA-256", e);
    }
  }
}
