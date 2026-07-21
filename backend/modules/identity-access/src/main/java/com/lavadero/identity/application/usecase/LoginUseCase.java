package com.lavadero.identity.application.usecase;

import com.lavadero.identity.application.TokenIssuer;
import com.lavadero.identity.application.command.LoginCommand;
import com.lavadero.identity.application.dto.AuthResultDto;
import com.lavadero.identity.domain.model.Usuario;
import com.lavadero.identity.domain.repository.UsuarioRepository;
import com.lavadero.shared.application.UseCase;
import com.lavadero.shared.application.exception.ForbiddenException;
import com.lavadero.tenant.application.dto.TenantResumenDto;
import com.lavadero.tenant.application.usecase.ObtenerTenantPorSlugUseCase;
import java.util.UUID;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

/**
 * Login: resuelve el tenant a partir de {@code X-Tenant-Slug} (si viene vacío, se interpreta como
 * intento de login de plataforma/SUPER_ADMIN), valida credenciales y emite un par access/refresh
 * token.
 *
 * <p>El header de tenant se usa SOLO aquí, para decidir en qué tenant autenticar; una vez emitido
 * el JWT, el tenant que importa para autorización es el que queda embebido en el claim {@code
 * tenant_id}, nunca un header (ver {@code TenantResolutionFilter} en infrastructure/security).
 */
@Service
public class LoginUseCase implements UseCase<LoginCommand, AuthResultDto> {

  private final UsuarioRepository usuarioRepository;
  private final ObtenerTenantPorSlugUseCase obtenerTenantPorSlugUseCase;
  private final PasswordEncoder passwordEncoder;
  private final TokenIssuer tokenIssuer;

  public LoginUseCase(
      UsuarioRepository usuarioRepository,
      ObtenerTenantPorSlugUseCase obtenerTenantPorSlugUseCase,
      PasswordEncoder passwordEncoder,
      TokenIssuer tokenIssuer) {
    this.usuarioRepository = usuarioRepository;
    this.obtenerTenantPorSlugUseCase = obtenerTenantPorSlugUseCase;
    this.passwordEncoder = passwordEncoder;
    this.tokenIssuer = tokenIssuer;
  }

  @Override
  @Transactional
  public AuthResultDto execute(LoginCommand input) {
    UUID tenantId = resolverTenantId(input.tenantSlug());

    Usuario usuario =
        usuarioRepository
            .findByEmailAndTenantId(input.email().toLowerCase(), tenantId)
            .orElseThrow(() -> new ForbiddenException("Credenciales inválidas"));

    if (!usuario.estaActivo()) {
      throw new ForbiddenException("Usuario bloqueado");
    }
    if (!passwordEncoder.matches(input.password(), usuario.getPasswordHash())) {
      throw new ForbiddenException("Credenciales inválidas");
    }

    return tokenIssuer.emitirParNuevo(usuario);
  }

  private UUID resolverTenantId(String tenantSlug) {
    if (tenantSlug == null || tenantSlug.isBlank()) {
      return null;
    }
    TenantResumenDto tenant = obtenerTenantPorSlugUseCase.execute(tenantSlug);
    return tenant.id();
  }
}
