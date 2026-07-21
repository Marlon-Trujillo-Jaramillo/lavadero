package com.lavadero.identity.interfaces.rest;

import com.lavadero.identity.application.command.LoginCommand;
import com.lavadero.identity.application.command.LogoutCommand;
import com.lavadero.identity.application.command.RefreshTokenCommand;
import com.lavadero.identity.application.command.RegistrarClienteCommand;
import com.lavadero.identity.application.dto.AuthResultDto;
import com.lavadero.identity.application.usecase.LoginUseCase;
import com.lavadero.identity.application.usecase.LogoutUseCase;
import com.lavadero.identity.application.usecase.RefreshTokenUseCase;
import com.lavadero.identity.application.usecase.RegistrarClienteUseCase;
import com.lavadero.identity.interfaces.rest.dto.AuthResponse;
import com.lavadero.identity.interfaces.rest.dto.LoginRequest;
import com.lavadero.identity.interfaces.rest.dto.LogoutRequest;
import com.lavadero.identity.interfaces.rest.dto.RefreshRequest;
import com.lavadero.identity.interfaces.rest.dto.RegisterRequest;
import com.lavadero.identity.interfaces.rest.dto.TokenPairResponse;
import jakarta.validation.Valid;
import org.springframework.http.HttpStatus;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestHeader;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.ResponseStatus;
import org.springframework.web.bind.annotation.RestController;

/**
 * Contrato FIJO consumido por la app Flutter (mobile_app): no cambiar la forma de los
 * endpoints/DTOs sin coordinar con ese lado.
 *
 * <p>{@code /login} y {@code /refresh} están en la lista blanca pública de {@code SecurityConfig}
 * (identity-access); {@code /logout} NO, por lo que exige autenticación (JWT) por la regla por
 * defecto de esa configuración.
 */
@RestController
@RequestMapping("/api/v1/auth")
public class AuthController {

  private final LoginUseCase loginUseCase;
  private final RegistrarClienteUseCase registrarClienteUseCase;
  private final RefreshTokenUseCase refreshTokenUseCase;
  private final LogoutUseCase logoutUseCase;

  public AuthController(
      LoginUseCase loginUseCase,
      RegistrarClienteUseCase registrarClienteUseCase,
      RefreshTokenUseCase refreshTokenUseCase,
      LogoutUseCase logoutUseCase) {
    this.loginUseCase = loginUseCase;
    this.registrarClienteUseCase = registrarClienteUseCase;
    this.refreshTokenUseCase = refreshTokenUseCase;
    this.logoutUseCase = logoutUseCase;
  }

  @PostMapping("/login")
  public AuthResponse login(
      @RequestHeader(value = "X-Tenant-Slug", required = false) String tenantSlug,
      @Valid @RequestBody LoginRequest request) {
    AuthResultDto resultado =
        loginUseCase.execute(new LoginCommand(tenantSlug, request.email(), request.password()));
    return AuthResponse.from(resultado);
  }

  @PostMapping("/register")
  public AuthResponse register(
      @RequestHeader("X-Tenant-Slug") String tenantSlug,
      @Valid @RequestBody RegisterRequest request) {
    AuthResultDto resultado =
        registrarClienteUseCase.execute(
            new RegistrarClienteCommand(
                tenantSlug, request.email(), request.password(), request.nombre()));
    return AuthResponse.from(resultado);
  }

  @PostMapping("/refresh")
  public TokenPairResponse refresh(@Valid @RequestBody RefreshRequest request) {
    AuthResultDto resultado =
        refreshTokenUseCase.execute(new RefreshTokenCommand(request.refreshToken()));
    return TokenPairResponse.from(resultado);
  }

  @PostMapping("/logout")
  @ResponseStatus(HttpStatus.NO_CONTENT)
  public void logout(@Valid @RequestBody LogoutRequest request) {
    logoutUseCase.execute(new LogoutCommand(request.refreshToken()));
  }
}
