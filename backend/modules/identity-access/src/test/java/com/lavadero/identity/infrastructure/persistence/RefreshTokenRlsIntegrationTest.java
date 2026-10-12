package com.lavadero.identity.infrastructure.persistence;

import static org.assertj.core.api.Assertions.assertThat;

import com.lavadero.identity.IdentityAccessTestApplication;
import com.lavadero.identity.domain.model.RefreshToken;
import com.lavadero.identity.domain.model.Rol;
import com.lavadero.identity.domain.model.Usuario;
import com.lavadero.identity.domain.model.UsuarioEstado;
import com.lavadero.identity.domain.repository.RefreshTokenRepository;
import com.lavadero.identity.domain.repository.UsuarioRepository;
import com.lavadero.tenant.domain.model.Tenant;
import com.lavadero.tenant.domain.repository.TenantRepository;
import java.time.Instant;
import java.util.EnumSet;
import java.util.UUID;
import java.util.function.Supplier;
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
 * Prueba la política RLS de `refresh_token` (V12__refresh_token_rls.sql) — la tabla que hasta esta
 * migración tenía `tenant_id` pero CERO aislamiento a nivel de base de datos, la única excepción al
 * modelo de seguridad declarado en ADR 0001. Mismo patrón que {@code UsuarioRlsIntegrationTest}.
 *
 * <p>Usa {@link RefreshTokenRepository#findByTokenHash(String)} deliberadamente: no añade
 * `tenantId` como predicado en Java/JPQL, así que si RLS fallara, un hash válido de otro tenant
 * sería encontrable igual.
 */
@SpringBootTest(classes = IdentityAccessTestApplication.class)
@Testcontainers
class RefreshTokenRlsIntegrationTest {

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
  }

  @Autowired private TenantRepository tenantRepository;
  @Autowired private UsuarioRepository usuarioRepository;
  @Autowired private RefreshTokenRepository refreshTokenRepository;
  @Autowired private JdbcTemplate jdbcTemplate;
  @Autowired private PlatformTransactionManager transactionManager;

  @Test
  void unRefreshTokenDeUnTenantEsInvisibleParaOtroTenant() {
    UUID tenantA = crearTenant("Lavadero A");
    UUID tenantB = crearTenant("Lavadero B");

    Usuario usuarioA = adminDe(tenantA);
    Usuario usuarioB = adminDe(tenantB);
    comoTenant(tenantA, () -> usuarioRepository.save(usuarioA));
    comoTenant(tenantB, () -> usuarioRepository.save(usuarioB));

    RefreshToken tokenA =
        RefreshToken.nuevo(
            usuarioA.getId(),
            tenantA,
            "hash-a-" + UUID.randomUUID(),
            Instant.now().plusSeconds(3600));
    RefreshToken tokenB =
        RefreshToken.nuevo(
            usuarioB.getId(),
            tenantB,
            "hash-b-" + UUID.randomUUID(),
            Instant.now().plusSeconds(3600));
    comoTenant(tenantA, () -> refreshTokenRepository.save(tokenA));
    comoTenant(tenantB, () -> refreshTokenRepository.save(tokenB));

    assertThat(
            comoTenant(
                tenantA, () -> refreshTokenRepository.findByTokenHash(tokenB.getTokenHash())))
        .isEmpty();
    assertThat(
            comoTenant(
                tenantA, () -> refreshTokenRepository.findByTokenHash(tokenA.getTokenHash())))
        .isPresent();

    assertThat(
            comoTenant(
                tenantB, () -> refreshTokenRepository.findByTokenHash(tokenA.getTokenHash())))
        .isEmpty();
    assertThat(
            comoTenant(
                tenantB, () -> refreshTokenRepository.findByTokenHash(tokenB.getTokenHash())))
        .isPresent();
  }

  private Usuario adminDe(UUID tenantId) {
    return new Usuario(
        UUID.randomUUID(),
        tenantId,
        "admin-" + UUID.randomUUID() + "@lavadero.com",
        "Admin de prueba",
        "hash",
        EnumSet.of(Rol.ADMIN_TENANT),
        false,
        UsuarioEstado.ACTIVO,
        null);
  }

  private UUID crearTenant(String nombre) {
    Tenant tenant =
        Tenant.nuevo(nombre, "NIT-" + UUID.randomUUID(), slugUnico(nombre), PLAN_STARTER_ID);
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

  private static String slugUnico(String prefijo) {
    return prefijo.toLowerCase().replace(" ", "-")
        + "-"
        + UUID.randomUUID().toString().substring(0, 8);
  }
}
