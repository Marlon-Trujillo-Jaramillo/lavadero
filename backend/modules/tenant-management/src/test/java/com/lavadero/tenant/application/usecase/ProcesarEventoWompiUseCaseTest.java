package com.lavadero.tenant.application.usecase;

import static org.assertj.core.api.Assertions.assertThat;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.never;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

import com.lavadero.shared.domain.Money;
import com.lavadero.shared.security.TenantContext;
import com.lavadero.tenant.application.command.ProcesarEventoPagoCommand;
import com.lavadero.tenant.application.dto.ResultadoEventoPago;
import com.lavadero.tenant.application.port.PaymentGateway;
import com.lavadero.tenant.application.port.PaymentGateway.EstadoTransaccion;
import com.lavadero.tenant.application.port.PaymentGateway.EventoTransaccion;
import com.lavadero.tenant.domain.model.Pago;
import com.lavadero.tenant.domain.model.PagoEstado;
import com.lavadero.tenant.domain.model.PagoReferencia;
import com.lavadero.tenant.domain.model.Tenant;
import com.lavadero.tenant.domain.repository.PagoRepository;
import com.lavadero.tenant.domain.repository.TenantRepository;
import java.math.BigDecimal;
import java.time.Clock;
import java.time.Instant;
import java.time.ZoneOffset;
import java.util.Optional;
import java.util.UUID;
import java.util.concurrent.atomic.AtomicReference;
import org.junit.jupiter.api.AfterEach;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;

class ProcesarEventoWompiUseCaseTest {

  private static final Instant AHORA = Instant.parse("2026-10-12T15:00:00Z");
  private static final UUID PLAN_STARTER = UUID.randomUUID();
  private static final UUID PLAN_PRO = UUID.randomUUID();
  private static final String PAYLOAD = "{}";

  private final PaymentGateway gateway = mock(PaymentGateway.class);
  private final PagoRepository pagoRepository = mock(PagoRepository.class);
  private final TenantRepository tenantRepository = mock(TenantRepository.class);
  private final ProcesarEventoWompiUseCase useCase =
      new ProcesarEventoWompiUseCase(
          gateway, pagoRepository, tenantRepository, Clock.fixed(AHORA, ZoneOffset.UTC));

  private Tenant tenant;
  private Pago pago;

  @BeforeEach
  void setUp() {
    tenant = Tenant.nuevo("Lavadero", "NIT-1", "lavadero-uno", PLAN_STARTER);
    pago =
        Pago.nuevo(
            tenant.getId(),
            PLAN_PRO,
            Money.cop(new BigDecimal("99000")),
            PagoReferencia.generar(tenant.getId()),
            AHORA);
    when(gateway.firmaValida(PAYLOAD)).thenReturn(true);
    when(pagoRepository.findByReferencia(pago.getReferencia())).thenReturn(Optional.of(pago));
    when(tenantRepository.findById(tenant.getId())).thenReturn(Optional.of(tenant));
  }

  @AfterEach
  void limpiar() {
    TenantContext.clear();
  }

  @Test
  void unPagoAprobadoCambiaElPlanDelTenant() {
    AtomicReference<UUID> tenantDuranteLaBusqueda = new AtomicReference<>();
    when(pagoRepository.findByReferencia(pago.getReferencia()))
        .thenAnswer(
            inv -> {
              tenantDuranteLaBusqueda.set(TenantContext.get().orElse(null));
              return Optional.of(pago);
            });
    llega(evento(EstadoTransaccion.APROBADA, 9_900_000L, "COP", AHORA));

    assertThat(ejecutar()).isEqualTo(ResultadoEventoPago.PROCESADO);
    assertThat(pago.getEstado()).isEqualTo(PagoEstado.APROBADO);
    assertThat(pago.getTransaccionExternaId()).contains("tx-1");
    assertThat(tenant.getSubscriptionPlanId()).isEqualTo(PLAN_PRO);
    verify(tenantRepository).save(tenant);
    assertThat(tenantDuranteLaBusqueda.get())
        .as("el tenant sale del prefijo de la referencia, no de un JWT")
        .isEqualTo(tenant.getId());
    assertThat(TenantContext.get()).as("no se filtra el tenant al hilo").isEmpty();
  }

