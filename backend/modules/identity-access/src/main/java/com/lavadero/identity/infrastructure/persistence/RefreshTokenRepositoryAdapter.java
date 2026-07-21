package com.lavadero.identity.infrastructure.persistence;

import com.lavadero.identity.domain.model.RefreshToken;
import com.lavadero.identity.domain.repository.RefreshTokenRepository;
import java.util.List;
import java.util.Optional;
import java.util.UUID;
import org.springframework.stereotype.Repository;
import org.springframework.transaction.annotation.Transactional;

@Repository
class RefreshTokenRepositoryAdapter implements RefreshTokenRepository {

  private final RefreshTokenJpaRepository jpaRepository;

  RefreshTokenRepositoryAdapter(RefreshTokenJpaRepository jpaRepository) {
    this.jpaRepository = jpaRepository;
  }

  @Override
  @Transactional(readOnly = true)
  public Optional<RefreshToken> findByTokenHash(String tokenHash) {
    return jpaRepository.findByTokenHash(tokenHash).map(RefreshTokenRepositoryAdapter::toDomain);
  }

  @Override
  @Transactional(readOnly = true)
  public List<RefreshToken> findCadenaDelUsuario(UUID usuarioId) {
    return jpaRepository.findByUsuarioIdOrderByExpiraEnDesc(usuarioId).stream()
        .map(RefreshTokenRepositoryAdapter::toDomain)
        .toList();
  }

  @Override
  @Transactional
  public RefreshToken save(RefreshToken refreshToken) {
    RefreshTokenJpaEntity entity =
        new RefreshTokenJpaEntity(
            refreshToken.getId(),
            refreshToken.getUsuarioId(),
            refreshToken.getTokenHash(),
            refreshToken.getExpiraEn(),
            refreshToken.isRevocado(),
            refreshToken.getCreadoPorTokenAnteriorId().orElse(null));
    jpaRepository.save(entity);
    return refreshToken;
  }

  @Override
  @Transactional
  public void revocarTodosDelUsuario(UUID usuarioId) {
    jpaRepository.revocarTodosDelUsuario(usuarioId);
  }

  private static RefreshToken toDomain(RefreshTokenJpaEntity entity) {
    return new RefreshToken(
        entity.getId(),
        entity.getUsuarioId(),
        entity.getTokenHash(),
        entity.getExpiraEn(),
        entity.isRevocado(),
        entity.getCreadoPorTokenAnteriorId());
  }
}
