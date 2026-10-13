package com.lavadero.tenant.application.usecase;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.never;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

import com.lavadero.shared.application.exception.NotFoundException;
import com.lavadero.shared.domain.Money;
import com.lavadero.shared.security.TenantContext;
import com.lavadero.tenant.application.command.IniciarPagoSuscripcionCommand;
import com.lavadero.tenant.application.dto.CheckoutPagoDto;
import com.lavadero.tenant.application.port.PaymentGateway;
import com.lavadero.tenant.domain.model.Pago;
import com.lavadero.tenant.domain.model.PagoEstado;
import com.lavadero.tenant.domain.model.PagoReferencia;
import com.lavadero.tenant.domain.model.SubscriptionPlan;
import com.lavadero.tenant.domain.repository.PagoRepository;
import com.lavadero.tenant.domain.repository.SubscriptionPlanRepository;
import java.math.BigDecimal;
import java.time.Clock;
import java.time.Duration;
import java.time.Instant;
import java.time.ZoneOffset;
import java.util.List;
import java.util.Optional;
import java.util.UUID;
import org.junit.jupiter.api.AfterEach;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.mockito.ArgumentCaptor;

class IniciarPagoSuscripcionUseCaseTest {

  private final SubscriptionPlanRepository planes = mock(SubscriptionPlanRepository.class);
  private final PagoRepository pagos = mock(PagoRepository.class);
  private final PaymentGateway gateway = mock(PaymentGateway.class);
  private static final Instant AHORA = Instant.parse("2026-10-12T15:00:00Z");
  private final IniciarPagoSuscripcionUseCase useCase =
      new IniciarPagoSuscripcionUseCase(planes, pagos, gateway, Clock.fixed(AHORA, ZoneOffset.UTC));
  private final SubscriptionPlan plan =
      new SubscriptionPlan(
          UUID.randomUUID(), "Pro", Money.cop(new BigDecimal("99000")), 3, 10, List.of());

  @BeforeEach
  void setUp() {
    when(planes.findById(plan.getId())).thenReturn(Optional.of(plan));
    when(pagos.findPendienteDelPlanDesde(any(), any())).thenReturn(Optional.empty());
    when(gateway.prepararCheckout(any()))
        .thenAnswer(
            inv -> {
              Pago p = inv.getArgument(0);
              return new PaymentGateway.DatosCheckout(
                  "https://checkout", "pub", p.getReferencia(), 9_900_000L, "COP", "firma", null);
            });
  }

  @AfterEach
  void limpiar() {
    TenantContext.clear();
  }

  @Test
  void creaUnPagoPendienteConElPrecioDelPlanYReferenciaDelTenant() {
    UUID tenantId = UUID.randomUUID();
    TenantContext.set(tenantId);

    CheckoutPagoDto checkout = useCase.execute(new IniciarPagoSuscripcionCommand(plan.getId()));

    ArgumentCaptor<Pago> guardado = ArgumentCaptor.forClass(Pago.class);
    verify(pagos).save(guardado.capture());
    Pago pago = guardado.getValue();
    assertThat(pago.getEstado()).isEqualTo(PagoEstado.PENDIENTE);
    assertThat(pago.getMonto()).isEqualTo(Money.cop(new BigDecimal("99000")));
    assertThat(PagoReferencia.extraerTenantId(pago.getReferencia())).contains(tenantId);
    assertThat(checkout.pagoId()).isEqualTo(pago.getId());
    assertThat(checkout.referencia()).isEqualTo(pago.getReferencia());
    assertThat(pago.getCreadoEn()).as("usa el reloj inyectado").isEqualTo(AHORA);
  }

  @Test
  void reusaUnPendienteRecienteDelMismoPlanEnVezDeCrearOtro() {
    UUID tenantId = UUID.randomUUID();
    TenantContext.set(tenantId);
    Pago existente =
        Pago.nuevo(
            tenantId,
            plan.getId(),
            plan.getPrecio(),
            PagoReferencia.generar(tenantId),
            AHORA.minusSeconds(600));
    when(pagos.findPendienteDelPlanDesde(plan.getId(), AHORA.minus(Duration.ofMinutes(30))))
        .thenReturn(Optional.of(existente));

    CheckoutPagoDto checkout = useCase.execute(new IniciarPagoSuscripcionCommand(plan.getId()));

    assertThat(checkout.pagoId()).isEqualTo(existente.getId());
    assertThat(checkout.referencia()).isEqualTo(existente.getReferencia());
    verify(pagos, never()).save(any());
  }

  @Test
  void noReusaUnPendienteSiElPrecioDelPlanCambio() {
    UUID tenantId = UUID.randomUUID();
    TenantContext.set(tenantId);
    Pago conPrecioViejo =
        Pago.nuevo(
            tenantId,
            plan.getId(),
            Money.cop(new BigDecimal("79000")),
            PagoReferencia.generar(tenantId),
            AHORA.minusSeconds(60));
    when(pagos.findPendienteDelPlanDesde(any(), any())).thenReturn(Optional.of(conPrecioViejo));

    CheckoutPagoDto checkout = useCase.execute(new IniciarPagoSuscripcionCommand(plan.getId()));

    assertThat(checkout.pagoId()).isNotEqualTo(conPrecioViejo.getId());
    verify(pagos).save(any());
  }

  @Test
  void unPlanInexistenteEs404() {
    TenantContext.set(UUID.randomUUID());
    UUID planId = UUID.randomUUID();
    when(planes.findById(planId)).thenReturn(Optional.empty());

    assertThatThrownBy(() -> useCase.execute(new IniciarPagoSuscripcionCommand(planId)))
        .isInstanceOf(NotFoundException.class);
  }
}
