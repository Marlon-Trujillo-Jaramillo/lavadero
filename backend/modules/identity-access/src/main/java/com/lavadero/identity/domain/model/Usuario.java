package com.lavadero.identity.domain.model;

import com.lavadero.shared.domain.AggregateRoot;
import java.util.EnumSet;
import java.util.Objects;
import java.util.Optional;
import java.util.Set;
import java.util.UUID;

/**
 * Aggregate root de identidad. {@code tenantId} es nullable: SOLO es nulo para usuarios con rol
 * {@link Rol#SUPER_ADMIN} (cuentas de plataforma, sin negocio asociado). Ver comentario de diseño
 * en V2__identity_access.sql sobre cómo esto interactúa con RLS.
 */
public class Usuario extends AggregateRoot<UUID> {

  private final UUID tenantId;
  private final String email;
  private String nombre;
  private String passwordHash;
  private Set<Rol> roles;
  private boolean mfaEnabled;
  private UsuarioEstado estado;
  private UUID sucursalId;

  public Usuario(
      UUID id,
      UUID tenantId,
      String email,
      String nombre,
      String passwordHash,
      Set<Rol> roles,
      boolean mfaEnabled,
      UsuarioEstado estado,
      UUID sucursalId) {
    super(id);
    this.email = requireEmail(email);
    this.nombre = nombre;
    this.passwordHash = Objects.requireNonNull(passwordHash);
    this.roles = EnumSet.copyOf(requireRolesNoVacios(roles));
    this.mfaEnabled = mfaEnabled;
    this.estado = Objects.requireNonNull(estado);
    this.sucursalId = sucursalId;

    boolean esSuperAdmin = this.roles.contains(Rol.SUPER_ADMIN);
    if (esSuperAdmin && tenantId != null) {
      throw new IllegalArgumentException("Un SUPER_ADMIN no puede tener tenantId");
    }
    if (!esSuperAdmin && tenantId == null) {
      throw new IllegalArgumentException("Solo un SUPER_ADMIN puede tener tenantId nulo");
    }
    this.tenantId = tenantId;
  }

  public static Usuario cliente(UUID tenantId, String email, String nombre, String passwordHash) {
    return new Usuario(
        UUID.randomUUID(),
        Objects.requireNonNull(tenantId),
        email,
        nombre,
        passwordHash,
        EnumSet.of(Rol.CLIENTE),
        false,
        UsuarioEstado.ACTIVO,
        null);
  }

  private static String requireEmail(String email) {
    if (email == null || !email.contains("@")) {
      throw new IllegalArgumentException("email inválido");
    }
    return email.toLowerCase();
  }

  private static Set<Rol> requireRolesNoVacios(Set<Rol> roles) {
    if (roles == null || roles.isEmpty()) {
      throw new IllegalArgumentException("un usuario debe tener al menos un rol");
    }
    return roles;
  }

  public boolean tieneRol(Rol rol) {
    return roles.contains(rol);
  }

  public boolean estaActivo() {
    return estado == UsuarioEstado.ACTIVO;
  }

  public void bloquear() {
    this.estado = UsuarioEstado.BLOQUEADO;
  }

  public Optional<UUID> getTenantId() {
    return Optional.ofNullable(tenantId);
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
    return Set.copyOf(roles);
  }

  public boolean isMfaEnabled() {
    return mfaEnabled;
  }

  public UsuarioEstado getEstado() {
    return estado;
  }

  public Optional<UUID> getSucursalId() {
    return Optional.ofNullable(sucursalId);
  }
}
