package com.lavadero.identity.infrastructure.security;

import java.time.Duration;
import java.util.List;
import org.springframework.boot.context.properties.EnableConfigurationProperties;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.security.access.expression.method.MethodSecurityExpressionHandler;
import org.springframework.security.config.annotation.method.configuration.EnableMethodSecurity;
import org.springframework.security.config.annotation.web.builders.HttpSecurity;
import org.springframework.security.config.annotation.web.configurers.AbstractHttpConfigurer;
import org.springframework.security.config.http.SessionCreationPolicy;
import org.springframework.security.web.SecurityFilterChain;
import org.springframework.security.web.authentication.UsernamePasswordAuthenticationFilter;
import org.springframework.web.cors.CorsConfiguration;
import org.springframework.web.cors.CorsConfigurationSource;
import org.springframework.web.cors.UrlBasedCorsConfigurationSource;

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
@EnableConfigurationProperties(CorsProperties.class)
public class SecurityConfig {

  /** Endpoints públicos: no requieren JWT. Lista blanca explícita y exhaustiva. */
  private static final String[] ENDPOINTS_PUBLICOS = {
    "/api/v1/auth/login",
    "/api/v1/auth/refresh",
    "/api/v1/auth/register",
    "/api/v1/onboarding/tenants",
    "/actuator/health",
    "/actuator/health/**"
  };

  private final JwtTokenService jwtTokenService;
  private final CorsProperties corsProperties;

  public SecurityConfig(JwtTokenService jwtTokenService, CorsProperties corsProperties) {
    this.jwtTokenService = jwtTokenService;
    this.corsProperties = corsProperties;
  }

  @Bean
  public SecurityFilterChain filterChain(HttpSecurity http) throws Exception {
    http.csrf(AbstractHttpConfigurer::disable)
        .cors(cors -> cors.configurationSource(corsConfigurationSource()))
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

  /**
   * {@code admin_web} corre en un origen de navegador distinto al del backend (SPA Flutter Web):
   * sin esto el navegador bloquea toda llamada cross-origin antes de que la request llegue a Spring
   * Security. Orígenes vienen de config por entorno (ver {@link CorsProperties}), nunca
   * hardcodeados aquí. Sin cookies de sesión (auth stateless vía header {@code Authorization}), no
   * hace falta {@code allowCredentials}.
   */
  private CorsConfigurationSource corsConfigurationSource() {
    CorsConfiguration configuration = new CorsConfiguration();
    configuration.setAllowedOrigins(corsProperties.getAllowedOrigins());
    configuration.setAllowedOriginPatterns(corsProperties.getAllowedOriginPatterns());
    configuration.setAllowedMethods(List.of("GET", "POST", "PUT", "PATCH", "DELETE", "OPTIONS"));
    configuration.setAllowedHeaders(List.of("*"));
    configuration.setAllowCredentials(false);
    configuration.setMaxAge(Duration.ofHours(1));

    UrlBasedCorsConfigurationSource source = new UrlBasedCorsConfigurationSource();
    source.registerCorsConfiguration("/**", configuration);
    return source;
  }
}