  @Test
  void unPagoRechazadoNoTocaElPlan() {
    llega(evento(EstadoTransaccion.RECHAZADA, 9_900_000L, "COP", AHORA));

    assertThat(ejecutar()).isEqualTo(ResultadoEventoPago.PROCESADO);
    assertThat(pago.getEstado()).isEqualTo(PagoEstado.RECHAZADO);
    assertThat(tenant.getSubscriptionPlanId()).isEqualTo(PLAN_STARTER);
  }

  @Test
  void firmaInvalidaNoLeeNada() {
    when(gateway.firmaValida(PAYLOAD)).thenReturn(false);

    assertThat(ejecutar()).isEqualTo(ResultadoEventoPago.FIRMA_INVALIDA);
    verify(gateway, never()).parsearEventoTransaccion(any());
    verify(pagoRepository, never()).findByReferencia(any());
  }

  @Test
  void unEventoDeMasDe48HorasSeRechazaAunqueEsteFirmado() {
    llega(evento(EstadoTransaccion.APROBADA, 9_900_000L, "COP", AHORA.minusSeconds(49 * 3600)));

    assertThat(ejecutar()).isEqualTo(ResultadoEventoPago.EVENTO_VENCIDO);
    assertThat(pago.getEstado()).isEqualTo(PagoEstado.PENDIENTE);
  }

  /** Wompi reintenta a las 24 h con el timestamp original: ese reintento debe procesarse. */
  @Test
  void elReintentoDeWompiA24HorasSeProcesa() {
    llega(evento(EstadoTransaccion.APROBADA, 9_900_000L, "COP", AHORA.minusSeconds(24 * 3600)));

    assertThat(ejecutar()).isEqualTo(ResultadoEventoPago.PROCESADO);
    assertThat(pago.getEstado()).isEqualTo(PagoEstado.APROBADO);
  }

  @Test
  void unEventoDelFuturoFueraDeLaVentanaTambienSeRechaza() {
    llega(evento(EstadoTransaccion.APROBADA, 9_900_000L, "COP", AHORA.plusSeconds(6 * 60)));

    assertThat(ejecutar()).isEqualTo(ResultadoEventoPago.EVENTO_VENCIDO);
  }

  @Test
  void unMontoDistintoNuncaApruebaElPago() {
    llega(evento(EstadoTransaccion.APROBADA, 100L, "COP", AHORA));

    assertThat(ejecutar()).isEqualTo(ResultadoEventoPago.IGNORADO);
    assertThat(pago.getEstado()).isEqualTo(PagoEstado.PENDIENTE);
    assertThat(tenant.getSubscriptionPlanId()).isEqualTo(PLAN_STARTER);
    verify(pagoRepository, never()).save(any());
  }

  @Test
  void unaMonedaDistintaNuncaApruebaElPago() {
    llega(evento(EstadoTransaccion.APROBADA, 9_900_000L, "USD", AHORA));

    assertThat(ejecutar()).isEqualTo(ResultadoEventoPago.IGNORADO);
    assertThat(pago.getEstado()).isEqualTo(PagoEstado.PENDIENTE);
  }

  @Test
  void esIdempotente_unPagoYaCerradoNoCambia() {
    pago.aprobar("tx-original");
    llega(evento(EstadoTransaccion.RECHAZADA, 9_900_000L, "COP", AHORA));

    assertThat(ejecutar()).isEqualTo(ResultadoEventoPago.IGNORADO);
    assertThat(pago.getEstado()).isEqualTo(PagoEstado.APROBADO);
    assertThat(pago.getTransaccionExternaId()).contains("tx-original");
    verify(pagoRepository, never()).save(any());
  }

