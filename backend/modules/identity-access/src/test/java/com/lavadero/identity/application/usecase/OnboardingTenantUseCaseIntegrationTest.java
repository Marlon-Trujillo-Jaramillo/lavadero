package com.lavadero.identity.application.usecase;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;

import com.lavadero.identity.IdentityAccessTestApplication;
import com.lavadero.identity.application.TokenIssuer;
import com.lavadero.identity.application.command.OnboardingTenantCommand;
import com.lavadero.identity.application.dto.AuthResultDto;
import com.lavadero.identity.application.port.TokenService;
import com.lavadero.identity.domain.model.Usuario;
import com.lavadero.identity.infrastructure.security.PasswordEncoderConfig;
import com.lavadero.identity.infrastructure.security.TenantAwareTransactionAspect;
import com.lavadero.identity.infrastructure.security.TransactionManagementConfig;
import com.lavadero.shared.application.exception.ValidationException;
import com.lavadero.tenant.application.usecase.CrearTenantUseCase;
import java.sql.Connection;
import java.sql.DriverManager;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.time.Duration;
import java.util.UUID;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.boot.test.context.TestConfiguration;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Import;
import org.springframework.test.context.DynamicPropertyRegistry;
import org.springframework.test.context.DynamicPropertySource;
import org.testcontainers.containers.PostgreSQLContainer;
import org.testcontainers.junit.jupiter.Container;
import org.testcontainers.junit.jupiter.Testcontainers;

/**
 * Alta self-service de un lavadero contra Postgres real (RLS incluida): crea tenant, sucursal
 * principal y primer ADMIN_TENANT en una sola transacción, y si algo falla no deja nada a medias.
 *
 * <p>Los conteos de verificación se hacen con el rol superusuario del contenedor (que se salta RLS
 * a propósito) para ver TODAS las filas, no solo las del tenant en contexto.
 */
@SpringBootTest(classes = IdentityAccessTestApplication.class)
@Import({
  TransactionManagementConfig.class,
  TenantAwareTransactionAspect.class,
  TokenIssuer.class,
  PasswordEncoderConfig.class,
  CrearTenantUseCase.class,
  OnboardingTenantUseCase.class,
  OnboardingTenantUseCaseIntegrationTest.TokenServiceDePrueba.class
})
@Testcontainers
class OnboardingTenantUseCaseIntegrationTest {

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

  @Autowired private OnboardingTenantUseCase onboarding;

  @Test
  void creaLavaderoSucursalYAdministradorJuntos() throws Exception {
    String slug = slugUnico();

    AuthResultDto resultado = onboarding.execute(comando(slug, "Dueña@Lavadero.com"));

    UUID tenantId = resultado.usuario().tenantId();
    assertThat(resultado.accessToken()).isNotBlank();
    assertThat(resultado.refreshToken()).isNotBlank();
    assertThat(resultado.usuario().roles()).containsExactly("ADMIN_TENANT");
    assertThat(resultado.usuario().email()).isEqualTo("dueña@lavadero.com");
    assertThat(contar("select count(*) from tenant where slug = ?", slug)).isEqualTo(1);
    assertThat(contar("select count(*) from sucursal where tenant_id = ?", tenantId)).isEqualTo(1);
    assertThat(contar("select count(*) from usuario where tenant_id = ?", tenantId)).isEqualTo(1);
  }

  @Test
  void unSlugRepetidoNoDejaNadaAMedias() throws Exception {
    String slug = slugUnico();
    onboarding.execute(comando(slug, "primera@lavadero.com"));

    assertThatThrownBy(() -> onboarding.execute(comando(slug, "segunda@lavadero.com")))
        .isInstanceOf(ValidationException.class)
        .hasMessageContaining(slug);

    assertThat(contar("select count(*) from tenant where slug = ?", slug)).isEqualTo(1);
    assertThat(contar("select count(*) from usuario where email = ?", "segunda@lavadero.com"))
        .isZero();
  }

  @Test
  void cadaAltaEsUnLavaderoIndependiente() throws Exception {
    UUID a = onboarding.execute(comando(slugUnico(), "a@lavadero.com")).usuario().tenantId();
    UUID b = onboarding.execute(comando(slugUnico(), "b@lavadero.com")).usuario().tenantId();

    assertThat(a).isNotEqualTo(b);
    assertThat(contar("select count(*) from usuario where tenant_id = ?", a)).isEqualTo(1);
    assertThat(contar("select count(*) from usuario where tenant_id = ?", b)).isEqualTo(1);
  }

  private static OnboardingTenantCommand comando(String slug, String email) {
    return new OnboardingTenantCommand(
        "Lavadero " + slug, "900123456-" + slug.length(), slug, email, "clave-segura-1", "Dueña");
  }

  private static String slugUnico() {
    return "lavadero-" + UUID.randomUUID().toString().substring(0, 8);
  }

  /** Cuenta como superusuario del contenedor: ve todas las filas, sin RLS. */
  private static long contar(String sql, Object parametro) throws Exception {
    try (Connection c =
            DriverManager.getConnection(
                POSTGRES.getJdbcUrl(), POSTGRES.getUsername(), POSTGRES.getPassword());
        PreparedStatement ps = c.prepareStatement(sql)) {
      ps.setObject(1, parametro);
      try (ResultSet rs = ps.executeQuery()) {
        rs.next();
        return rs.getLong(1);
      }
    }
  }
}
