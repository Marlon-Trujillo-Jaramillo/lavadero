package com.lavadero.identity.domain.repository;

import com.lavadero.identity.domain.model.Usuario;
import java.util.Optional;
import java.util.UUID;

public interface UsuarioRepository {

  /**
   * Busca por email dentro de un tenant. Si {@code tenantId} es {@code null}, busca entre cuentas
   * de plataforma (SUPER_ADMIN, sin tenant).
   */
  Optional<Usuario> findByEmailAndTenantId(String email, UUID tenantId);

  Optional<Usuario> findById(UUID id);

  boolean existsByEmailAndTenantId(String email, UUID tenantId);

  Usuario save(Usuario usuario);
}
