package com.lavadero.identity.application.usecase;

import com.lavadero.identity.application.RefreshTokenFormato;
import com.lavadero.identity.application.TokenHasher;
import com.lavadero.identity.application.TokenIssuer;
import com.lavadero.identity.application.command.RefreshTokenCommand;
import com.lavadero.identity.application.dto.AuthResultDto;
import com.lavadero.identity.domain.model.RefreshToken;
import com.lavadero.identity.domain.model.Usuario;
import com.lavadero.identity.domain.repository.RefreshTokenRepository;
import com.lavadero.identity.domain.repository.UsuarioRepository;
import com.lavadero.shared.application.UseCase;
import com.lavadero.shared.application.exception.ForbiddenException;
import com.lavadero.shared.application.exception.NotFoundException;
import com.lavadero.shared.security.TenantContext;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

/**
 * Refresca un par de tokens con ROTACIÓN: el refresh token usado se marca revocado y se emite uno
 * nuevo. Si el token recibido YA estaba revocado, es señal de reuso (robo de refresh token): se
 * revoca TODA la cadena del usuario y se responde 403 (vía {@link ForbiddenException}), forzando un
 * login limpio: el cliente trata cualquier fallo de refresh como cierre de sesión.
 *
 * <p>Endpoint público (sin JWT): {@code TenantContext} no llega poblado. El prefijo del token (ver
 * {@link RefreshTokenFormato}) lo fija ANTES de buscar el token, porque la política RLS de {@code
 * refresh_token} lo ocultaría sin tenant. Después, {@code token.getTenantId()} (el valor
 * persistido) es el que manda para leer {@code Usuario}.
 *
 * <p>{@code noRollbackFor}: la revocación por reuso tiene que persistir aunque se lance la
 * excepción; con rollback por defecto, la detección de robo no tendría efecto.
 */
@Service
public class RefreshTokenUseCase implements UseCase<RefreshTokenCommand, AuthResultDto> {

  private final RefreshTokenRepository refreshTokenRepository;
  private final UsuarioRepository usuarioRepository;
  private final TokenIssuer tokenIssuer;

  public RefreshTokenUseCase(
      RefreshTokenRepository refreshTokenRepository,
      UsuarioRepository usuarioRepository,
      TokenIssuer tokenIssuer) {
    this.refreshTokenRepository = refreshTokenRepository;
    this.usuarioRepository = usuarioRepository;
    this.tokenIssuer = tokenIssuer;
  }

  @Override
  @Transactional(noRollbackFor = ForbiddenException.class)
  public AuthResultDto execute(RefreshTokenCommand input) {
    RefreshTokenFormato.tenantDe(input.refreshToken()).ifPresent(TenantContext::set);
    try {
      String hash = TokenHasher.sha256(input.refreshToken());

      RefreshToken token =
          refreshTokenRepository
              .findByTokenHash(hash)
              .orElseThrow(() -> new ForbiddenException("Refresh token inválido"));

      if (token.isRevocado()) {
        // Reuso de un token ya rotado: posible robo. Se revoca toda la
        // cadena del usuario para forzar re-autenticación completa.
        refreshTokenRepository.revocarTodosDelUsuario(token.getUsuarioId());
        throw new ForbiddenException("Refresh token reutilizado; sesión revocada");
      }

      if (!token.estaVigente()) {
        throw new ForbiddenException("Refresh token expirado");
      }

      token.getTenantId().ifPresent(TenantContext::set);
      Usuario usuario =
          usuarioRepository
              .findById(token.getUsuarioId())
              .orElseThrow(() -> NotFoundException.de("Usuario", token.getUsuarioId()));

      token.revocar();
      refreshTokenRepository.save(token);

      return tokenIssuer.emitirRotado(usuario, token);
    } finally {
      TenantContext.clear();
    }
  }
}
