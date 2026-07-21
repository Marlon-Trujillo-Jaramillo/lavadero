package com.lavadero.identity.infrastructure.persistence;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.Id;
import jakarta.persistence.Table;
import java.time.Instant;
import java.util.UUID;

/**
 * Entidad JPA de {@code RefreshToken}. Solo persiste el hash del token (ver {@code token_hash} en
 * V2__identity_access.sql y {@code TokenHasher} en `application`), nunca el valor en claro.
 */
@Entity
@Table(name = "refresh_token")
public class RefreshTokenJpaEntity {

  @Id private UUID id;

  @Column(name = "usuario_id", nullable = false)
  private UUID usuarioId;

  @Column(name = "tenant_id")
  private UUID tenantId;

  @Column(name = "token_hash", nullable = false, unique = true)
  private String tokenHash;

  @Column(name = "expira_en", nullable = false)
  private Instant expiraEn;

  @Column(nullable = false)
  private boolean revocado;

  @Column(name = "creado_por_token_anterior_id")
  private UUID creadoPorTokenAnteriorId;

  protected RefreshTokenJpaEntity() {}

  public RefreshTokenJpaEntity(
      UUID id,
      UUID usuarioId,
      UUID tenantId,
      String tokenHash,
      Instant expiraEn,
      boolean revocado,
      UUID creadoPorTokenAnteriorId) {
    this.id = id;
    this.usuarioId = usuarioId;
    this.tenantId = tenantId;
    this.tokenHash = tokenHash;
    this.expiraEn = expiraEn;
    this.revocado = revocado;
    this.creadoPorTokenAnteriorId = creadoPorTokenAnteriorId;
  }

  public UUID getId() {
    return id;
  }

  public UUID getUsuarioId() {
    return usuarioId;
  }

  public UUID getTenantId() {
    return tenantId;
  }

  public String getTokenHash() {
    return tokenHash;
  }

  public Instant getExpiraEn() {
    return expiraEn;
  }

  public boolean isRevocado() {
    return revocado;
  }

  public UUID getCreadoPorTokenAnteriorId() {
    return creadoPorTokenAnteriorId;
  }
}
