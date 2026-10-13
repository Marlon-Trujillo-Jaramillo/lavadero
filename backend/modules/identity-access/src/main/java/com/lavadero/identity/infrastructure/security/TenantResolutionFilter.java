package com.lavadero.identity.infrastructure.security;

import com.lavadero.shared.security.PrincipalAutenticado;
import com.lavadero.shared.security.TenantContext;
import jakarta.servlet.FilterChain;
import jakarta.servlet.ServletException;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import java.io.IOException;
import org.springframework.security.core.Authentication;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.web.filter.OncePerRequestFilter;

/**
 * Puebla {@link TenantContext} para el hilo de la request en curso, a partir del claim {@code
 * tenant_id} del JWT YA VALIDADO por {@link JwtAuthenticationFilter} (nunca de un header, en
 * endpoints autenticados: confiar en un header de cliente para decidir el tenant permitiría a
 * cualquiera suplantar otro tenant con solo cambiar un header).
 *
 * <p>Para los endpoints públicos (lista blanca explícita, ver {@link #ES_PUBLICO}) no exige tenant:
 * si no hay autenticación, simplemente no setea nada (algunos de esos endpoints, como login, leen
 * el tenant desde {@code X-Tenant-Slug} pero eso lo hace el caso de uso directamente, no este
 * filtro, y solo para decidir en qué tenant buscar el usuario — NO para autorización).
 *
 * <p>SIEMPRE limpia el contexto en un {@code finally}, para que un hilo reutilizado por el servidor
 * (pool de threads) no arrastre el tenant de una request anterior.
 */
public class TenantResolutionFilter extends OncePerRequestFilter {

  @Override
  protected void doFilterInternal(
      HttpServletRequest request, HttpServletResponse response, FilterChain filterChain)
      throws ServletException, IOException {
    try {
      Authentication authentication = SecurityContextHolder.getContext().getAuthentication();
      if (authentication != null
          && authentication.getPrincipal() instanceof PrincipalAutenticado principal
          && principal.tenantId() != null) {
        TenantContext.set(principal.tenantId());
      }
      filterChain.doFilter(request, response);
    } finally {
      TenantContext.clear();
    }
  }
}
