package com.lavadero.identity.application.usecase;

import com.lavadero.contracts.identity.UsuarioRegistradoEvent;
import com.lavadero.identity.application.TokenIssuer;
import com.lavadero.identity.application.command.RegistrarClienteCommand;
import com.lavadero.identity.application.dto.AuthResultDto;
import com.lavadero.identity.domain.model.Usuario;
import com.lavadero.identity.domain.repository.UsuarioRepository;
import com.lavadero.shared.application.UseCase;
import com.lavadero.shared.application.exception.ValidationException;
import com.lavadero.tenant.application.dto.TenantResumenDto;
import com.lavadero.tenant.application.usecase.ObtenerTenantPorSlugUseCase;
import org.springframework.context.ApplicationEventPublisher;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

/**
 * Auto-registro público de un cliente nuevo dentro de un tenant (header {@code X-Tenant-Slug}
 * obligatorio).
 */
@Service
public class RegistrarClienteUseCase implements UseCase<RegistrarClienteCommand, AuthResultDto> {

  private final UsuarioRepository usuarioRepository;
  private final ObtenerTenantPorSlugUseCase obtenerTenantPorSlugUseCase;
  private final PasswordEncoder passwordEncoder;
  private final TokenIssuer tokenIssuer;
  private final ApplicationEventPublisher eventPublisher;

  public RegistrarClienteUseCase(
      UsuarioRepository usuarioRepository,
      ObtenerTenantPorSlugUseCase obtenerTenantPorSlugUseCase,
      PasswordEncoder passwordEncoder,
      TokenIssuer tokenIssuer,
      ApplicationEventPublisher eventPublisher) {
    this.usuarioRepository = usuarioRepository;
    this.obtenerTenantPorSlugUseCase = obtenerTenantPorSlugUseCase;
    this.passwordEncoder = passwordEncoder;
    this.tokenIssuer = tokenIssuer;
    this.eventPublisher = eventPublisher;
  }

  @Override
  @Transactional
  public AuthResultDto execute(RegistrarClienteCommand input) {
    if (input.tenantSlug() == null || input.tenantSlug().isBlank()) {
      throw new ValidationException("X-Tenant-Slug es obligatorio para el auto-registro");
    }
    TenantResumenDto tenant = obtenerTenantPorSlugUseCase.execute(input.tenantSlug());
    String email = input.email().toLowerCase();

    if (usuarioRepository.existsByEmailAndTenantId(email, tenant.id())) {
      throw new ValidationException("Ya existe un usuario con ese email en este tenant");
    }

    String passwordHash = passwordEncoder.encode(input.password());
    Usuario usuario = Usuario.cliente(tenant.id(), email, input.nombre(), passwordHash);
    usuarioRepository.save(usuario);

    eventPublisher.publishEvent(
        UsuarioRegistradoEvent.of(usuario.getId(), tenant.id(), usuario.getEmail()));

    return tokenIssuer.emitirParNuevo(usuario);
  }
}
