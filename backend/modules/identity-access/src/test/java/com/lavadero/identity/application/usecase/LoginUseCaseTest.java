package com.lavadero.identity.application.usecase;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.anyString;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.never;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

import com.lavadero.identity.application.TokenIssuer;
import com.lavadero.identity.application.command.LoginCommand;
import com.lavadero.identity.application.dto.AuthResultDto;
import com.lavadero.identity.application.port.LimitadorIntentosLogin;
import com.lavadero.identity.domain.model.Usuario;
import com.lavadero.identity.domain.repository.UsuarioRepository;
import com.lavadero.shared.application.exception.DemasiadosIntentosException;
import com.lavadero.shared.application.exception.ForbiddenException;
import com.lavadero.tenant.application.dto.TenantResumenDto;
import com.lavadero.tenant.application.usecase.ObtenerTenantPorSlugUseCase;
import java.util.Optional;
import java.util.UUID;
import java.util.concurrent.atomic.AtomicInteger;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.springframework.security.crypto.password.PasswordEncoder;

class LoginUseCaseTest {

  private static final UUID TENANT_ID = UUID.randomUUID();
  private static final String CLAVE = TENANT_ID + "|ana@lavadero.com";

  private final UsuarioRepository usuarios = mock(UsuarioRepository.class);
  private final ObtenerTenantPorSlugUseCase tenants = mock(ObtenerTenantPorSlugUseCase.class);
  private final TokenIssuer tokenIssuer = mock(TokenIssuer.class);
  private final LimitadorIntentosLogin limitador = mock(LimitadorIntentosLogin.class);
  private final AtomicInteger verificacionesDeHash = new AtomicInteger();
  private final PasswordEncoder encoder =
      new PasswordEncoder() {
        @Override
        public String encode(CharSequence raw) {
          return "h:" + raw;
        }

        @Override
        public boolean matches(CharSequence raw, String hash) {
          verificacionesDeHash.incrementAndGet();
          return hash.equals("h:" + raw);
        }
      };

  private LoginUseCase useCase;

  @BeforeEach
  void setUp() {
    when(limitador.registrarIntento(anyString())).thenReturn(true);
    when(tenants.execute("lavadero-uno"))
        .thenReturn(new TenantResumenDto(TENANT_ID, "lavadero-uno", "Lavadero"));
    useCase = new LoginUseCase(usuarios, tenants, encoder, tokenIssuer, limitador);
  }

  @Test
  void loginCorrectoNormalizaElEmailYLimpiaLosFallos() {
    Usuario ana = Usuario.cliente(TENANT_ID, "ana@lavadero.com", "Ana", "h:secreta");
    when(usuarios.findByEmailAndTenantId("ana@lavadero.com", TENANT_ID))
        .thenReturn(Optional.of(ana));
    AuthResultDto esperado = new AuthResultDto("access", "refresh", 900, null);
    when(tokenIssuer.emitirParNuevo(ana)).thenReturn(esperado);

    assertThat(useCase.execute(login("Ana@Lavadero.com", "secreta"))).isSameAs(esperado);
    verify(limitador).registrarExito(CLAVE);
  }

  @Test
  void usuarioInexistenteVerificaUnHashSenueloYRespondeIgual() {
    when(usuarios.findByEmailAndTenantId(anyString(), any())).thenReturn(Optional.empty());

    assertThatThrownBy(() -> useCase.execute(login("ana@lavadero.com", "x")))
        .isInstanceOf(ForbiddenException.class)
        .hasMessage(LoginUseCase.CREDENCIALES_INVALIDAS);
    assertThat(verificacionesDeHash.get())
        .as("mismo costo que con un usuario real: no se puede enumerar por tiempo")
        .isEqualTo(1);
    verify(limitador).registrarIntento(CLAVE);
    verify(limitador, never()).registrarExito(anyString());
  }

  @Test
  void passwordIncorrectaYUsuarioBloqueadoDanElMismoMensaje() {
    Usuario ana = Usuario.cliente(TENANT_ID, "ana@lavadero.com", "Ana", "h:secreta");
    when(usuarios.findByEmailAndTenantId("ana@lavadero.com", TENANT_ID))
        .thenReturn(Optional.of(ana));

    assertThatThrownBy(() -> useCase.execute(login("ana@lavadero.com", "mala")))
        .hasMessage(LoginUseCase.CREDENCIALES_INVALIDAS);

    ana.bloquear();
    assertThatThrownBy(() -> useCase.execute(login("ana@lavadero.com", "secreta")))
        .isInstanceOf(ForbiddenException.class)
        .hasMessage(LoginUseCase.CREDENCIALES_INVALIDAS);
    verify(tokenIssuer, never()).emitirParNuevo(any());
  }

  @Test
  void cuentaBloqueadaSeRechazaCon429SinMirarLaPassword() {
    when(limitador.registrarIntento(CLAVE)).thenReturn(false);

    assertThatThrownBy(() -> useCase.execute(login("ana@lavadero.com", "secreta")))
        .isInstanceOf(DemasiadosIntentosException.class)
        .hasMessage(LoginUseCase.DEMASIADOS_INTENTOS);
    verify(usuarios, never()).findByEmailAndTenantId(anyString(), any());
    assertThat(verificacionesDeHash.get()).isZero();
  }

  private static LoginCommand login(String email, String password) {
    return new LoginCommand("lavadero-uno", email, password);
  }
}
