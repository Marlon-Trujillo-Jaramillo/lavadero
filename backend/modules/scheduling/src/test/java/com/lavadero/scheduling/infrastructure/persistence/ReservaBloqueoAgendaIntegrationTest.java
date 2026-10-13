package com.lavadero.scheduling.infrastructure.persistence;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;

import com.lavadero.scheduling.SchedulingTestApplication;
import com.lavadero.scheduling.domain.repository.ReservaRepository;
import java.time.Duration;
import java.time.Instant;
import java.util.UUID;
import java.util.concurrent.CompletableFuture;
import java.util.concurrent.CountDownLatch;
import java.util.concurrent.TimeUnit;
import java.util.concurrent.atomic.AtomicReference;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.test.context.DynamicPropertyRegistry;
import org.springframework.test.context.DynamicPropertySource;
import org.springframework.transaction.IllegalTransactionStateException;
import org.springframework.transaction.PlatformTransactionManager;
import org.springframework.transaction.support.TransactionTemplate;
import org.testcontainers.containers.PostgreSQLContainer;
import org.testcontainers.junit.jupiter.Container;
import org.testcontainers.junit.jupiter.Testcontainers;

/**
 * {@link ReservaRepository#bloquearAgendaDeSucursal}: la segunda transacción sobre la misma
 * sucursal espera a que la primera termine (es lo que evita la sobreventa en CrearReservaUseCase).
 */
@SpringBootTest(classes = SchedulingTestApplication.class)
@Testcontainers
class ReservaBloqueoAgendaIntegrationTest {

  private static final Duration RETENCION = Duration.ofMillis(800);

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
  }

  @Autowired private ReservaRepository reservaRepository;
  @Autowired private PlatformTransactionManager transactionManager;

  @Test
  void unaSegundaTransaccionEsperaAQueLaPrimeraLibereLaSucursal() throws Exception {
    UUID sucursalId = UUID.randomUUID();
    CountDownLatch primeraTieneElLock = new CountDownLatch(1);
    AtomicReference<Instant> primeraTermino = new AtomicReference<>();

    CompletableFuture<Void> primera =
        CompletableFuture.runAsync(
            () ->
                enTransaccion(
                    () -> {
                      reservaRepository.bloquearAgendaDeSucursal(sucursalId);
                      primeraTieneElLock.countDown();
                      dormir(RETENCION);
                      primeraTermino.set(Instant.now());
                    }));

    assertThat(primeraTieneElLock.await(10, TimeUnit.SECONDS)).isTrue();
    enTransaccion(() -> reservaRepository.bloquearAgendaDeSucursal(sucursalId));
    Instant segundaObtuvoElLock = Instant.now();
    primera.get(10, TimeUnit.SECONDS);

    assertThat(segundaObtuvoElLock).isAfterOrEqualTo(primeraTermino.get());
  }

  @Test
  void fueraDeUnaTransaccionFallaEnVezDeNoProtegerNada() {
    assertThatThrownBy(() -> reservaRepository.bloquearAgendaDeSucursal(UUID.randomUUID()))
        .isInstanceOf(IllegalTransactionStateException.class);
  }

  private void enTransaccion(Runnable accion) {
    new TransactionTemplate(transactionManager).executeWithoutResult(status -> accion.run());
  }

  private static void dormir(Duration duracion) {
    try {
      Thread.sleep(duracion.toMillis());
    } catch (InterruptedException e) {
      Thread.currentThread().interrupt();
      throw new IllegalStateException(e);
    }
  }
}
