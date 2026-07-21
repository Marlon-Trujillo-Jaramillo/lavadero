package com.lavadero.identity.infrastructure.persistence;

import java.util.Optional;
import java.util.UUID;
import org.springframework.data.jpa.repository.JpaRepository;

/**
 * Repositorio Spring Data. Deliberadamente NO añade cláusulas manuales de aislamiento por tenant:
 * eso lo garantizan la política RLS de Postgres y el filtro de Hibernate a nivel de sesión (ver
 * {@code UsuarioJpaEntity}).
 *
 * <p>Nota sobre {@code tenantId} nulo: Spring Data JPA traduce automáticamente un parámetro {@code
 * null} en una consulta derivada ({@code findByEmailAndTenantId}, {@code existsByEmailAndTenantId})
 * a {@code IS NULL} en el JPQL generado, así que estos métodos funcionan correctamente tanto para
 * usuarios de negocio (tenantId no nulo) como para cuentas de plataforma SUPER_ADMIN (tenantId
 * nulo) sin necesitar dos variantes de query.
 */
interface UsuarioJpaRepository extends JpaRepository<UsuarioJpaEntity, UUID> {

  Optional<UsuarioJpaEntity> findByEmailAndTenantId(String email, UUID tenantId);

  boolean existsByEmailAndTenantId(String email, UUID tenantId);
}
