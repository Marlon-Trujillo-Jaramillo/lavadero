package com.lavadero.identity.infrastructure.persistence;

import static org.assertj.core.api.Assertions.assertThat;

import com.lavadero.identity.IdentityAccessTestApplication;
import com.lavadero.identity.domain.model.Rol;
import com.lavadero.identity.domain.model.Usuario;
import com.lavadero.identity.domain.model.UsuarioEstado;
import com.lavadero.identity.domain.repository.UsuarioRepository;
import com.lavadero.tenant.domain.model.Tenant;
import com.lavadero.tenant.domain.repository.TenantRepository;
import jakarta.persistence.EntityManagerFactory;
import java.util.EnumSet;
import java.util.List;
import java.util.UUID;
import java.util.function.Supplier;
import org.hibernate.SessionFactory;
import org.hibernate.stat.Statistics;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.test.context.DynamicPropertyRegistry;
import org.springframework.test.context.DynamicPropertySource;
import org.springframework.transaction.PlatformTransactionManager;
import org.springframework.transaction.support.TransactionTemplate;
import org.testcontainers.containers.PostgreSQLContainer;
import org.testcontainers.junit.jupiter.Container;
import org.testcontainers.junit.jupiter.Testcontainers;

/**
 * Regresión de N+1: listar los empleados de un lavadero no debe hacer una consulta extra por cada
 * empleado para cargar sus roles ({@code @ElementCollection} de {@link UsuarioJpaEntity}). Con
 * {@code @BatchSize} los roles de todos se cargan en un solo lote, así que el número de sentencias
 * SQL no crece con el número de empleados.
 */
@SpringBootTest(classes = IdentityAccessTestApplication.class)
@Testcontainers
class EmpleadosConsultasIntegrationTest {

  private static final UUID PLAN_STARTER_ID =
      UUID.fromString("00000000-0000-0000-0000-000000000001");
  private static final int EMPLEADOS = 8;

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
    registry.add("spring.jpa.properties.hibernate.generate_statistics", () -> "true");
  }

  @Autowired private TenantRepository tenantRepository;
  @Autowired private UsuarioRepository usuarioRepository;
  @Autowired private JdbcTemplate jdbcTemplate;
  @Autowired private PlatformTransactionManager transactionManager;
  @Autowired private EntityManagerFactory entityManagerFactory;

  @Test
  void listarEmpleadosNoHaceUnaConsultaPorEmpleado() {
    UUID tenant = crearTenant();
    for (int i = 0; i < EMPLEADOS; i++) {
      Usuario empleado = empleadoDe(tenant, i);
      comoTenant(tenant, () -> usuarioRepository.save(empleado));
    }

    Statistics stats = entityManagerFactory.unwrap(SessionFactory.class).getStatistics();
    stats.clear();

    List<Usuario> empleados =
        comoTenant(tenant, () -> usuarioRepository.findEmpleadosDelTenantActual(null));

    assertThat(empleados).hasSize(EMPLEADOS);
    assertThat(empleados).allSatisfy(e -> assertThat(e.getRoles()).contains(Rol.EMPLEADO));
    // 1 consulta de usuarios + 1 lote de roles. Con N+1 serían 1 + EMPLEADOS.
    assertThat(stats.getPrepareStatementCount()).isLessThanOrEqualTo(2);
  }

  private Usuario empleadoDe(UUID tenantId, int i) {
    return new Usuario(
        UUID.randomUUID(),
        tenantId,
        "empleado-" + i + "-" + UUID.randomUUID() + "@lavadero.com",
        "Empleado " + i,
        "hash",
        EnumSet.of(Rol.EMPLEADO),
        false,
        UsuarioEstado.ACTIVO,
        null);
  }

  private UUID crearTenant() {
    String slug = "lavadero-" + UUID.randomUUID().toString().substring(0, 8);
    Tenant tenant = Tenant.nuevo("Lavadero", "NIT-" + UUID.randomUUID(), slug, PLAN_STARTER_ID);
    tenantRepository.save(tenant);
    return tenant.getId();
  }

  private <T> T comoTenant(UUID tenantId, Supplier<T> accion) {
    return new TransactionTemplate(transactionManager)
        .execute(
            status -> {
              jdbcTemplate.queryForObject(
                  "SELECT set_config('app.current_tenant_id', ?, true)",
                  String.class,
                  tenantId.toString());
              return accion.get();
            });
  }
}
