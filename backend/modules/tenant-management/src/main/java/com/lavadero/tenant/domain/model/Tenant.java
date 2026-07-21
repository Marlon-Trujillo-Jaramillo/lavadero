package com.lavadero.tenant.domain.model;

import com.lavadero.shared.domain.AggregateRoot;
import java.time.Instant;
import java.util.Objects;
import java.util.UUID;
import java.util.regex.Pattern;

/**
 * Aggregate root de plataforma: representa un negocio (lavadero) que contrata el SaaS. A diferencia
 * de las entidades de negocio de los demás módulos, `Tenant` NO lleva `tenant_id` (es la raíz) y
 * por tanto su tabla no tiene RLS habilitado (ver migración V1).
 */
public class Tenant extends AggregateRoot<UUID> {

  private static final Pattern SLUG_VALIDO = Pattern.compile("^[a-z0-9]+(-[a-z0-9]+)*$");

  private final String nombre;
  private final String nit;
  private final String slug;
  private TenantEstado estado;
  private UUID subscriptionPlanId;
  private final Instant fechaCreacion;

  public Tenant(
      UUID id,
      String nombre,
      String nit,
      String slug,
      TenantEstado estado,
      UUID subscriptionPlanId,
      Instant fechaCreacion) {
    super(id);
    this.nombre = requireTexto(nombre, "nombre");
    this.nit = requireTexto(nit, "nit");
    this.slug = validarSlug(slug);
    this.estado = Objects.requireNonNull(estado);
    this.subscriptionPlanId = Objects.requireNonNull(subscriptionPlanId);
    this.fechaCreacion = Objects.requireNonNull(fechaCreacion);
  }

  public static Tenant nuevo(String nombre, String nit, String slug, UUID subscriptionPlanId) {
    return new Tenant(
        UUID.randomUUID(),
        nombre,
        nit,
        slug,
        TenantEstado.ACTIVO,
        subscriptionPlanId,
        Instant.now());
  }

  private static String validarSlug(String slug) {
    String valor = requireTexto(slug, "slug");
    if (!SLUG_VALIDO.matcher(valor).matches()) {
      throw new IllegalArgumentException(
          "slug inválido: '%s'. Solo minúsculas, números y guiones simples.".formatted(valor));
    }
    return valor;
  }

  private static String requireTexto(String valor, String campo) {
    if (valor == null || valor.isBlank()) {
      throw new IllegalArgumentException("%s no puede ser vacío".formatted(campo));
    }
    return valor;
  }

  public void suspender() {
    this.estado = TenantEstado.SUSPENDIDO;
  }

  public void reactivar() {
    this.estado = TenantEstado.ACTIVO;
  }

  public boolean estaActivo() {
    return this.estado == TenantEstado.ACTIVO;
  }

  public String getNombre() {
    return nombre;
  }

  public String getNit() {
    return nit;
  }

  public String getSlug() {
    return slug;
  }

  public TenantEstado getEstado() {
    return estado;
  }

  public UUID getSubscriptionPlanId() {
    return subscriptionPlanId;
  }

  public Instant getFechaCreacion() {
    return fechaCreacion;
  }
}
