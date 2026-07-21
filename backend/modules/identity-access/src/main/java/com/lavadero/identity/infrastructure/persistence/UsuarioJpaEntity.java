package com.lavadero.identity.infrastructure.persistence;

import com.lavadero.identity.domain.model.Rol;
import jakarta.persistence.CollectionTable;
import jakarta.persistence.Column;
import jakarta.persistence.ElementCollection;
import jakarta.persistence.Entity;
import jakarta.persistence.EnumType;
import jakarta.persistence.Enumerated;
import jakarta.persistence.FetchType;
import jakarta.persistence.Id;
import jakarta.persistence.JoinColumn;
import jakarta.persistence.Table;
import java.util.EnumSet;
import java.util.Set;
import java.util.UUID;
import org.hibernate.annotations.Filter;
import org.hibernate.annotations.FilterDef;
import org.hibernate.annotations.ParamDef;

/**
 * Entidad JPA de {@code Usuario}. Igual que {@code SucursalJpaEntity} (tenant-management), lleva
 * DOS capas de aislamiento:
 *
 * <ol>
 *   <li>Row Level Security de Postgres (V2__identity_access.sql).
 *   <li>Este {@code @FilterDef}/{@code @Filter} de Hibernate, habilitado a nivel de sesión por
 *       {@code TenantAwareTransactionAspect}.
 * </ol>
 *
 * <p>A diferencia de Sucursal, {@code tenantId} es NULLABLE (solo nulo para SUPER_ADMIN, ver
 * comentario de diseño en {@code Usuario} y en la política RLS de la migración): tanto el filtro de
 * Hibernate como la política RLS solo se activan cuando hay un tenant vigente en {@code
 * TenantContext}; las consultas de plataforma (sin tenant) no habilitan el filtro, igual que la
 * política SQL no exige tenant para ver las filas con {@code tenant_id IS NULL}.
 */
@Entity
@Table(name = "usuario")
@FilterDef(name = "tenantFilter", parameters = @ParamDef(name = "tenantId", type = UUID.class))
@Filter(name = "tenantFilter", condition = "tenant_id = :tenantId")
public class UsuarioJpaEntity {

  @Id private UUID id;

  @Column(name = "tenant_id")
  private UUID tenantId;

  @Column(nullable = false)
  private String email;

  @Column(nullable = false)
  private String nombre;

  @Column(name = "password_hash", nullable = false)
  private String passwordHash;

  @ElementCollection(fetch = FetchType.EAGER)
  @CollectionTable(name = "usuario_rol", joinColumns = @JoinColumn(name = "usuario_id"))
  @Column(name = "rol", nullable = false)
  @Enumerated(EnumType.STRING)
  private Set<Rol> roles = EnumSet.noneOf(Rol.class);

  @Column(name = "mfa_enabled", nullable = false)
  private boolean mfaEnabled;

  @Column(nullable = false)
  private String estado;

  @Column(name = "sucursal_id")
  private UUID sucursalId;

  protected UsuarioJpaEntity() {}

  public UsuarioJpaEntity(
      UUID id,
      UUID tenantId,
      String email,
      String nombre,
      String passwordHash,
      Set<Rol> roles,
      boolean mfaEnabled,
      String estado,
      UUID sucursalId) {
    this.id = id;
    this.tenantId = tenantId;
    this.email = email;
    this.nombre = nombre;
    this.passwordHash = passwordHash;
    this.roles =
        roles == null || roles.isEmpty() ? EnumSet.noneOf(Rol.class) : EnumSet.copyOf(roles);
    this.mfaEnabled = mfaEnabled;
    this.estado = estado;
    this.sucursalId = sucursalId;
  }

  public UUID getId() {
    return id;
  }

  public UUID getTenantId() {
    return tenantId;
  }

  public String getEmail() {
    return email;
  }

  public String getNombre() {
    return nombre;
  }

  public String getPasswordHash() {
    return passwordHash;
  }

  public Set<Rol> getRoles() {
    return roles;
  }

  public boolean isMfaEnabled() {
    return mfaEnabled;
  }

  public String getEstado() {
    return estado;
  }

  public UUID getSucursalId() {
    return sucursalId;
  }
}
