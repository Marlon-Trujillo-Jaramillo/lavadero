package com.lavadero.identity.infrastructure.security;

import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.security.access.expression.method.MethodSecurityExpressionHandler;
import org.springframework.security.config.annotation.method.configuration.EnableMethodSecurity;
import org.springframework.security.config.annotation.web.builders.HttpSecurity;
import org.springframework.security.config.annotation.web.configurers.AbstractHttpConfigurer;
import org.springframework.security.config.http.SessionCreationPolicy;
import org.springframework.security.web.SecurityFilterChain;
import org.springframework.security.web.authentication.UsernamePasswordAuthenticationFilter;

/**
 * Configuración central de Spring Security.
 *
 * <p>Orden de filtros relevante:
 *
 * <ol>
 *   <li>{@link RateLimitFilter}: corta temprano (429) los intentos de fuerza bruta en
 *       login/refresh, antes de gastar ciclos de autenticación.
 *   <li>{@link JwtAuthenticationFilter}: valida el JWT (si viene) y puebla el SecurityContext.
 *   <li>{@link TenantResolutionFilter}: lee el claim {@code tenant_id} YA VALIDADO y puebla {@code
 *       TenantContext} para el resto de la request; limpia el contexto en un {@code finally}.
 * </ol>
 *
 * <p>Sesión STATELESS (sin cookies de sesión): toda la autenticación viaja en el header {@code
 * Authorization: Bearer <jwt>} en cada request.
 */
@Configuration
@EnableMethodSecurity
public class SecurityConfig {

  /** Endpoints públicos: no requieren JWT. Lista blanca explícita y exhaustiva. */
  private static final String[] ENDPOINTS_PUBLICOS = {
    "/api/v1/auth/login",
    "/api/v1/auth/refresh",
    "/api/v1/auth/register",
    "/actuator/health",
    "/actuator/health/**"
  };

  private final JwtTokenService jwtTokenService;

  public SecurityConfig(JwtTokenService jwtTokenService) {
    this.jwtTokenService = jwtTokenService;
  }

  @Bean
  public SecurityFilterChain filterChain(HttpSecurity http) throws Exception {
    http.csrf(AbstractHttpConfigurer::disable)
        .sessionManagement(sm -> sm.sessionCreationPolicy(SessionCreationPolicy.STATELESS))
        .authorizeHttpRequests(
            authorize ->
                authorize
                    .requestMatchers(ENDPOINTS_PUBLICOS)
                    .permitAll()
                    // GET /api/v1/tenants es público (búsqueda de lavaderos);
                    // POST /api/v1/tenants exige autenticación + @PreAuthorize
                    // SUPER_ADMIN en el propio controlador.
                    .requestMatchers(org.springframework.http.HttpMethod.GET, "/api/v1/tenants")
                    .permitAll()
                    .anyRequest()
                    .authenticated())
        .addFilterBefore(new RateLimitFilter(), UsernamePasswordAuthenticationFilter.class)
        .addFilterBefore(
            new JwtAuthenticationFilter(jwtTokenService),
            UsernamePasswordAuthenticationFilter.class)
        .addFilterAfter(new TenantResolutionFilter(), JwtAuthenticationFilter.class);

    return http.build();
  }

  @Bean
  public MethodSecurityExpressionHandler methodSecurityExpressionHandler() {
    return new CustomMethodSecurityExpressionHandler();
  }
}
