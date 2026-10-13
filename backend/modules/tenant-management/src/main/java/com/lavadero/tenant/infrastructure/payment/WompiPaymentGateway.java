package com.lavadero.tenant.infrastructure.payment;

import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.lavadero.shared.application.exception.ValidationException;
import com.lavadero.tenant.application.port.PaymentGateway;
import com.lavadero.tenant.domain.model.Pago;
import java.nio.charset.StandardCharsets;
import java.security.MessageDigest;
import java.security.NoSuchAlgorithmException;
import java.time.Instant;
import java.util.ArrayList;
import java.util.HashSet;
import java.util.HexFormat;
import java.util.List;
import java.util.Locale;
import java.util.Optional;
import java.util.Set;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.boot.context.properties.EnableConfigurationProperties;
import org.springframework.stereotype.Component;

/**
 * Adaptador de {@link PaymentGateway} contra Wompi (pasarela colombiana: PSE, tarjetas, Nequi — ver
 * decisión en spec de auditoría técnica/negocio 2026-08-18).
 *
 * <p>Usa el Web Checkout de Wompi (redirección a {@code checkout.wompi.co/p/} con los datos
 * firmados), no la API de Payment Links: así el backend no hace ninguna llamada saliente a Wompi
 * (ni llave privada que custodiar) y el monto queda protegido por la firma de integridad — el
 * cliente no puede cambiarlo sin invalidarla.
 *
 * <p>Verificado contra https://docs.wompi.co (2026-10):
 *
 * <ul>
 *   <li>Firma de integridad: SHA-256 hex de {@code referencia + montoEnCentavos + moneda +
 *       secretoIntegridad}.
 *   <li>Webhook: checksum = SHA-256 de los valores de {@code signature.properties} (rutas dentro de
 *       {@code data}, en orden) + {@code timestamp} (segundos UNIX) + secreto de eventos.
 * </ul>
 *
 * Antes de aceptar pagos reales, probar un pago de punta a punta en el sandbox de Wompi.
 */
@Component
@EnableConfigurationProperties(WompiProperties.class)
public class WompiPaymentGateway implements PaymentGateway {

  private static final Logger log = LoggerFactory.getLogger(WompiPaymentGateway.class);

  /**
   * Campos que DEBEN estar cubiertos por el checksum: son los que deciden qué hace el webhook (qué
   * transacción, si se aprobó y por cuánto). Wompi documenta que la lista puede crecer, así que se
   * toleran propiedades adicionales — pero si falta alguna de estas, un evento auténtico reenviado
   * con ese campo alterado pasaría la verificación.
   */
  static final Set<String> PROPIEDADES_FIRMADAS_REQUERIDAS =
      Set.of("transaction.id", "transaction.status", "transaction.amount_in_cents");

  private static final Set<String> ESTADOS_RECHAZADOS = Set.of("DECLINED", "VOIDED", "ERROR");

  private final WompiProperties properties;
  private final ObjectMapper objectMapper;

  public WompiPaymentGateway(WompiProperties properties, ObjectMapper objectMapper) {
    this.properties = properties;
    this.objectMapper = objectMapper;
  }

  @Override
  public DatosCheckout prepararCheckout(Pago pago) {
    if (!properties.isCheckoutConfigurado()) {
      throw new ValidationException(
          "Los pagos todavía no están configurados en este ambiente (falta la cuenta de Wompi)");
    }
    long montoEnCentavos = pago.montoEnCentavos();
    String moneda = pago.getMonto().moneda().getCurrencyCode();
    String firma =
        sha256Hex(
            pago.getReferencia() + montoEnCentavos + moneda + properties.getIntegritySecret());
    return new DatosCheckout(
        properties.getCheckoutUrl(),
        properties.getPublicKey(),
        pago.getReferencia(),
        montoEnCentavos,
        moneda,
        firma,
        properties.getRedirectUrl().isBlank() ? null : properties.getRedirectUrl());
  }

  @Override
  public boolean firmaValida(String payloadCrudo) {
    if (!properties.isEventosConfigurados()) {
      return false;
    }
    try {
      JsonNode raiz = objectMapper.readTree(payloadCrudo);
      JsonNode firma = raiz.path("signature");
      String checksumRecibido = firma.path("checksum").asText(null);
      JsonNode timestamp = raiz.path("timestamp");
      if (checksumRecibido == null || checksumRecibido.isBlank() || !timestamp.canConvertToLong()) {
        return false;
      }

      List<String> propiedades = new ArrayList<>();
      firma.path("properties").forEach(p -> propiedades.add(p.asText()));
      if (!new HashSet<>(propiedades).containsAll(PROPIEDADES_FIRMADAS_REQUERIDAS)) {
        log.warn(
            "Webhook de Wompi sin firmar los campos requeridos ({} propiedades)",
            propiedades.size());
        return false;
      }

      JsonNode data = raiz.path("data");
      StringBuilder concatenado = new StringBuilder();
      for (String propiedad : propiedades) {
        concatenado.append(valorEnRuta(data, propiedad));
      }
      concatenado.append(timestamp.asLong()).append(properties.getEventsSecret());

      String calculado = sha256Hex(concatenado.toString());
      return MessageDigest.isEqual(
          calculado.getBytes(StandardCharsets.UTF_8),
          checksumRecibido.toLowerCase(Locale.ROOT).getBytes(StandardCharsets.UTF_8));
    } catch (Exception e) {
      // Sin stack trace ni mensaje: el endpoint es público y el mensaje de Jackson trae trozos
      // del payload — cualquiera podría inundar los logs con contenido arbitrario.
      log.warn(
          "Webhook de Wompi ilegible al verificar la firma ({})", e.getClass().getSimpleName());
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
  public Optional<EventoTransaccion> parsearEventoTransaccion(String payloadCrudo) {
    try {
      JsonNode raiz = objectMapper.readTree(payloadCrudo);
      JsonNode transaccion = raiz.path("data").path("transaction");
      if (transaccion.isMissingNode()
          || !transaccion.path("amount_in_cents").canConvertToLong()
          || !raiz.path("timestamp").canConvertToLong()) {
        return Optional.empty();
      }
      String referencia = transaccion.path("reference").asText(null);
      String idExterno = transaccion.path("id").asText(null);
      String moneda = transaccion.path("currency").asText(null);
      if (referencia == null || idExterno == null || moneda == null) {
        return Optional.empty();
      }
      return Optional.of(
          new EventoTransaccion(
              referencia,
              idExterno,
              estadoDe(transaccion.path("status").asText("")),
              transaccion.path("amount_in_cents").asLong(),
              moneda,
              Instant.ofEpochSecond(raiz.path("timestamp").asLong())));
    } catch (Exception e) {
      log.warn("Webhook de Wompi ilegible al parsearlo ({})", e.getClass().getSimpleName());
      return Optional.empty();
    }
  }

  private static EstadoTransaccion estadoDe(String estadoWompi) {
    String estado = estadoWompi.toUpperCase(Locale.ROOT);
    if ("APPROVED".equals(estado)) {
      return EstadoTransaccion.APROBADA;
    }
    return ESTADOS_RECHAZADOS.contains(estado)
        ? EstadoTransaccion.RECHAZADA
        : EstadoTransaccion.EN_CURSO;
  }

  static String sha256Hex(String data) {
    try {
      MessageDigest digest = MessageDigest.getInstance("SHA-256");
      return HexFormat.of().formatHex(digest.digest(data.getBytes(StandardCharsets.UTF_8)));
    } catch (NoSuchAlgorithmException e) {
      throw new IllegalStateException("No se pudo calcular SHA-256", e);
    }
  }
}
