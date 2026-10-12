package com.lavadero.identity.infrastructure.persistence;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatCode;

import com.lavadero.identity.IdentityAccessTestApplication;
import com.lavadero.identity.domain.model.Rol;
import com.lavadero.identity.domain.model.Usuario;
import com.lavadero.identity.domain.model.UsuarioEstado;
import com.lavadero.identity.domain.repository.UsuarioRepository;
import com.lavadero.tenant.domain.model.Tenant;
import com.lavadero.tenant.domain.repository.TenantRepository;
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
 * Prueba la política RLS REAL (Testcontainers, sin mocks) de la tabla `usuario` — la tabla más
 * sensible del proyecto: fue la involucrada en el incidente real de julio (bypass por rol
 * superusuario) y en el bug de `set_config LOCAL` corregido por V9__fix_rls_local_setting_reset.sql
 * (SUPER_ADMIN fallando al reusar una conexión pooled). Antes de este test, ninguno de los dos
 * quedaba cubierto por CI: solo se detectaron corriendo la app real (ver memoria de sesión).
 *
 * <p>Usa {@link UsuarioRepository#findById(UUID)} deliberadamente (no {@code
 * findByEmailAndTenantId}, que SÍ añade `tenantId` como predicado explícito y por tanto no probaría
 * nada sobre RLS): {@code findById} no tiene ninguna cláusula de tenant a nivel de Java/JPQL, así
 * que si una fila cruza el aislamiento, solo puede ser porque RLS falló.
 */
@SpringBootTest(classes = IdentityAccessTestApplication.class)
@Testcontainers
class UsuarioRlsIntegrationTest {

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

    // Pool de UNA sola conexión física: fuerza que la transacción "de
    // plataforma" (comoPlataforma) de regresionPooledConnection... reuse
    // EXACTAMENTE la misma conexión que la transacción de tenant anterior,
    // reproduciendo el escenario real del bug de V9 (una conexión que ya
    // tuvo `set_config('app.current_tenant_id', ..., true)` fijado y
    // revertido a '' al terminar esa transacción, no a NULL).
    registry.add("spring.datasource.hikari.maximum-pool-size", () -> "1");
  }

  @Autowired private TenantRepository tenantRepository;
  @Autowired private UsuarioRepository usuarioRepository;
  @Autowired private JdbcTemplate jdbcTemplate;
  @Autowired private PlatformTransactionManager transactionManager;

  @Test
  void unUsuarioDeUnTenantEsInvisibleParaOtroTenant() {
    UUID tenantA = crearTenant("Lavadero A");
    UUID tenantB = crearTenant("Lavadero B");

    Usuario usuarioA = adminDe(tenantA);
    Usuario usuarioB = adminDe(tenantB);
    comoTenant(tenantA, () -> usuarioRepository.save(usuarioA));
    comoTenant(tenantB, () -> usuarioRepository.save(usuarioB));

    // findById no añade WHERE tenant_id = ... a nivel de Java: si esto
    // encuentra la fila de B estando en el contexto de A, RLS está rota.
    assertThat(comoTenant(tenantA, () -> usuarioRepository.findById(usuarioB.getId()))).isEmpty();
    assertThat(comoTenant(tenantA, () -> usuarioRepository.findById(usuarioA.getId()))).isPresent();

    assertThat(comoTenant(tenantB, () -> usuarioRepository.findById(usuarioA.getId()))).isEmpty();
    assertThat(comoTenant(tenantB, () -> usuarioRepository.findById(usuarioB.getId()))).isPresent();
  }

  @Test
  void superAdminSoloVisibleSinTenantActivo_yRegresionConexionPooled() {
    UUID tenantA = crearTenant("Lavadero A");

    // Esta transacción fija app.current_tenant_id=tenantA (SET LOCAL) y
    // COMMITEA: en la conexión física reusada por el pool de tamaño 1, el
    // valor queda en '' (no NULL) después de esto — exactamente el estado
    // que causó el bug real.
    Usuario usuarioA = adminDe(tenantA);
    comoTenant(tenantA, () -> usuarioRepository.save(usuarioA));

    Usuario superAdmin =
        new Usuario(
            UUID.randomUUID(),
            null,
            "super-" + UUID.randomUUID() + "@lavadero.com",
            "Super Admin",
            "hash",
            EnumSet.of(Rol.SUPER_ADMIN),
            false,
            UsuarioEstado.ACTIVO,
            null);

    // Sin fijar NINGÚN tenant (simula el login de un SUPER_ADMIN, sin
    // header X-Tenant-Slug), reusando la conexión de arriba: si la política
    // no tuviera el `nullif(..., '')` de V9, el INSERT fallaría (cast
    // inválido de '' a uuid) o la fila insertada quedaría inaccesible.
    assertThatCode(() -> comoPlataforma(() -> usuarioRepository.save(superAdmin)))
        .doesNotThrowAnyException();

    assertThat(comoPlataforma(() -> usuarioRepository.findById(superAdmin.getId()))).isPresent();

    // Un SUPER_ADMIN nunca debe ser visible desde el contexto de un tenant,
    // ni viceversa: los dos universos (plataforma vs. negocio) no se
    // mezclan (ver comentario de diseño en V2__identity_access.sql).
    assertThat(comoTenant(tenantA, () -> usuarioRepository.findById(superAdmin.getId()))).isEmpty();
    assertThat(comoPlataforma(() -> usuarioRepository.findById(usuarioA.getId()))).isEmpty();
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

  /** `tenant` no tiene RLS (dato de plataforma) — el insert no necesita contexto de tenant. */
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

  /**
   * Deliberadamente NO fija {@code app.current_tenant_id}: representa una request de plataforma
   * (login/lectura de un SUPER_ADMIN) sobre una conexión que puede venir de reusar una del pool
   * recién usada por un tenant normal — el escenario exacto del bug de V9.
   */
  private <T> T comoPlataforma(Supplier<T> accion) {
    TransactionTemplate transactionTemplate = new TransactionTemplate(transactionManager);
    return transactionTemplate.execute(status -> accion.get());
  }

  private static String slugUnico(String prefijo) {
    return prefijo.toLowerCase().replace(" ", "-")
        + "-"
        + UUID.randomUUID().toString().substring(0, 8);
  }
}
