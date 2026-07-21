package com.lavadero.identity.infrastructure.security;

import com.lavadero.shared.security.TenantContext;
import jakarta.persistence.EntityManager;
import jakarta.persistence.PersistenceContext;
import java.util.Optional;
import java.util.UUID;
import org.aspectj.lang.ProceedingJoinPoint;
import org.aspectj.lang.annotation.Around;
import org.aspectj.lang.annotation.Aspect;
import org.hibernate.Session;
import org.springframework.core.annotation.Order;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.stereotype.Component;

/**
 * Segunda barrera de aislamiento multi-tenant (defensa en profundidad), complementaria a la
 * política RLS de Postgres:
 *
 * <ol>
 *   <li>Ejecuta {@code SELECT set_config('app.current_tenant_id', ?, true)} (equivalente
 *       parametrizado y seguro de {@code SET LOCAL}) al entrar a cada método {@code @Transactional}
 *       de negocio, leyendo el valor vigente de {@link TenantContext}. El tercer argumento {@code
 *       true} de {@code set_config} equivale al {@code true} de {@code current_setting(..., true)}
 *       usado en las políticas RLS: hace que el valor sea local a la transacción actual (como
 *       {@code SET LOCAL}), sin persistir en la sesión.
 *   <li>Habilita el filtro de Hibernate {@code tenantFilter} (ver {@code @FilterDef} en {@code
 *       SucursalJpaEntity}) con el mismo tenantId, para que incluso si una consulta JPQL/Criteria
 *       olvidara filtrar por tenant, Hibernate añada la condición igualmente.
 * </ol>
 *
 * <p>Si {@link TenantContext} está vacío (operaciones de plataforma, p. ej. SUPER_ADMIN
 * listando/creando tenants), NO se setea nada: {@code current_setting(..., true)} en Postgres
 * retorna NULL en vez de fallar, y el filtro de Hibernate simplemente no se activa. Esto es
 * intencional para no romper flujos sin tenant.
 *
 * <p>Se ejecuta en CADA método {@code @Transactional} (no solo en el de más alto nivel): esto es
 * necesario para el flujo de onboarding de un tenant nuevo (`CrearTenantUseCase`), donde el tenant
 * recién creado se setea en {@code TenantContext} DESPUÉS de que la transacción ya inició; al
 * llamar al adaptador de persistencia de `Sucursal` (un bean distinto, también anotado
 * {@code @Transactional}), este aspecto vuelve a ejecutarse y aplica el `SET LOCAL` con el valor ya
 * actualizado, justo antes del INSERT.
 */
@Aspect
@Component
@Order(101) // Debe ejecutarse DESPUÉS del advisor @Transactional (order 100, ver
// TransactionManagementConfig)
public class TenantAwareTransactionAspect {

  private final JdbcTemplate jdbcTemplate;

  @PersistenceContext private EntityManager entityManager;

  public TenantAwareTransactionAspect(JdbcTemplate jdbcTemplate) {
    this.jdbcTemplate = jdbcTemplate;
  }

  @Around(
      "@annotation(org.springframework.transaction.annotation.Transactional) "
          + "|| @within(org.springframework.transaction.annotation.Transactional)")
  public Object aplicarTenantActual(ProceedingJoinPoint joinPoint) throws Throwable {
    Optional<UUID> tenantId = TenantContext.get();
    if (tenantId.isPresent()) {
      fijarTenantEnSesionSql(tenantId.get());
      habilitarFiltroHibernate(tenantId.get());
    }
    return joinPoint.proceed();
  }

  private void fijarTenantEnSesionSql(UUID tenantId) {
    jdbcTemplate.queryForObject(
        "SELECT set_config('app.current_tenant_id', ?, true)", String.class, tenantId.toString());
  }

  private void habilitarFiltroHibernate(UUID tenantId) {
    Session session = entityManager.unwrap(Session.class);
    if (session.getEnabledFilter("tenantFilter") == null) {
      session.enableFilter("tenantFilter").setParameter("tenantId", tenantId);
    }
  }
}
