package com.lavadero.identity.domain.repository;

import com.lavadero.identity.domain.model.RefreshToken;
import java.util.List;
import java.util.Optional;
import java.util.UUID;

public interface RefreshTokenRepository {

  Optional<RefreshToken> findByTokenHash(String tokenHash);

  List<RefreshToken> findCadenaDelUsuario(UUID usuarioId);

  RefreshToken save(RefreshToken refreshToken);

  void revocarTodosDelUsuario(UUID usuarioId);
}
