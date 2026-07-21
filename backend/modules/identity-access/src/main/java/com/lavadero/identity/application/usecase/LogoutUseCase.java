package com.lavadero.identity.application.usecase;

import com.lavadero.identity.application.TokenHasher;
import com.lavadero.identity.application.command.LogoutCommand;
import com.lavadero.identity.domain.repository.RefreshTokenRepository;
import com.lavadero.shared.application.UseCase;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

/** Revoca el refresh token actual de la sesión (logout explícito). Idempotente. */
@Service
public class LogoutUseCase implements UseCase<LogoutCommand, Void> {

  private final RefreshTokenRepository refreshTokenRepository;

  public LogoutUseCase(RefreshTokenRepository refreshTokenRepository) {
    this.refreshTokenRepository = refreshTokenRepository;
  }

  @Override
  @Transactional
  public Void execute(LogoutCommand input) {
    String hash = TokenHasher.sha256(input.refreshToken());
    refreshTokenRepository
        .findByTokenHash(hash)
        .ifPresent(
            token -> {
              token.revocar();
              refreshTokenRepository.save(token);
            });
    return null;
  }
}
