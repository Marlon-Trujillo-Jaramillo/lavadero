package com.lavadero.identity.application.usecase;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;

import com.lavadero.identity.IdentityAccessTestApplication;
import com.lavadero.identity.application.TokenHasher;
import com.lavadero.identity.application.TokenIssuer;
import com.lavadero.identity.application.command.RefreshTokenCommand;
import com.lavadero.identity.application.dto.AuthResultDto;
import com.lavadero.identity.application.port.TokenService;
import com.lavadero.identity.domain.model.RefreshToken;
import com.lavadero.identity.domain.model.Rol;
import com.lavadero.identity.domain.model.Usuario;
import com.lavadero.identity.domain.model.UsuarioEstado;
import com.lavadero.identity.domain.repository.RefreshTokenRepository;
import com.lavadero.identity.domain.repository.UsuarioRepository;
import com.lavadero.identity.infrastructure.security.TenantAwareTransactionAspect;
import com.lavadero.identity.infrastructure.security.TransactionManagementConfig;
import com.lavadero.shared.application.exception.ForbiddenException;
import com.lavadero.shared.security.TenantContext;
import com.lavadero.tenant.domain.model.Tenant;
import com.lavadero.tenant.domain.repository.TenantRepository;
import java.time.Duration;
import java.util.EnumSet;
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
 * Flujo real de {@code POST /auth/refresh} contra Postgres con RLS: el endpoint es público, así que
 * el caso de uso arranca SIN {@link TenantContext}, y aun así tiene que encontrar el refresh token
 * de un usuario de tenant (la política de V12 lo oculta si no hay tenant fijado).
 *
 * <p>Importa el {@link TenantAwareTransactionAspect} real (es quien aplica {@code set_config}) y
 * solo sustituye la firma JWT, que no influye en este flujo.
 */
@SpringBootTest(classes = IdentityAccessTestApplication.class)
@Import({
  TransactionManagementConfig.class,
  TenantAwareTransactionAspect.class,
  TokenIssuer.class,
  RefreshTokenUseCase.class,
  RefreshTokenUseCaseIntegrationTest.TokenServiceDePrueba.class
})
@Testcontainers
class RefreshTokenUseCaseIntegrationTest {

  @TestConfiguration
  static class TokenServiceDePrueba {
    @Bean
    TokenService tokenService() {
      return new TokenService() {
        @Override
        public String generarAccessToken(Usuario usuario) {
          return "access-" + usuario.getId();
        }

        @Override
        public Duration duracionAccessToken() {
          return Duration.ofMinutes(15);
        }

        @Override
        public String generarRefreshTokenOpaco() {
          return UUID.randomUUID().toString().replace("-", "");
        }
      };
    }
  }

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
  @Autowired private TokenIssuer tokenIssuer;
  @Autowired private RefreshTokenUseCase refreshTokenUseCase;
  @Autowired private JdbcTemplate jdbcTemplate;
  @Autowired private PlatformTransactionManager transactionManager;

  @AfterEach
  void limpiarContexto() {
    TenantContext.clear();
  }

  @Test
  void unUsuarioDeTenantPuedeRefrescarSinTenantEnContexto() {
    UUID tenantId = crearTenant();
    Usuario usuario = adminDe(tenantId);
    AuthResultDto login = comoTenant(tenantId, () -> emitirLogin(usuario));

    AuthResultDto refrescado =
        refreshTokenUseCase.execute(new RefreshTokenCommand(login.refreshToken()));

    assertThat(refrescado.accessToken()).isNotBlank();
    assertThat(refrescado.refreshToken()).isNotEqualTo(login.refreshToken());
  }

  @Test
  void reusarUnTokenRotadoRevocaTodaLaCadenaDelUsuario() {
    UUID tenantId = crearTenant();
    Usuario usuario = adminDe(tenantId);
    AuthResultDto login = comoTenant(tenantId, () -> emitirLogin(usuario));
    AuthResultDto rotado =
        refreshTokenUseCase.execute(new RefreshTokenCommand(login.refreshToken()));

    assertThatThrownBy(
            () -> refreshTokenUseCase.execute(new RefreshTokenCommand(login.refreshToken())))
        .isInstanceOf(ForbiddenException.class);

    RefreshToken vigenteAntes =
        comoTenant(
                tenantId, () -> refreshTokenRepository.findByTokenHash(sha(rotado.refreshToken())))
            .orElseThrow();
    assertThat(vigenteAntes.isRevocado())
        .as("la revocación por reuso debe persistir aunque se lance la excepción")
        .isTrue();
  }

  private AuthResultDto emitirLogin(Usuario usuario) {
    usuarioRepository.save(usuario);
    return tokenIssuer.emitirParNuevo(usuario);
  }

  private static String sha(String token) {
    return TokenHasher.sha256(token);
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