  /** El cliente reintenta en el checkout con la misma referencia tras un rechazo: se cobra. */
  @Test
  void unRechazoSeguidoDeUnaAprobacionApruebaYCambiaElPlan() {
    llega(evento(EstadoTransaccion.RECHAZADA, 9_900_000L, "COP", AHORA));
    assertThat(ejecutar()).isEqualTo(ResultadoEventoPago.PROCESADO);
    assertThat(pago.getEstado()).isEqualTo(PagoEstado.RECHAZADO);

    when(gateway.parsearEventoTransaccion(PAYLOAD))
        .thenReturn(
            Optional.of(
                new EventoTransaccion(
                    pago.getReferencia(),
                    "tx-2",
                    EstadoTransaccion.APROBADA,
                    9_900_000L,
                    "COP",
                    AHORA)));
    assertThat(ejecutar()).isEqualTo(ResultadoEventoPago.PROCESADO);

    assertThat(pago.getEstado()).isEqualTo(PagoEstado.APROBADO);
    assertThat(pago.getTransaccionExternaId()).contains("tx-2");
    assertThat(tenant.getSubscriptionPlanId()).isEqualTo(PLAN_PRO);
  }

  @Test
  void unaAprobacionSeguidaDeUnRechazoSigueAprobada() {
    llega(evento(EstadoTransaccion.APROBADA, 9_900_000L, "COP", AHORA));
    assertThat(ejecutar()).isEqualTo(ResultadoEventoPago.PROCESADO);

    llega(evento(EstadoTransaccion.RECHAZADA, 9_900_000L, "COP", AHORA));
    assertThat(ejecutar()).isEqualTo(ResultadoEventoPago.IGNORADO);

    assertThat(pago.getEstado()).isEqualTo(PagoEstado.APROBADO);
    assertThat(tenant.getSubscriptionPlanId()).isEqualTo(PLAN_PRO);
  }

  @Test
  void unaAprobacionDuplicadaNoSeReaplica() {
    pago.aprobar("tx-original");
    llega(evento(EstadoTransaccion.APROBADA, 9_900_000L, "COP", AHORA));

    assertThat(ejecutar()).isEqualTo(ResultadoEventoPago.IGNORADO);
    assertThat(pago.getTransaccionExternaId()).contains("tx-original");
    verify(pagoRepository, never()).save(any());
  }

  @Test
  void unaTransaccionEnCursoNoCambiaNada() {
    llega(evento(EstadoTransaccion.EN_CURSO, 9_900_000L, "COP", AHORA));

    assertThat(ejecutar()).isEqualTo(ResultadoEventoPago.IGNORADO);
    assertThat(pago.getEstado()).isEqualTo(PagoEstado.PENDIENTE);
  }

  @Test
  void unaReferenciaSinPrefijoDeTenantSeIgnora() {
    when(gateway.parsearEventoTransaccion(PAYLOAD))
        .thenReturn(
            Optional.of(
                new EventoTransaccion(
                    "otra-cosa", "tx-1", EstadoTransaccion.APROBADA, 9_900_000L, "COP", AHORA)));

    assertThat(ejecutar()).isEqualTo(ResultadoEventoPago.IGNORADO);
    verify(pagoRepository, never()).findByReferencia(any());
  }

  private ResultadoEventoPago ejecutar() {
    return useCase.execute(new ProcesarEventoPagoCommand(PAYLOAD));
  }

  private void llega(EventoTransaccion evento) {
    when(gateway.parsearEventoTransaccion(PAYLOAD)).thenReturn(Optional.of(evento));
  }

  private EventoTransaccion evento(
      EstadoTransaccion estado, long centavos, String moneda, Instant emitidoEn) {
    return new EventoTransaccion(pago.getReferencia(), "tx-1", estado, centavos, moneda, emitidoEn);
  }
}
