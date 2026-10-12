package com.lavadero.identity.interfaces.rest;

import com.lavadero.identity.application.command.OnboardingTenantCommand;
import com.lavadero.identity.application.dto.AuthResultDto;
import com.lavadero.identity.application.usecase.OnboardingTenantUseCase;
import com.lavadero.identity.interfaces.rest.dto.AuthResponse;
import com.lavadero.identity.interfaces.rest.dto.OnboardingTenantRequest;
import jakarta.validation.Valid;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

/**
 * Alta self-service de un lavadero nuevo (tenant + su primer admin), sin intervención de
 * SUPER_ADMIN. Endpoint público, en la lista blanca de {@code SecurityConfig} y con rate limiting
 * (ver {@code RateLimitFilter}) — mismo nivel de exposición que {@code /auth/register}.
 */
@RestController
@RequestMapping("/api/v1/onboarding")
public class OnboardingController {

  private final OnboardingTenantUseCase onboardingTenantUseCase;

  public OnboardingController(OnboardingTenantUseCase onboardingTenantUseCase) {
    this.onboardingTenantUseCase = onboardingTenantUseCase;
  }

  @PostMapping("/tenants")
  public AuthResponse crear(@Valid @RequestBody OnboardingTenantRequest request) {
    AuthResultDto resultado =
        onboardingTenantUseCase.execute(
            new OnboardingTenantCommand(
                request.tenantNombre(),
                request.tenantNit(),
                request.tenantSlug(),
                request.adminEmail(),
                request.adminPassword(),
                request.adminNombre()));
    return AuthResponse.from(resultado);
  }
}
