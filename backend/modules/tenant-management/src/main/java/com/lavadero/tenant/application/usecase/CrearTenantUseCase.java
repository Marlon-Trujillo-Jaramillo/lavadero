package com.lavadero.tenant.application.usecase;

import com.lavadero.contracts.tenant.TenantCreadoEvent;
import com.lavadero.shared.application.UseCase;
import com.lavadero.shared.application.exception.ValidationException;
import com.lavadero.shared.security.TenantContext;
import com.lavadero.tenant.application.command.CrearTenantCommand;
import com.lavadero.tenant.application.dto.TenantResumenDto;
import com.lavadero.tenant.domain.factory.TenantProvisioningFactory;
import com.lavadero.tenant.domain.repository.SucursalRepository;
import com.lavadero.tenant.domain.repository.TenantRepository;
import org.springframework.context.ApplicationEventPublisher;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

/**
 * Caso de uso de onboarding: crea un tenant nuevo + su sucursal principal y publica {@link
 * TenantCreadoEvent}. Es el único punto de entrada para dar de alta un tenant (restringido a rol
 * SUPER_ADMIN en la capa REST).
 *
 * <p>Quien llama es SUPER_ADMIN (JWT con {@code tenantId} nulo por invariante de dominio, ver
 * {@code Usuario}), así que {@link TenantContext} NUNCA trae el tenant recién creado por sí solo
 * ({@code TenantResolutionFilter} no tiene nada que leer del JWT) — este caso de uso lo fija
 * explícitamente, igual que documenta el Javadoc de {@code TenantAwareTransactionAspect}, o el
 * insert de {@code sucursal} (RLS + FORCE) lo rechaza.
 */
@Service
public class CrearTenantUseCase implements UseCase<CrearTenantCommand, TenantResumenDto> {

  private final TenantRepository tenantRepository;
  private final SucursalRepository sucursalRepository;
  private final ApplicationEventPublisher eventPublisher;

  public CrearTenantUseCase(
      TenantRepository tenantRepository,
      SucursalRepository sucursalRepository,
      ApplicationEventPublisher eventPublisher) {
    this.tenantRepository = tenantRepository;
    this.sucursalRepository = sucursalRepository;
    this.eventPublisher = eventPublisher;
  }

  @Override
  @Transactional
  public TenantResumenDto execute(CrearTenantCommand input) {
    if (tenantRepository.existsBySlug(input.slug())) {
      throw new ValidationException("Ya existe un tenant con el slug '%s'".formatted(input.slug()));
    }

    TenantProvisioningFactory.Resultado resultado =
        TenantProvisioningFactory.provisionar(
            input.nombre(), input.nit(), input.slug(), input.subscriptionPlanId());

    TenantContext.set(resultado.tenant().getId());
    try {
      tenantRepository.save(resultado.tenant());
      sucursalRepository.save(resultado.sucursalPrincipal());
    } finally {
      TenantContext.clear();
    }

    eventPublisher.publishEvent(
        TenantCreadoEvent.of(
            resultado.tenant().getId(),
            resultado.tenant().getSlug(),
            resultado.tenant().getNombre()));

    return new TenantResumenDto(
        resultado.tenant().getId(), resultado.tenant().getSlug(), resultado.tenant().getNombre());
  }
}
