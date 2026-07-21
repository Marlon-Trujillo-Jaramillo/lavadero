package com.lavadero.shared.security;

import java.util.Optional;
import java.util.UUID;

/**
 * Contenedor del tenant "actual" para el hilo de ejecución en curso.
 *
 * <p>Se puebla exclusivamente por el {@code TenantResolutionFilter} del módulo `identity-access`
 * (infraestructura de seguridad), a partir del claim {@code tenant_id} del JWT ya validado — NUNCA
 * a partir de un header arbitrario en endpoints autenticados. Vive en `shared-kernel/security`
 * porque lo consume también la capa de persistencia (interceptor que ejecuta {@code SET LOCAL
 * app.current_tenant_id}) y el filtro de Hibernate, ambos fuera de `identity-access`.
 *
 * <p>Usa {@link ThreadLocal} porque Spring MVC procesa cada request en un hilo dedicado; en un
 * modelo reactivo habría que sustituir esto por Reactor Context, pero esta fase usa Spring MVC
 * clásico (blocking).
 *
 * <p>IMPORTANTE: quien invoque {@link #set(UUID)} es responsable de llamar {@link #clear()} en un
 * bloque {@code finally}, para no filtrar el tenant de una request hacia la siguiente request que
 * reutilice el mismo hilo (p. ej. en un pool de threads del servidor).
 */
public final class TenantContext {

  private static final ThreadLocal<UUID> TENANT_ACTUAL = new ThreadLocal<>();

  private TenantContext() {}

  public static void set(UUID tenantId) {
    TENANT_ACTUAL.set(tenantId);
  }

  public static Optional<UUID> get() {
    return Optional.ofNullable(TENANT_ACTUAL.get());
  }

  public static UUID requerido() {
    return get()
        .orElseThrow(() -> new IllegalStateException("No hay tenant activo en el contexto actual"));
  }

  public static void clear() {
    TENANT_ACTUAL.remove();
  }
}
