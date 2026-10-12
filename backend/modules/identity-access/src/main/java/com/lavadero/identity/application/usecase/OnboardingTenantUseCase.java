package com.lavadero.identity.application.usecase;

import com.lavadero.contracts.identity.UsuarioRegistradoEvent;
import com.lavadero.identity.application.TokenIssuer;
import com.lavadero.identity.application.command.OnboardingTenantCommand;
import com.lavadero.identity.application.dto.AuthResultDto;
import com.lavadero.identity.domain.model.Usuario;
import com.lavadero.identity.domain.repository.UsuarioRepository;
import com.lavadero.shared.application.UseCase;
import com.lavadero.shared.application.exception.ValidationException;
import com.lavadero.shared.security.TenantContext;
import com.lavadero.tenant.application.command.CrearTenantCommand;
import com.lavadero.tenant.application.dto.TenantResumenDto;
import com.lavadero.tenant.application.usecase.CrearTenantUseCase;
import java.util.UUID;
import org.springframework.context.ApplicationEventPublisher;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

/**
 * Alta self-service de un tenant nuevo: antes de esto, la ÚNICA forma de crear un tenant era que un
 * SUPER_ADMIN llamara {@code POST /api/v1/tenants} a mano — sin este caso de uso, un lavadero nuevo
 * no podía darse de alta solo, tenía que pedirle al desarrollador que lo hiciera por él (ver spec
 * de auditoría técnica/negocio 2026-08-18).
 *
 * <p>Reusa {@link CrearTenantUseCase} (tenant + sucursal principal, mismo camino que usa
 * SUPER_ADMIN) y, en la MISMA transacción, crea el primer usuario {@code ADMIN_TENANT} — mismo
 * patrón de "todo o nada" que motiva ADR 0001 (monolito modular = transacciones ACID reales entre
 * agregados de distintos módulos sin sagas). Sin selección de plan: se asigna el plan "Starter"
 * (sembrado en V1__tenant_management.sql) porque todavía no existe checkout de pago (ver Fase 3 de
 * esa misma auditoría) — el tenant puede cambiar de plan más adelante vía
 * `ActualizarSubscriptionPlanUseCase`/soporte.
 */
@Service
public class OnboardingTenantUseCase implements UseCase<OnboardingTenantCommand, AuthResultDto> {

  private static final UUID PLAN_STARTER_ID =
      UUID.fromString("00000000-0000-0000-0000-000000000001");

  private final CrearTenantUseCase crearTenantUseCase;
  private final UsuarioRepository usuarioRepository;
  private final PasswordEncoder passwordEncoder;
  private final TokenIssuer tokenIssuer;
  private final ApplicationEventPublisher eventPublisher;

  public OnboardingTenantUseCase(
      CrearTenantUseCase crearTenantUseCase,
      UsuarioRepository usuarioRepository,
      PasswordEncoder passwordEncoder,
      TokenIssuer tokenIssuer,
      ApplicationEventPublisher eventPublisher) {
    this.crearTenantUseCase = crearTenantUseCase;
    this.usuarioRepository = usuarioRepository;
    this.passwordEncoder = passwordEncoder;
    this.tokenIssuer = tokenIssuer;
    this.eventPublisher = eventPublisher;
  }

  @Override
  @Transactional
  public AuthResultDto execute(OnboardingTenantCommand input) {
    TenantResumenDto tenant =
        crearTenantUseCase.execute(
            new CrearTenantCommand(
                input.tenantNombre(), input.tenantNit(), input.tenantSlug(), PLAN_STARTER_ID));

    String email = input.adminEmail().toLowerCase();

    // CrearTenantUseCase ya limpió TenantContext en su propio finally: hay que
    // fijarlo de nuevo para el insert de `usuario` (RLS + FORCE), igual que
    // RegistrarClienteUseCase.
    TenantContext.set(tenant.id());
    try {
      if (usuarioRepository.existsByEmailAndTenantId(email, tenant.id())) {
        throw new ValidationException("Ya existe un usuario con ese email en este tenant");
      }

      String passwordHash = passwordEncoder.encode(input.adminPassword());
      Usuario admin = Usuario.adminTenant(tenant.id(), email, input.adminNombre(), passwordHash);
      usuarioRepository.save(admin);

      eventPublisher.publishEvent(
          UsuarioRegistradoEvent.of(admin.getId(), tenant.id(), admin.getEmail()));

      return tokenIssuer.emitirParNuevo(admin);
    } finally {
      TenantContext.clear();
    }
  }
}
