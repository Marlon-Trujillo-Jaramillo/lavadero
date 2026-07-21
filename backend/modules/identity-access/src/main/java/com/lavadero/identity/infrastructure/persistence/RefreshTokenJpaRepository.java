package com.lavadero.identity.infrastructure.persistence;

import java.util.List;
import java.util.Optional;
import java.util.UUID;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Modifying;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

interface RefreshTokenJpaRepository extends JpaRepository<RefreshTokenJpaEntity, UUID> {

  Optional<RefreshTokenJpaEntity> findByTokenHash(String tokenHash);

  List<RefreshTokenJpaEntity> findByUsuarioIdOrderByExpiraEnDesc(UUID usuarioId);

  @Modifying
  @Query(
      "update RefreshTokenJpaEntity r set r.revocado = true "
          + "where r.usuarioId = :usuarioId and r.revocado = false")
  void revocarTodosDelUsuario(@Param("usuarioId") UUID usuarioId);
}
