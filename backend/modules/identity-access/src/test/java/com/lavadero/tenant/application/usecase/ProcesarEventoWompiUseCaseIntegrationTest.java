package com.lavadero.tenant.application.usecase;

import static org.assertj.core.api.Assertions.assertThat;

import com.lavadero.identity.IdentityAccessTestApplication;
import com.lavadero.identity.infrastructure.security.TenantAwareTransactionAspect;
import com.lavadero.identity.infrastructure.security.TransactionManagementConfig;
import com.lavadero.shared.domain.Money;
import com.lavadero.shared.security.TenantContext;
import com.lavadero.tenant.application.command.ProcesarEventoPagoCommand;
import com.lavadero.tenant.application.dto.ResultadoEventoPago;
import com.lavadero.tenant.domain.model.Pago;
import com.lavadero.tenant.domain.model.PagoEstado;
import com.lavadero.tenant.domain.model.PagoReferencia;
import com.lavadero.tenant.domain.model.SubscriptionPlan;
import com.lavadero.tenant.domain.model.Tenant;
import com.lavadero.tenant.domain.repository.PagoRepository;
import com.lavadero.tenant.domain.repository.SubscriptionPlanRepository;
import com.lavadero.tenant.domain.repository.TenantRepository;
import com.lavadero.tenant.infrastructure.payment.WompiPaymentGateway;
import java.math.BigDecimal;
import java.nio.charset.StandardCharsets;
import java.security.MessageDigest;
import java.time.Clock;
import java.time.Instant;
import java.util.HexFormat;
import java.util.List;
import java.util.UUID;
import java.util.function.Supplier;
import org.junit.jupiter.api.AfterEach;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.boot.test.context.TestConfiguration;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Import;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.test.context.DynamicPropertyRegistry;
import org.springframework.test.context.DynamicPropertySource;
import org.springframework.transaction.PlatformTransactionManager;
import org.springframework.transaction.support.TransactionTemplate;
import org.testcontainers.containers.PostgreSQLContainer;
import org.testcontainers.junit.jupiter.Container;
import org.testcontainers.junit.jupiter.Testcontainers;

/**
 * Webhook de Wompi de punta a punta contra Postgres con RLS + FORCE en `pago`, con el datasource
 * {@code lavadero_app} (no superusuario). El endpoint es público: el caso de uso arranca SIN {@link
 * TenantContext} y solo el prefijo de la referencia le dice en qué tenant buscar.
 *
 * <p>Vive en el árbol de tests de identity-access (aunque el caso de uso es de tenant-management)
 * porque es el único módulo que tiene el {@link TenantAwareTransactionAspect} real — quien aplica
 * {@code set_config} — y tenant-management no puede depender de identity-access ni en tests sin
 * romper la dirección de dependencias. Mismo montaje que {@code
 * RefreshTokenUseCaseIntegrationTest}.
 */
@SpringBootTest(classes = IdentityAccessTestApplication.class)
@Import({
  TransactionManagementConfig.class,
  TenantAwareTransactionAspect.class,
  ProcesarEventoWompiUseCaseIntegrationTest.RelojDePrueba.class,
  WompiPaymentGateway.class,
  ProcesarEventoWompiUseCase.class
})
@Testcontainers
class ProcesarEventoWompiUseCaseIntegrationTest {

  /** El {@code Clock} de producción vive en bootstrap: este contexto declara el suyo. */
  @TestConfiguration
  static class RelojDePrueba {
    @Bean
    Clock reloj() {
      return Clock.systemUTC();
    }
  }

  private static final String SECRETO_EVENTOS = "test_events_integracion";
  private static final UUID PLAN_STARTER_ID =
      UUID.fromString("00000000-0000-0000-0000-000000000001");

  @Container
  static final PostgreSQLContainer<?> POSTGRES =
      new PostgreSQLContainer<>("postgres:16-alpine").withDatabaseName("lavadero_test");

  @DynamicPropertySource
  static void datasourceProperties(DynamicPropertyRegistry registry) {
    registry.add("spring.flyway.url", POSTGRES::getJdbcUrl);
    registry.add("spring.flyway.user", POSTGRES::getUsername);
    registry.add("spring.flyway.password", POSTGRES::getPassword);

    registry.add("spring.datasource.url", POSTGRES::getJdbcUrl);
    registry.add("spring.datasource.username", () -> "lavadero_app");
    registry.add("spring.datasource.password", () -> "lavadero_app");

    registry.add("lavadero.payments.wompi.events-secret", () -> SECRETO_EVENTOS);
  }

  @Autowired private TenantRepository tenantRepository;
  @Autowired private SubscriptionPlanRepository subscriptionPlanRepository;
  @Autowired private PagoRepository pagoRepository;
  @Autowired private ProcesarEventoWompiUseCase useCase;
  @Autowired private JdbcTemplate jdbcTemplate;
  @Autowired private PlatformTransactionManager transactionManager;

  @AfterEach
  void limpiarContexto() {
    TenantContext.clear();
  }

