package com.lavadero.identity.application.usecase;

import com.lavadero.identity.application.TokenIssuer;
import com.lavadero.identity.application.command.LoginCommand;
import com.lavadero.identity.application.dto.AuthResultDto;
import com.lavadero.identity.application.port.LimitadorIntentosLogin;
import com.lavadero.identity.domain.model.Usuario;
import com.lavadero.identity.domain.repository.UsuarioRepository;
import com.lavadero.shared.application.UseCase;
import com.lavadero.shared.application.exception.DemasiadosIntentosException;
import com.lavadero.shared.application.exception.ForbiddenException;
import com.lavadero.shared.security.TenantContext;
import com.lavadero.tenant.application.dto.TenantResumenDto;
import com.lavadero.tenant.application.usecase.ObtenerTenantPorSlugUseCase;
import java.util.Locale;
import java.util.Optional;
import java.util.UUID;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;

/**
 * Login: resuelve el tenant a partir de {@code X-Tenant-Slug} (si viene vacío, se interpreta como
 * intento de login de plataforma/SUPER_ADMIN), valida credenciales y emite un par access/refresh
 * token.
 *
 * <p>El header de tenant se usa SOLO aquí, para decidir en qué tenant autenticar; una vez emitido
 * el JWT, el tenant que importa para autorización es el que queda embebido en el claim {@code
 * tenant_id}, nunca un header (ver {@code TenantResolutionFilter} en infrastructure/security).
 *
 * <p>Endpoint público: sin JWT todavía, {@code TenantResolutionFilter} no puebla {@link
 * TenantContext}. Hay que fijarlo aquí explícitamente antes de leer `usuario` (RLS + FORCE) — si
 * no, la política nunca deja ver la fila (para tenantId nulo/SUPER_ADMIN no hace falta: la rama de
 * la política para filas con `tenant_id IS NULL` no exige tenant en sesión).
 *
 * <p>Endurecimiento contra enumeración y fuerza bruta:
 *
 * <ul>
 *   <li>Usuario inexistente, contraseña incorrecta y usuario bloqueado responden EXACTAMENTE igual
 *       ({@value #CREDENCIALES_INVALIDAS}), y en los tres casos se ejecuta una verificación de hash
 *       Argon2 (contra un hash señuelo si el usuario no existe): sin eso, la diferencia de tiempo
 *       delata qué emails están registrados.
 *   <li>Bloqueo por cuenta ({@link LimitadorIntentosLogin}): tras varios fallos, la cuenta se
 *       rechaza (429) sin mirar la contraseña durante un rato, aunque la contraseña sea la
 *       correcta. El intento se registra antes de verificar, para que peticiones concurrentes no
 *       esquiven el umbral.
 * </ul>
 *
 * <p>Sin {@code @Transactional} a propósito: la verificación Argon2 tarda decenas de ms y no debe
 * retener una conexión del pool. Cada acceso a datos (buscar el usuario, guardar el refresh token)
 * abre su propia transacción en el adaptador, donde {@code TenantAwareTransactionAspect} fija el
 * tenant.
 */
@Service
public class LoginUseCase implements UseCase<LoginCommand, AuthResultDto> {

  static final String CREDENCIALES_INVALIDAS = "Credenciales inválidas";
  static final String DEMASIADOS_INTENTOS = "Demasiados intentos, intenta más tarde";

  private final UsuarioRepository usuarioRepository;
  private final ObtenerTenantPorSlugUseCase obtenerTenantPorSlugUseCase;
  private final PasswordEncoder passwordEncoder;
  private final TokenIssuer tokenIssuer;
  private final LimitadorIntentosLogin limitadorIntentosLogin;

  /** Hash con el mismo algoritmo/costo que los reales, para igualar el tiempo de respuesta. */
  private final String hashSenuelo;

  public LoginUseCase(
      UsuarioRepository usuarioRepository,
      ObtenerTenantPorSlugUseCase obtenerTenantPorSlugUseCase,
      PasswordEncoder passwordEncoder,
      TokenIssuer tokenIssuer,
      LimitadorIntentosLogin limitadorIntentosLogin) {
    this.usuarioRepository = usuarioRepository;
    this.obtenerTenantPorSlugUseCase = obtenerTenantPorSlugUseCase;
    this.passwordEncoder = passwordEncoder;
    this.tokenIssuer = tokenIssuer;
    this.limitadorIntentosLogin = limitadorIntentosLogin;
    this.hashSenuelo = passwordEncoder.encode(UUID.randomUUID().toString());
  }

  @Override
  public AuthResultDto execute(LoginCommand input) {
    UUID tenantId = resolverTenantId(input.tenantSlug());
    String email = input.email().toLowerCase(Locale.ROOT);
    String claveCuenta = (tenantId == null ? "plataforma" : tenantId.toString()) + "|" + email;

    if (!limitadorIntentosLogin.registrarIntento(claveCuenta)) {
      throw new DemasiadosIntentosException(DEMASIADOS_INTENTOS);
    }

    if (tenantId != null) {
      TenantContext.set(tenantId);
    }
    try {
      Optional<Usuario> usuario = usuarioRepository.findByEmailAndTenantId(email, tenantId);
      // Siempre se verifica un hash, exista o no el usuario: mismo costo en los tres caminos.
      boolean passwordCorrecta =
          passwordEncoder.matches(
              input.password(), usuario.map(Usuario::getPasswordHash).orElse(hashSenuelo));

      if (usuario.isEmpty() || !passwordCorrecta || !usuario.get().estaActivo()) {
        throw new ForbiddenException(CREDENCIALES_INVALIDAS);
      }

      limitadorIntentosLogin.registrarExito(claveCuenta);
      return tokenIssuer.emitirParNuevo(usuario.get());
    } finally {
      TenantContext.clear();
    }
  }

  private UUID resolverTenantId(String tenantSlug) {
    if (tenantSlug == null || tenantSlug.isBlank()) {
      return null;
    }
    TenantResumenDto tenant = obtenerTenantPorSlugUseCase.execute(tenantSlug);
    return tenant.id();
  }
}
