package com.lavadero.identity.domain.model;

import com.lavadero.shared.domain.AggregateRoot;
import java.time.Instant;
import java.util.Objects;
import java.util.Optional;
import java.util.UUID;

/**
 * Refresh token con soporte de rotación y detección de reuso ("robo de token"). NUNCA se persiste
 * el token en claro: solo su hash ({@code tokenHash}). {@code creadoPorTokenAnteriorId} enlaza la
 * cadena de rotación: si un token ya revocado se intenta reusar, toda la cadena del usuario se
 * revoca (ver {@code RefreshTokenUseCase}).
 */
public class RefreshToken extends AggregateRoot<UUID> {

  private final UUID usuarioId;
  private final String tokenHash;
  private final Instant expiraEn;
  private boolean revocado;
  private final UUID creadoPorTokenAnteriorId;

  public RefreshToken(
      UUID id,
      UUID usuarioId,
      String tokenHash,
      Instant expiraEn,
      boolean revocado,
      UUID creadoPorTokenAnteriorId) {
    super(id);
    this.usuarioId = Objects.requireNonNull(usuarioId);
    this.tokenHash = Objects.requireNonNull(tokenHash);
    this.expiraEn = Objects.requireNonNull(expiraEn);
    this.revocado = revocado;
    this.creadoPorTokenAnteriorId = creadoPorTokenAnteriorId;
  }

  public static RefreshToken nuevo(UUID usuarioId, String tokenHash, Instant expiraEn) {
    return new RefreshToken(UUID.randomUUID(), usuarioId, tokenHash, expiraEn, false, null);
  }

  public static RefreshToken rotadoDesde(
      RefreshToken anterior, String nuevoTokenHash, Instant expiraEn) {
    return new RefreshToken(
        UUID.randomUUID(), anterior.usuarioId, nuevoTokenHash, expiraEn, false, anterior.getId());
  }

  public boolean estaVigente() {
    return !revocado && expiraEn.isAfter(Instant.now());
  }

  public void revocar() {
    this.revocado = true;
  }

  public UUID getUsuarioId() {
    return usuarioId;
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

  public Optional<UUID> getCreadoPorTokenAnteriorId() {
    return Optional.ofNullable(creadoPorTokenAnteriorId);
  }
}
