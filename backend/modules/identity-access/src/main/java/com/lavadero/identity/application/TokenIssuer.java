package com.lavadero.identity.application;

import com.lavadero.identity.application.dto.AuthResultDto;
import com.lavadero.identity.application.dto.UsuarioAutenticadoDto;
import com.lavadero.identity.application.port.TokenService;
import com.lavadero.identity.domain.model.RefreshToken;
import com.lavadero.identity.domain.model.Usuario;
import com.lavadero.identity.domain.repository.RefreshTokenRepository;
import java.time.Duration;
import java.time.Instant;
import java.util.stream.Collectors;
import org.springframework.stereotype.Component;

/**
 * Helper de aplicación compartido por {@code LoginUseCase} y {@code RefreshTokenUseCase}: emite un
 * par access/refresh token para un usuario ya autenticado/validado, persistiendo el nuevo refresh
 * token (hasheado). No es un caso de uso en sí (no implementa {@code UseCase}) porque no es un
 * punto de entrada de la aplicación, solo una utilidad interna.
 */
@Component
public class TokenIssuer {

  private static final Duration VIGENCIA_REFRESH_TOKEN = Duration.ofDays(30);

  private final TokenService tokenService;
  private final RefreshTokenRepository refreshTokenRepository;

  public TokenIssuer(TokenService tokenService, RefreshTokenRepository refreshTokenRepository) {
    this.tokenService = tokenService;
    this.refreshTokenRepository = refreshTokenRepository;
  }

  /** Emite el primer par de tokens de una sesión (login). */
  public AuthResultDto emitirParNuevo(Usuario usuario) {
    return emitir(usuario, null);
  }

  /** Emite un par rotado a partir de un refresh token válido (refresh). */
  public AuthResultDto emitirRotado(Usuario usuario, RefreshToken tokenAnterior) {
    return emitir(usuario, tokenAnterior);
  }

  private AuthResultDto emitir(Usuario usuario, RefreshToken tokenAnterior) {
    String accessToken = tokenService.generarAccessToken(usuario);
    String refreshTokenPlano = tokenService.generarRefreshTokenOpaco();
    String hash = TokenHasher.sha256(refreshTokenPlano);
    Instant expiraEn = Instant.now().plus(VIGENCIA_REFRESH_TOKEN);

    RefreshToken aPersistir =
        tokenAnterior == null
            ? RefreshToken.nuevo(
                usuario.getId(), usuario.getTenantId().orElse(null), hash, expiraEn)
            : RefreshToken.rotadoDesde(tokenAnterior, hash, expiraEn);
    refreshTokenRepository.save(aPersistir);

    UsuarioAutenticadoDto usuarioDto =
        new UsuarioAutenticadoDto(
            usuario.getId(),
            usuario.getEmail(),
            usuario.getRoles().stream().map(Enum::name).collect(Collectors.toSet()),
            usuario.getTenantId().orElse(null),
            usuario.getSucursalId().orElse(null));

    return new AuthResultDto(
        accessToken, refreshTokenPlano, tokenService.duracionAccessToken().toSeconds(), usuarioDto);
  }
}
