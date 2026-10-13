package com.lavadero.tenant.application.usecase;

import com.lavadero.shared.application.UseCase;
import com.lavadero.shared.application.exception.NotFoundException;
import com.lavadero.shared.application.exception.ValidationException;
import com.lavadero.shared.security.TenantContext;
import com.lavadero.tenant.application.command.IniciarPagoSuscripcionCommand;
import com.lavadero.tenant.application.dto.CheckoutPagoDto;
import com.lavadero.tenant.application.port.PaymentGateway;
import com.lavadero.tenant.domain.model.Pago;
import com.lavadero.tenant.domain.model.PagoReferencia;
import com.lavadero.tenant.domain.model.SubscriptionPlan;
import com.lavadero.tenant.domain.repository.PagoRepository;
import com.lavadero.tenant.domain.repository.SubscriptionPlanRepository;
import java.time.Clock;
import java.time.Duration;
import java.time.Instant;
import java.util.Optional;
import java.util.UUID;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

/**
 * El ADMIN_TENANT elige un plan y recibe los datos firmados para pagarlo en el Web Checkout de la
 * pasarela. Crea el {@link Pago} PENDIENTE que luego cierra {@code ProcesarEventoWompiUseCase}.
 *
 * <p>El monto sale SIEMPRE del plan guardado, nunca del cliente; y la referencia embebe el tenant
 * (ver {@link PagoReferencia}) para que el webhook, que llega sin JWT, pueda leer el pago bajo RLS.
 */
@Service
public class IniciarPagoSuscripcionUseCase
    implements UseCase<IniciarPagoSuscripcionCommand, CheckoutPagoDto> {

  /**
   * Un PENDIENTE del mismo plan y precio creado hace menos que esto se reusa (misma referencia,
   * mismo checkout): reabrir la pantalla de pago o hacer doble clic no deja filas huérfanas.
   */
  static final Duration VENTANA_REUSO = Duration.ofMinutes(30);

  private final SubscriptionPlanRepository subscriptionPlanRepository;
  private final PagoRepository pagoRepository;
  private final PaymentGateway paymentGateway;
  private final Clock reloj;

  public IniciarPagoSuscripcionUseCase(
      SubscriptionPlanRepository subscriptionPlanRepository,
      PagoRepository pagoRepository,
      PaymentGateway paymentGateway,
      Clock reloj) {
    this.subscriptionPlanRepository = subscriptionPlanRepository;
    this.pagoRepository = pagoRepository;
    this.paymentGateway = paymentGateway;
    this.reloj = reloj;
  }

  @Override
  @Transactional
  public CheckoutPagoDto execute(IniciarPagoSuscripcionCommand input) {
    UUID tenantId = TenantContext.requerido();
    SubscriptionPlan plan =
        subscriptionPlanRepository
            .findById(input.subscriptionPlanId())
            .orElseThrow(() -> NotFoundException.de("Plan", input.subscriptionPlanId()));
    if (plan.getPrecio().monto().signum() <= 0) {
      throw new ValidationException("El plan '%s' no requiere pago".formatted(plan.getNombre()));
    }

    Instant ahora = reloj.instant();
    Optional<Pago> reusable =
        pagoRepository
            .findPendienteDelPlanDesde(plan.getId(), ahora.minus(VENTANA_REUSO))
            .filter(p -> p.getMonto().equals(plan.getPrecio()));
    Pago pago =
        reusable.orElseGet(
            () ->
                Pago.nuevo(
                    tenantId,
                    plan.getId(),
                    plan.getPrecio(),
                    PagoReferencia.generar(tenantId),
                    ahora));
    PaymentGateway.DatosCheckout checkout = paymentGateway.prepararCheckout(pago);
    if (reusable.isEmpty()) {
      pagoRepository.save(pago);
    }

    return new CheckoutPagoDto(
        pago.getId(),
        checkout.urlCheckout(),
        checkout.llavePublica(),
        checkout.referencia(),
        checkout.montoEnCentavos(),
        checkout.moneda(),
        checkout.firmaIntegridad(),
        checkout.urlRedireccion());
  }
}
