package com.lavadero.identity.infrastructure.security;

import io.jsonwebtoken.Claims;
import io.jsonwebtoken.JwtException;
import io.jsonwebtoken.Jwts;
import jakarta.servlet.FilterChain;
import jakarta.servlet.ServletException;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import java.io.IOException;
import java.util.List;
import java.util.Set;
import java.util.UUID;
import java.util.stream.Collectors;
import org.springframework.security.authentication.UsernamePasswordAuthenticationToken;
import org.springframework.security.core.GrantedAuthority;
import org.springframework.security.core.authority.SimpleGrantedAuthority;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.web.filter.OncePerRequestFilter;

/**
 * Valida el access token JWT (firma + expiración) y, si es válido, puebla el {@code
 * SecurityContext} con un principal {@link JwtAuthenticatedPrincipal} y las authorities derivadas
 * del claim {@code roles} (prefijo {@code ROLE_}, requerido por {@code hasRole(...)} de Spring
 * Security).
 *
 * <p>Se ejecuta ANTES de {@link TenantResolutionFilter}: primero se autentica (se confía en la
 * firma), y solo después se resuelve el tenant a partir del claim ya validado.
 *
 * <p>No lanza excepción si el token falta o es inválido: simplemente deja el contexto sin
 * autenticar y delega en Spring Security (que responderá 401/403 según la regla de autorización del
 * endpoint). Esto permite que los endpoints públicos (lista blanca) sigan funcionando sin token.
 */
public class JwtAuthenticationFilter extends OncePerRequestFilter {

  private final JwtTokenService jwtTokenService;

  public JwtAuthenticationFilter(JwtTokenService jwtTokenService) {
    this.jwtTokenService = jwtTokenService;
  }

  @Override
  protected void doFilterInternal(
      HttpServletRequest request, HttpServletResponse response, FilterChain filterChain)
      throws ServletException, IOException {

    String header = request.getHeader("Authorization");
    if (header != null && header.startsWith("Bearer ")) {
      String token = header.substring("Bearer ".length());
      try {
        autenticar(token);
      } catch (JwtException | IllegalArgumentException e) {
        SecurityContextHolder.clearContext();
      }
    }
    filterChain.doFilter(request, response);
  }

  private void autenticar(String token) {
    Claims claims =
        Jwts.parser()
            .requireIssuer(jwtTokenService.getIssuer())
            .setSigningKey(jwtTokenService.getFirmaKey())
            .build()
            .parseSignedClaims(token)
            .getPayload();

    UUID usuarioId = UUID.fromString(claims.getSubject());
    UUID tenantId =
        claims.get(JwtTokenService.CLAIM_TENANT_ID, String.class) != null
            ? UUID.fromString(claims.get(JwtTokenService.CLAIM_TENANT_ID, String.class))
            : null;
    UUID sucursalId =
        claims.get(JwtTokenService.CLAIM_SUCURSAL_ID, String.class) != null
            ? UUID.fromString(claims.get(JwtTokenService.CLAIM_SUCURSAL_ID, String.class))
            : null;

    @SuppressWarnings("unchecked")
    List<String> rolesClaim = claims.get(JwtTokenService.CLAIM_ROLES, List.class);
    Set<String> roles = rolesClaim == null ? Set.of() : Set.copyOf(rolesClaim);

    JwtAuthenticatedPrincipal principal =
        new JwtAuthenticatedPrincipal(usuarioId, tenantId, sucursalId, roles, claims.getId());

    List<GrantedAuthority> authorities =
        roles.stream()
            .map(rol -> new SimpleGrantedAuthority("ROLE_" + rol))
            .collect(Collectors.toList());

    var authentication = new UsernamePasswordAuthenticationToken(principal, null, authorities);
    SecurityContextHolder.getContext().setAuthentication(authentication);
  }
}
