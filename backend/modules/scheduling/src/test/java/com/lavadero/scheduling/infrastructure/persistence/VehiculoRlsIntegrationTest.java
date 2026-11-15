package com.lavadero.scheduling.infrastructure.persistence;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;

import com.lavadero.scheduling.SchedulingTestApplication;
import com.lavadero.scheduling.domain.model.Placa;
import com.lavadero.scheduling.domain.model.TipoVehiculo;
import com.lavadero.scheduling.domain.model.Vehiculo;
import com.lavadero.scheduling.domain.repository.VehiculoRepository;
import java.util.UUID;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.dao.DataIntegrityViolationException;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.test.context.DynamicPropertyRegistry;
import org.springframework.test.context.DynamicPropertySource;
import org.springframework.transaction.PlatformTransactionManager;
import org.testcontainers.containers.PostgreSQLContainer;
import org.testcontainers.junit.jupiter.Container;
import org.testcontainers.junit.jupiter.Testcontainers;

/** Tabla `vehiculo` (V22): aislamiento por tenant y placa activa única por cliente. */
@SpringBootTest(classes = SchedulingTestApplication.class)
@Testcontainers
class VehiculoRlsIntegrationTest {

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

  @Autowired private VehiculoRepository vehiculoRepository;
  @Autowired private JdbcTemplate jdbcTemplate;
  @Autowired private PlatformTransactionManager transactionManager;

  private RlsTestFixtures fixtures;

  @BeforeEach
  void setUp() {
    fixtures = new RlsTestFixtures(jdbcTemplate, transactionManager);
  }

  @Test
  void unTenantNuncaVeLosVehiculosDeOtroTenant() {
    UUID tenantA = fixtures.crearTenant("Lavadero A");
    UUID clienteA = fixtures.crearUsuario(tenantA);
    UUID tenantB = fixtures.crearTenant("Lavadero B");
    UUID clienteB = fixtures.crearUsuario(tenantB);
    Vehiculo deA = vehiculo(tenantA, clienteA, "AAA111");
    Vehiculo deB = vehiculo(tenantB, clienteB, "BBB222");
    fixtures.comoTenant(tenantA, () -> vehiculoRepository.save(deA));
    fixtures.comoTenant(tenantB, () -> vehiculoRepository.save(deB));

    assertThat(fixtures.comoTenant(tenantA, () -> vehiculoRepository.findById(deB.getId())))
        .isEmpty();
    assertThat(
            fixtures.comoTenant(tenantA, () -> vehiculoRepository.findActivosByClienteId(clienteA)))
        .extracting(Vehiculo::getId)
        .containsExactly(deA.getId());
  }

  @Test
  void unClienteNoPuedeTenerDosVehiculosActivosConLaMismaPlaca() {
    UUID tenant = fixtures.crearTenant("Lavadero");
    UUID cliente = fixtures.crearUsuario(tenant);
    fixtures.comoTenant(tenant, () -> vehiculoRepository.save(vehiculo(tenant, cliente, "ABC123")));

    assertThatThrownBy(
            () ->
                fixtures.comoTenant(
                    tenant, () -> vehiculoRepository.save(vehiculo(tenant, cliente, "ABC123"))))
        .isInstanceOf(DataIntegrityViolationException.class);
  }

  @Test
  void trasArchivarloPuedeVolverARegistrarLaMismaPlaca() {
    UUID tenant = fixtures.crearTenant("Lavadero");
    UUID cliente = fixtures.crearUsuario(tenant);
    Vehiculo primero = vehiculo(tenant, cliente, "ABC123");
    fixtures.comoTenant(tenant, () -> vehiculoRepository.save(primero));

    primero.archivar();
    fixtures.comoTenant(tenant, () -> vehiculoRepository.save(primero));
    fixtures.comoTenant(tenant, () -> vehiculoRepository.save(vehiculo(tenant, cliente, "ABC123")));

    assertThat(
            fixtures.comoTenant(tenant, () -> vehiculoRepository.findActivosByClienteId(cliente)))
        .hasSize(1);
    assertThat(
            fixtures.comoTenant(
                tenant,
                () -> vehiculoRepository.existeActivoConPlaca(cliente, Placa.de("abc-123"))))
        .isTrue();
  }

  private static Vehiculo vehiculo(UUID tenant, UUID cliente, String placa) {
    return Vehiculo.nuevo(tenant, cliente, Placa.de(placa), TipoVehiculo.AUTOMOVIL, null, null);
  }
}
