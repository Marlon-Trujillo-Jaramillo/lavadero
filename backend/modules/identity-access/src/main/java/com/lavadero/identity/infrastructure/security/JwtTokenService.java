package com.lavadero.identity.infrastructure.security;

import com.lavadero.identity.application.port.TokenService;
import com.lavadero.identity.domain.model.Rol;
import com.lavadero.identity.domain.model.Usuario;
import io.jsonwebtoken.Jwts;
import io.jsonwebtoken.SignatureAlgorithm;
import io.jsonwebtoken.security.Keys;
import java.security.Key;
import java.security.SecureRandom;
import java.time.Duration;
import java.time.Instant;
import java.util.Base64;
import java.util.Date;
import java.util.UUID;
import java.util.stream.Collectors;
import org.springframework.boot.context.properties.EnableConfigurationProperties;
import org.springframework.stereotype.Component;

/**
 * Implementación JJWT del puerto {@link TokenService}.
 *
 * <p>DECISIÓN DE DISEÑO (HS256 vs RS256): se elige HS256 (firma simétrica). El backend es un
 * monolito modular desplegado como UN SOLO proceso: el mismo proceso que firma el access token es
 * el único que lo valida (no hay otro servicio independiente verificando tokens sin poder
 * firmarlos). RS256 (asimétrico) solo aporta valor cuando la verificación debe ocurrir en un
 * proceso que NO debe tener la capacidad de firmar (p. ej. un gateway o un microservicio separado);
 * eso no aplica aquí y añadiría complejidad de gestión de claves (par pública/privada, rotación)
 * sin beneficio real en esta fase. Si en el futuro se extrae un servicio (p. ej. un API Gateway
 * externo) que solo necesite verificar, migrar a RS256 es sencillo porque todo el acceso al secreto
 * está encapsulado aquí.
 */
@Component
@EnableConfigurationProperties(JwtProperties.class)
public class JwtTokenService implements TokenService {

  public static final String CLAIM_TENANT_ID = "tenant_id";
  public static final String CLAIM_ROLES = "roles";
  public static final String CLAIM_SUCURSAL_ID = "sucursal_id";

  private final JwtProperties properties;
  private final Key firmaKey;
  private final SecureRandom secureRandom = new SecureRandom();

  public JwtTokenService(JwtProperties properties) {
    this.properties = properties;
    this.firmaKey = Keys.hmacShaKeyFor(Base64.getDecoder().decode(properties.getSecret()));
  }

  @SuppressWarnings("deprecation")
  @Override
  public String generarAccessToken(Usuario usuario) {
    Instant ahora = Instant.now();
    Instant expira = ahora.plus(properties.getAccessTokenTtl());

    var builder =
        Jwts.builder()
            .setSubject(usuario.getId().toString())
            .setIssuer(properties.getIssuer())
            .setId(UUID.randomUUID().toString())
            .setIssuedAt(Date.from(ahora))
            .setExpiration(Date.from(expira))
            .claim(
                CLAIM_ROLES,
                usuario.getRoles().stream().map(Rol::name).collect(Collectors.toList()));

    usuario
        .getTenantId()
        .ifPresent(tenantId -> builder.claim(CLAIM_TENANT_ID, tenantId.toString()));
    usuario
        .getSucursalId()
        .ifPresent(sucursalId -> builder.claim(CLAIM_SUCURSAL_ID, sucursalId.toString()));

    return builder.signWith(firmaKey, SignatureAlgorithm.HS256).compact();
  }

  @Override
  public Duration duracionAccessToken() {
    return properties.getAccessTokenTtl();
  }

  @Override
  public String generarRefreshTokenOpaco() {
    byte[] bytes = new byte[64];
    secureRandom.nextBytes(bytes);
    return Base64.getUrlEncoder().withoutPadding().encodeToString(bytes);
  }

  Key getFirmaKey() {
    return firmaKey;
  }

  String getIssuer() {
    return properties.getIssuer();
  }
}
