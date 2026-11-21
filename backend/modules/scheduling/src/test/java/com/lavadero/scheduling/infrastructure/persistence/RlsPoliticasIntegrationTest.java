package com.lavadero.scheduling.infrastructure.persistence;

import static org.assertj.core.api.Assertions.assertThat;

import com.lavadero.scheduling.SchedulingTestApplication;
import java.util.List;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.test.context.DynamicPropertyRegistry;
import org.springframework.test.context.DynamicPropertySource;
import org.testcontainers.containers.PostgreSQLContainer;
import org.testcontainers.junit.jupiter.Container;
import org.testcontainers.junit.jupiter.Testcontainers;

/**
 * Guarda transversal sobre TODAS las migraciones (scheduling depende de los demás módulos y trae
 * `inventory` en test, así que aquí corren V1..VN completas): cada tabla con {@code tenant_id}
 * tiene RLS activada y forzada, y cada política usa {@code nullif(current_setting(...), '')}.
 * V16/V17 se escribieron sin ese {@code nullif} y reintrodujeron el 500 de conexiones del pool ya
 * corregido en V8-V11; este test lo habría parado.
 */
@SpringBootTest(classes = SchedulingTestApplication.class)
@Testcontainers
class RlsPoliticasIntegrationTest {

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

  @Autowired private JdbcTemplate jdbcTemplate;

  /**
   * pg_attribute y no information_schema.columns: este último solo lista tablas sobre las que el
   * rol actual (lavadero_app) tiene algún privilegio, así que una tabla nueva sin su GRANT se
   * escaparía del chequeo.
   */
  @Test
  void todaTablaConTenantIdTieneRlsActivadaYForzada() {
    List<String> sinRls =
        jdbcTemplate.queryForList(
            """
            select c.relname
            from pg_class c
            join pg_namespace n on n.oid = c.relnamespace
            join pg_attribute a on a.attrelid = c.oid
            where n.nspname = 'public'
              and c.relkind in ('r', 'p')
              and a.attname = 'tenant_id'
              and a.attnum > 0
              and not a.attisdropped
              and not (c.relrowsecurity and c.relforcerowsecurity)
            """,
            String.class);

    assertThat(sinRls).as("tablas con tenant_id sin ENABLE + FORCE RLS").isEmpty();
  }

  @Test
  void todaPoliticaToleraElResetDelSettingACadenaVacia() {
    List<String> politicasSinNullif =
        jdbcTemplate.queryForList(
            """
            select tablename || '.' || policyname
            from pg_policies
            where schemaname = 'public'
              and qual like '%app.current_tenant_id%'
              and qual not like '%NULLIF%' and qual not like '%nullif%'
            """,
            String.class);

    assertThat(politicasSinNullif)
        .as("políticas que castean current_setting(...)::uuid sin nullif(..., '')")
        .isEmpty();
  }
}
