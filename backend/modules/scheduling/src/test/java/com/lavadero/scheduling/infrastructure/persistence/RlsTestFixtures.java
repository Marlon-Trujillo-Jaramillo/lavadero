package com.lavadero.scheduling.infrastructure.persistence;

import java.sql.Timestamp;
import java.time.Instant;
import java.util.UUID;
import java.util.function.Supplier;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.transaction.PlatformTransactionManager;
import org.springframework.transaction.support.TransactionTemplate;

/**
 * Fixtures compartidos entre los tests de integración de este módulo: inserta tenant/sucursal/
 * servicio/usuario directo por SQL (esas tablas son de otros módulos, no disponibles como
 * repositorios/beans en el contexto de test aislado de `scheduling` — ver {@code
 * SchedulingTestApplication}).
 */
final class RlsTestFixtures {

  private static final UUID PLAN_STARTER_ID =
      UUID.fromString("00000000-0000-0000-0000-000000000001");

  private final JdbcTemplate jdbcTemplate;
  private final PlatformTransactionManager transactionManager;

  RlsTestFixtures(JdbcTemplate jdbcTemplate, PlatformTransactionManager transactionManager) {
    this.jdbcTemplate = jdbcTemplate;
    this.transactionManager = transactionManager;
  }

  /**
   * Igual al {@code comoTenant} de {@code SucursalRlsIntegrationTest}/{@code
   * ServicioRlsIntegrationTest}: fija {@code app.current_tenant_id} con alcance de la transacción
   * actual y ejecuta la acción dentro de ella.
   */
  <T> T comoTenant(UUID tenantId, Supplier<T> accion) {
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

  /** `tenant` no tiene RLS (dato de plataforma) — el insert no necesita {@link #comoTenant}. */
  UUID crearTenant(String nombre) {
    UUID id = UUID.randomUUID();
    jdbcTemplate.update(
        "insert into tenant (id, nombre, nit, slug, estado, subscription_plan_id, fecha_creacion) "
            + "values (?, ?, ?, ?, 'ACTIVO', ?, now())",
        id,
        nombre,
        "NIT-" + UUID.randomUUID(),
        "slug-" + UUID.randomUUID().toString().substring(0, 8),
        PLAN_STARTER_ID);
    return id;
  }

  /**
   * `sucursal`/`servicio`/`usuario` SÍ tienen RLS+FORCE — el insert debe correr con el tenant ya
   * fijado.
   */
  UUID crearSucursal(UUID tenantId) {
    UUID id = UUID.randomUUID();
    comoTenant(
        tenantId,
        () ->
            jdbcTemplate.update(
                "insert into sucursal (id, tenant_id, nombre, capacidad_simultanea) values (?, ?, 'Principal', 1)",
                id,
                tenantId));
    return id;
  }

  UUID crearServicio(UUID tenantId, String nombre) {
    UUID id = UUID.randomUUID();
    comoTenant(
        tenantId,
        () ->
            jdbcTemplate.update(
                "insert into servicio (id, tenant_id, nombre, duracion_estimada_minutos, precio, moneda, activo) "
                    + "values (?, ?, ?, 20, 15000, 'COP', true)",
                id,
                tenantId,
                nombre));
    return id;
  }

  /** `reserva` SÍ tiene RLS+FORCE — usada como fixture por los tests de checklist/incidencia. */
  UUID crearReserva(UUID tenantId, UUID sucursalId, UUID servicioId, UUID clienteId) {
    UUID id = UUID.randomUUID();
    comoTenant(
        tenantId,
        () ->
            jdbcTemplate.update(
                "insert into reserva (id, tenant_id, sucursal_id, servicio_id, cliente_id, "
                    + "fecha_hora_inicio, fecha_hora_fin, duracion_estimada_minutos, precio, moneda, estado) "
                    + "values (?, ?, ?, ?, ?, ?, ?, 20, 15000, 'COP', 'PENDIENTE')",
                id,
                tenantId,
                sucursalId,
                servicioId,
                clienteId,
                Timestamp.from(Instant.parse("2026-08-01T10:00:00Z")),
                Timestamp.from(Instant.parse("2026-08-01T10:20:00Z"))));
    return id;
  }

  UUID crearUsuario(UUID tenantId) {
    UUID id = UUID.randomUUID();
    comoTenant(
        tenantId,
        () ->
            jdbcTemplate.update(
                "insert into usuario (id, tenant_id, email, nombre, password_hash, estado) "
                    + "values (?, ?, ?, 'Cliente de prueba', 'hash', 'ACTIVO')",
                id,
                tenantId,
                "cliente-" + UUID.randomUUID() + "@example.com"));
    return id;
  }
}
