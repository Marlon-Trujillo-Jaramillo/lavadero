package com.lavadero.tenant.infrastructure.persistence;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.Id;
import jakarta.persistence.Table;
import java.util.UUID;
import org.hibernate.annotations.Filter;
import org.hibernate.annotations.FilterDef;
import org.hibernate.annotations.ParamDef;

/**
 * Entidad JPA de {@code Sucursal}: primera entidad de negocio con {@code tenant_id}. Lleva DOS
 * capas de aislamiento:
 *
 * <ol>
 *   <li>Row Level Security de Postgres (V1__tenant_management.sql), la barrera "real" e
 *       infranqueable aunque la aplicación tenga un bug.
 *   <li>Este {@code @FilterDef}/{@code @Filter} de Hibernate, habilitado a nivel de sesión por
 *       {@code TenantAwareTransactionAspect} (módulo identity-access) leyendo el mismo valor de
 *       {@code TenantContext} — defensa en profundidad, no la única barrera.
 * </ol>
 *
 * <p>El {@code @FilterDef} de aquí es la ÚNICA declaración de {@code tenantFilter} en toda la app:
 * las demás entidades tenant-scoped ({@code UsuarioJpaEntity}, {@code ServicioJpaEntity}, {@code
 * ReservaJpaEntity}) solo la referencian con {@code @Filter} (sin repetir {@code @FilterDef}) —
 * Hibernate rechaza en arranque que dos entidades del mismo persistence unit definan un filtro con
 * el mismo nombre.
 */
@Entity
@Table(name = "sucursal")
@FilterDef(name = "tenantFilter", parameters = @ParamDef(name = "tenantId", type = UUID.class))
@Filter(name = "tenantFilter", condition = "tenant_id = :tenantId")
public class SucursalJpaEntity {

  @Id private UUID id;

  @Column(name = "tenant_id", nullable = false)
  private UUID tenantId;

  @Column(nullable = false)
  private String nombre;

  private String direccion;

  @Column(name = "capacidad_simultanea", nullable = false)
  private int capacidadSimultanea;

  protected SucursalJpaEntity() {}

  public SucursalJpaEntity(
      UUID id, UUID tenantId, String nombre, String direccion, int capacidadSimultanea) {
    this.id = id;
    this.tenantId = tenantId;
    this.nombre = nombre;
    this.direccion = direccion;
    this.capacidadSimultanea = capacidadSimultanea;
  }

  public UUID getId() {
    return id;
  }

  public UUID getTenantId() {
    return tenantId;
  }

  public String getNombre() {
    return nombre;
  }

  public String getDireccion() {
    return direccion;
  }

  public int getCapacidadSimultanea() {
    return capacidadSimultanea;
  }
}