  @Test
  void apruebaElPagoYCambiaElPlanSinTenantEnContexto() {
    UUID planPro = crearPlanPro();
    UUID tenantId = crearTenant();
    Pago pago = crearPagoPendiente(tenantId, planPro);
    assertThat(TenantContext.get()).isEmpty();

    ResultadoEventoPago resultado =
        useCase.execute(
            new ProcesarEventoPagoCommand(eventoAprobado(pago.getReferencia(), "tx-ok-1")));

    assertThat(resultado).isEqualTo(ResultadoEventoPago.PROCESADO);
    Pago leido = comoTenant(tenantId, () -> pagoRepository.findById(pago.getId())).orElseThrow();
    assertThat(leido.getEstado()).isEqualTo(PagoEstado.APROBADO);
    assertThat(leido.getTransaccionExternaId()).contains("tx-ok-1");
    assertThat(tenantRepository.findById(tenantId).orElseThrow().getSubscriptionPlanId())
        .isEqualTo(planPro);

    // Reintento del mismo evento: idempotente.
    assertThat(
            useCase.execute(
                new ProcesarEventoPagoCommand(eventoAprobado(pago.getReferencia(), "tx-ok-1"))))
        .isEqualTo(ResultadoEventoPago.IGNORADO);
  }

  @Test
  void unPrefijoDeTenantFalsificadoNoEncuentraNada() {
    UUID planPro = crearPlanPro();
    UUID tenantVictima = crearTenant();
    UUID tenantAtacante = crearTenant();
    Pago pagoVictima = crearPagoPendiente(tenantVictima, planPro);

    // Misma parte aleatoria, prefijo de otro tenant: la referencia no es parte del checksum de
    // Wompi, así que la firma sigue siendo válida — y aun así RLS no deja ver el pago.
    String sufijo =
        pagoVictima.getReferencia().substring(pagoVictima.getReferencia().lastIndexOf('_'));
    String referenciaForjada = "pago_" + tenantAtacante + sufijo;
    assertThat(PagoReferencia.extraerTenantId(referenciaForjada)).contains(tenantAtacante);

    ResultadoEventoPago resultado =
        useCase.execute(new ProcesarEventoPagoCommand(eventoAprobado(referenciaForjada, "tx-x")));

    assertThat(resultado).isEqualTo(ResultadoEventoPago.IGNORADO);
    assertThat(comoTenant(tenantAtacante, () -> pagoRepository.findRecientesDelTenantActual(50)))
        .isEmpty();
    assertThat(
            comoTenant(tenantVictima, () -> pagoRepository.findById(pagoVictima.getId()))
                .orElseThrow()
                .getEstado())
        .isEqualTo(PagoEstado.PENDIENTE);
    assertThat(tenantRepository.findById(tenantVictima).orElseThrow().getSubscriptionPlanId())
        .isEqualTo(PLAN_STARTER_ID);
  }

  @Test
  void unaFirmaIncorrectaNoTocaLaBaseDeDatos() {
    UUID tenantId = crearTenant();
    Pago pago = crearPagoPendiente(tenantId, PLAN_STARTER_ID);
    String payload =
        eventoAprobado(pago.getReferencia(), "tx-1").replace("\"APPROVED\"", "\"approved\"");

    assertThat(useCase.execute(new ProcesarEventoPagoCommand(payload)))
        .isEqualTo(ResultadoEventoPago.FIRMA_INVALIDA);
  }

  private String eventoAprobado(String referencia, String idTransaccion) {
    long monto = 9_900_000L;
    long timestamp = Instant.now().getEpochSecond();
    String checksum = sha256(idTransaccion + "APPROVED" + monto + timestamp + SECRETO_EVENTOS);
    return """
        {"event":"transaction.updated",
         "data":{"transaction":{"id":"%s","status":"APPROVED","amount_in_cents":%d,
                                "currency":"COP","reference":"%s"}},
         "environment":"test",
         "signature":{"properties":["transaction.id","transaction.status",
                                    "transaction.amount_in_cents"],"checksum":"%s"},
         "timestamp":%d}
        """
        .formatted(idTransaccion, monto, referencia, checksum, timestamp);
  }

  private static String sha256(String data) {
    try {
      return HexFormat.of()
          .formatHex(
              MessageDigest.getInstance("SHA-256").digest(data.getBytes(StandardCharsets.UTF_8)));
    } catch (Exception e) {
      throw new IllegalStateException(e);
    }
  }

  private Pago crearPagoPendiente(UUID tenantId, UUID planId) {
    Pago pago =
        Pago.nuevo(
            tenantId,
            planId,
            Money.cop(new BigDecimal("99000")),
            PagoReferencia.generar(tenantId),
            Instant.now());
    comoTenant(tenantId, () -> pagoRepository.save(pago));
    return pago;
  }

  private UUID crearPlanPro() {
    SubscriptionPlan plan =
        new SubscriptionPlan(
            UUID.randomUUID(), "Pro", Money.cop(new BigDecimal("99000")), 3, 10, List.of());
    subscriptionPlanRepository.save(plan);
    return plan.getId();
  }

  private UUID crearTenant() {
    String slug = "lavadero-" + UUID.randomUUID().toString().substring(0, 8);
    Tenant tenant = Tenant.nuevo("Lavadero", "NIT-" + UUID.randomUUID(), slug, PLAN_STARTER_ID);
    tenantRepository.save(tenant);
    return tenant.getId();
  }

  private <T> T comoTenant(UUID tenantId, Supplier<T> accion) {
    TransactionTemplate transactionTemplate = new TransactionTemplate(transactionManager);
    return transactionTemplate.execute(
        status -> {
          jdbcTemplate.queryForObject(
              "SELECT set_config('app.current_tenant_id', ?, true)",
              String.class,
              tenantId.toString());
          return accion.get();
        });
  }
}
