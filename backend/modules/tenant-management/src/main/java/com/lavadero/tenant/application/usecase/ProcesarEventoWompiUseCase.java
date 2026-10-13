package com.lavadero.tenant.application.usecase;

import com.lavadero.shared.application.UseCase;
import com.lavadero.shared.security.TenantContext;
import com.lavadero.tenant.application.command.ProcesarEventoPagoCommand;
import com.lavadero.tenant.application.dto.ResultadoEventoPago;
import com.lavadero.tenant.application.port.PaymentGateway;
import com.lavadero.tenant.application.port.PaymentGateway.EstadoTransaccion;
import com.lavadero.tenant.application.port.PaymentGateway.EventoTransaccion;
import com.lavadero.tenant.domain.model.Pago;
import com.lavadero.tenant.domain.model.PagoReferencia;
import com.lavadero.tenant.domain.model.Tenant;
import com.lavadero.tenant.domain.repository.PagoRepository;
import com.lavadero.tenant.domain.repository.TenantRepository;
import java.time.Clock;
import java.time.Duration;
import java.time.Instant;
import java.util.Optional;
import java.util.UUID;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

/**
 * Webhook de confirmación de la pasarela (endpoint público, sin JWT). Orden de defensas:
 *
 * <ol>
 *   <li>Firma (checksum del propio payload con el secreto de eventos): sin ella, nada más se mira.
 *   <li>Antigüedad del evento: un evento auténtico reenviado tiempo después se rechaza (la firma
 *       incluye el timestamp, así que no se puede "refrescar").
 *   <li>Tenant desde el prefijo de la referencia → {@link TenantContext}, porque `pago` tiene RLS +
 *       FORCE y sin tenant fijado la fila es invisible. El prefijo no autoriza nada: si se
 *       manipula, RLS simplemente no encuentra el pago.
 *   <li>Monto y moneda contra lo que se guardó al iniciar el pago: si no cuadran, nunca se aprueba.
 *   <li>Idempotencia: un pago APROBADO no vuelve a cambiar (ni un rechazo tardío lo deshace); un
 *       RECHAZADO sí puede aprobarse, porque el cliente reintenta en el checkout con la misma
 *       referencia. El índice único sobre {@code transaccion_externa_id} (V20) impide que una misma
 *       transacción apruebe dos pagos.
 * </ol>
 *
 * Un pago aprobado cambia el plan del tenant en la misma transacción.
 */
@Service
public class ProcesarEventoWompiUseCase
    implements UseCase<ProcesarEventoPagoCommand, ResultadoEventoPago> {

  /**
   * Antigüedad máxima aceptada de un evento. Wompi reintenta las entregas fallidas (30 min / 3 h /
   * 24 h) con el timestamp ORIGINAL, así que una ventana corta rechazaría justo los reintentos tras
   * una caída nuestra y dejaría pagos reales en PENDIENTE. 48 h los cubre. El replay de un evento
   * viejo no es peligroso: la firma impide fabricarlo y la transición solo ocurre desde PENDIENTE
   * (más el índice único sobre la transacción externa, V20).
   */
  static final Duration ANTIGUEDAD_MAXIMA = Duration.ofHours(48);

  /** Tolerancia de reloj para eventos que dicen venir "del futuro". */
  static final Duration DESFASE_FUTURO_MAXIMO = Duration.ofMinutes(5);

  private static final Logger log = LoggerFactory.getLogger(ProcesarEventoWompiUseCase.class);

  private final PaymentGateway paymentGateway;
  private final PagoRepository pagoRepository;
  private final TenantRepository tenantRepository;
  private final Clock reloj;

  public ProcesarEventoWompiUseCase(
      PaymentGateway paymentGateway,
      PagoRepository pagoRepository,
      TenantRepository tenantRepository,
      Clock reloj) {
    this.paymentGateway = paymentGateway;
    this.pagoRepository = pagoRepository;
    this.tenantRepository = tenantRepository;
    this.reloj = reloj;
  }

  @Override
  @Transactional
  public ResultadoEventoPago execute(ProcesarEventoPagoCommand input) {
    if (!paymentGateway.firmaValida(input.payloadCrudo())) {
      log.warn("Webhook de pago rechazado: firma inválida");
      return ResultadoEventoPago.FIRMA_INVALIDA;
    }
    Optional<EventoTransaccion> parseado =
        paymentGateway.parsearEventoTransaccion(input.payloadCrudo());
    if (parseado.isEmpty()) {
      return ResultadoEventoPago.IGNORADO;
    }
    EventoTransaccion evento = parseado.get();
    if (estaVencido(evento.emitidoEn())) {
      log.warn(
          "Webhook de pago vencido (emitido {}, referencia {})",
          evento.emitidoEn(),
          evento.referencia());
      return ResultadoEventoPago.EVENTO_VENCIDO;
    }

    Optional<UUID> tenantId = PagoReferencia.extraerTenantId(evento.referencia());
    if (tenantId.isEmpty()) {
      log.warn("Webhook de pago con referencia ajena al formato: {}", evento.referencia());
      return ResultadoEventoPago.IGNORADO;
    }

    TenantContext.set(tenantId.get());
    try {
      return aplicar(evento);
    } finally {
      TenantContext.clear();
    }
  }

  private ResultadoEventoPago aplicar(EventoTransaccion evento) {
    Optional<Pago> encontrado = pagoRepository.findByReferencia(evento.referencia());
    if (encontrado.isEmpty()) {
      log.warn("Webhook de pago sin pago asociado (referencia {})", evento.referencia());
      return ResultadoEventoPago.IGNORADO;
    }
    Pago pago = encontrado.get();
    boolean sinEfecto =
        switch (evento.estado()) {
          case EN_CURSO -> true;
          case APROBADA -> pago.estaAprobado();
          case RECHAZADA -> !pago.estaPendiente();
        };
    if (sinEfecto) {
      return ResultadoEventoPago.IGNORADO;
    }
    if (!pago.coincideCon(evento.montoEnCentavos(), evento.moneda())) {
      log.error(
          "Webhook de pago con monto que no cuadra: pago {} esperaba {} centavos {}, llegó {} {}",
          pago.getId(),
          pago.montoEnCentavos(),
          pago.getMonto().moneda().getCurrencyCode(),
          evento.montoEnCentavos(),
          evento.moneda());
      return ResultadoEventoPago.IGNORADO;
    }

    if (evento.estado() == EstadoTransaccion.APROBADA) {
      pago.aprobar(evento.idTransaccionExterna());
      pagoRepository.save(pago);
      Tenant tenant =
          tenantRepository
              .findById(pago.getTenantId())
              .orElseThrow(
                  () ->
                      new IllegalStateException("Pago de un tenant inexistente: " + pago.getId()));
      tenant.cambiarPlan(pago.getSubscriptionPlanId());
      tenantRepository.save(tenant);
    } else {
      pago.rechazar();
      pagoRepository.save(pago);
    }
    return ResultadoEventoPago.PROCESADO;
  }

  private boolean estaVencido(Instant emitidoEn) {
    Instant ahora = reloj.instant();
    return emitidoEn.isAfter(ahora.plus(DESFASE_FUTURO_MAXIMO))
        || emitidoEn.isBefore(ahora.minus(ANTIGUEDAD_MAXIMA));
  }
}
