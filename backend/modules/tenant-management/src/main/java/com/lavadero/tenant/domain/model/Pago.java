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

  public static Pago nuevo(UUID tenantId, UUID subscriptionPlanId, Money monto, String referencia) {
    return new Pago(
        UUID.randomUUID(),
        tenantId,
        subscriptionPlanId,
        monto,
        referencia,
        PagoEstado.PENDIENTE,
        null,
        Instant.now());
  }

  /**
   * Idempotente a propósito: Wompi puede reintentar la entrega del webhook (o el mismo evento
   * puede llegar duplicado); aprobar dos veces el mismo pago no debe fallar ni tener efecto
   * distinto de aprobarlo una vez.
   */
  public void aprobar(String transaccionExternaId) {
    if (estado == PagoEstado.APROBADO) {
      return;
    }
    if (estado == PagoEstado.RECHAZADO) {
      throw new IllegalStateException("No se puede aprobar un pago ya rechazado: " + getId());
    }
    this.estado = PagoEstado.APROBADO;
    this.transaccionExternaId = Objects.requireNonNull(transaccionExternaId);
  }

  public void rechazar() {
    if (estado == PagoEstado.APROBADO) {
      throw new IllegalStateException("No se puede rechazar un pago ya aprobado: " + getId());
    }
    this.estado = PagoEstado.RECHAZADO;
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
