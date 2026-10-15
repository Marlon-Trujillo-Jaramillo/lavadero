package com.lavadero.tenant.domain.model;

import com.lavadero.shared.domain.AggregateRoot;
import com.lavadero.shared.domain.Money;
import java.time.Instant;
import java.util.Objects;
import java.util.Optional;
import java.util.UUID;

/**
 * Un intento de cobro de un plan de suscripción vía la pasarela de pago (Wompi, ver {@code
 * WompiPaymentGateway}). Antes de esto no existía ninguna forma de cobrar a un tenant: los planes
 * de suscripción eran solo un catálogo administrable (ver spec de auditoría técnica/negocio
 * 2026-08-18).
 *
 * <p>{@code referencia} es lo que se envía a la pasarela y lo que ella devuelve en el webhook de
 * confirmación — es la única forma de correlacionar "este pago que inicié" con "este evento que
 * llegó", ya que el id interno nunca sale de nuestra base de datos.
 */
public class Pago extends AggregateRoot<UUID> {

  private final UUID tenantId;
  private final UUID subscriptionPlanId;
  private final Money monto;
  private final String referencia;
  private PagoEstado estado;
  private String transaccionExternaId;
  private final Instant creadoEn;

  public Pago(
      UUID id,
      UUID tenantId,
      UUID subscriptionPlanId,
      Money monto,
      String referencia,
      PagoEstado estado,
      String transaccionExternaId,
      Instant creadoEn) {
    super(id);
    this.tenantId = Objects.requireNonNull(tenantId, "tenantId no puede ser nulo");
    this.subscriptionPlanId = Objects.requireNonNull(subscriptionPlanId);
    this.monto = Objects.requireNonNull(monto);
    this.referencia = Objects.requireNonNull(referencia);
    this.estado = Objects.requireNonNull(estado);
    this.transaccionExternaId = transaccionExternaId;
    this.creadoEn = Objects.requireNonNull(creadoEn);
  }

  /** {@code creadoEn} lo da el caso de uso (reloj inyectado), no {@code Instant.now()}. */
  public static Pago nuevo(
      UUID tenantId, UUID subscriptionPlanId, Money monto, String referencia, Instant creadoEn) {
    return new Pago(
        UUID.randomUUID(),
        tenantId,
        subscriptionPlanId,
        monto,
        referencia,
        PagoEstado.PENDIENTE,
        null,
        creadoEn);
  }

  /**
   * Idempotente a propósito: Wompi puede reintentar la entrega del webhook (o el mismo evento puede
   * llegar duplicado); aprobar dos veces el mismo pago no debe fallar ni tener efecto distinto de
   * aprobarlo una vez.
   *
   * <p>Un pago RECHAZADO SÍ puede aprobarse: en el Web Checkout el cliente reintenta con la misma
   * referencia tras un rechazo (otra tarjeta, PSE, ...), y esa aprobación posterior es dinero real
   * cobrado — ignorarla cobraría sin activar el plan.
   */
  public void aprobar(String transaccionExternaId) {
    if (estado == PagoEstado.APROBADO) {
      return;
    }
    this.estado = PagoEstado.APROBADO;
    this.transaccionExternaId = Objects.requireNonNull(transaccionExternaId);
  }

  /**
   * Solo un pago PENDIENTE pasa a RECHAZADO. Sobre uno ya cerrado no hace nada: un rechazo nunca
   * deshace una aprobación (puede llegar después, fuera de orden, por un intento previo).
   */
  public void rechazar() {
    if (estado == PagoEstado.PENDIENTE) {
      this.estado = PagoEstado.RECHAZADO;
    }
  }

  public boolean estaPendiente() {
    return estado == PagoEstado.PENDIENTE;
  }

  public boolean estaAprobado() {
    return estado == PagoEstado.APROBADO;
  }

  /** Monto en la unidad mínima de la moneda (centavos), como lo exige la pasarela. */
  public long montoEnCentavos() {
    return monto.monto().movePointRight(2).longValueExact();
  }

  /**
   * ¿El monto/moneda que reporta la pasarela es exactamente lo que se cobró? Un evento con otro
   * monto nunca aprueba el pago (pagar $1 no puede activar un plan de $99.000).
   */
  public boolean coincideCon(long montoEnCentavosReportado, String monedaReportada) {
    return montoEnCentavos() == montoEnCentavosReportado
        && monto.moneda().getCurrencyCode().equals(monedaReportada);
  }

  public UUID getTenantId() {
    return tenantId;
  }

  public UUID getSubscriptionPlanId() {
    return subscriptionPlanId;
  }

  public Money getMonto() {
    return monto;
  }

  public String getReferencia() {
    return referencia;
  }

  public PagoEstado getEstado() {
    return estado;
  }

  public Optional<String> getTransaccionExternaId() {
    return Optional.ofNullable(transaccionExternaId);
  }

  public Instant getCreadoEn() {
    return creadoEn;
  }
}
