package com.lavadero.identity.infrastructure.persistence;

import com.lavadero.identity.domain.model.Rol;
import com.lavadero.identity.domain.model.Usuario;
import com.lavadero.identity.domain.model.UsuarioEstado;
import com.lavadero.identity.domain.repository.UsuarioRepository;
import java.util.List;
import java.util.Optional;
import java.util.UUID;
import org.springframework.stereotype.Repository;
import org.springframework.transaction.annotation.Transactional;

@Repository
class UsuarioRepositoryAdapter implements UsuarioRepository {

  private final UsuarioJpaRepository jpaRepository;

  UsuarioRepositoryAdapter(UsuarioJpaRepository jpaRepository) {
    this.jpaRepository = jpaRepository;
  }

  @Override
  @Transactional(readOnly = true)
  public Optional<Usuario> findByEmailAndTenantId(String email, UUID tenantId) {
    return jpaRepository
        .findByEmailAndTenantId(email, tenantId)
        .map(UsuarioRepositoryAdapter::toDomain);
  }

  @Override
  @Transactional(readOnly = true)
  public Optional<Usuario> findById(UUID id) {
    return jpaRepository.findById(id).map(UsuarioRepositoryAdapter::toDomain);
  }

  @Override
  @Transactional(readOnly = true)
  public boolean existsByEmailAndTenantId(String email, UUID tenantId) {
    return jpaRepository.existsByEmailAndTenantId(email, tenantId);
  }

  @Override
  @Transactional(readOnly = true)
  public List<Usuario> findEmpleadosDelTenantActual(UUID sucursalId) {
    var filas =
        sucursalId == null
            ? jpaRepository.findByRol(Rol.EMPLEADO)
            : jpaRepository.findByRolAndSucursalId(Rol.EMPLEADO, sucursalId);
    return filas.stream().map(UsuarioRepositoryAdapter::toDomain).toList();
  }

  @Override
  @Transactional
  public Usuario save(Usuario usuario) {
    UsuarioJpaEntity entity =
        new UsuarioJpaEntity(
            usuario.getId(),
            usuario.getTenantId().orElse(null),
            usuario.getEmail(),
            usuario.getNombre(),
            usuario.getPasswordHash(),
            usuario.getRoles(),
            usuario.isMfaEnabled(),
            usuario.getEstado().name(),
            usuario.getSucursalId().orElse(null));
    jpaRepository.save(entity);
    return usuario;
  }

  private static Usuario toDomain(UsuarioJpaEntity entity) {
    return new Usuario(
        entity.getId(),
        entity.getTenantId(),
        entity.getEmail(),
        entity.getNombre(),
        entity.getPasswordHash(),
        entity.getRoles(),
        entity.isMfaEnabled(),
        UsuarioEstado.valueOf(entity.getEstado()),
        entity.getSucursalId());
  }
}
