package com.lavadero.identity.interfaces.rest.dto;

import static org.assertj.core.api.Assertions.assertThat;

import jakarta.validation.ConstraintViolation;
import jakarta.validation.Validation;
import jakarta.validation.Validator;
import java.util.Set;
import java.util.stream.Collectors;
import org.junit.jupiter.api.Test;

/** Reglas de los endpoints públicos de alta: correo válido y contraseña con tamaño razonable. */
class ValidacionAltasTest {

  private static final Validator VALIDATOR =
      Validation.buildDefaultValidatorFactory().getValidator();

  private static OnboardingTenantRequest alta(String slug, String email, String password) {
    return new OnboardingTenantRequest(
        "Lavadero Centro", "900123456-7", slug, email, password, "Dueña");
  }

  private static Set<String> camposInvalidos(Object request) {
    return VALIDATOR.validate(request).stream()
        .map(ConstraintViolation::getPropertyPath)
        .map(Object::toString)
        .collect(Collectors.toSet());
  }

  @Test
  void unAltaCorrectaPasa() {
    assertThat(camposInvalidos(alta("lavadero-centro", "duena@lavadero.com", "clave-segura")))
        .isEmpty();
  }

  @Test
  void rechazaContraseñasCortas() {
    assertThat(camposInvalidos(alta("lavadero-centro", "duena@lavadero.com", "1234567")))
        .containsExactly("adminPassword");
    assertThat(camposInvalidos(new RegisterRequest("ana@correo.com", "a", "Ana")))
        .containsExactly("password");
  }

  @Test
  void rechazaContraseñasEnormes() {
    String enorme = "x".repeat(LimitesCampos.PASSWORD_MAX + 1);
    assertThat(camposInvalidos(alta("lavadero-centro", "duena@lavadero.com", enorme)))
        .containsExactly("adminPassword");
  }

  @Test
  void rechazaCorreosInvalidos() {
    assertThat(camposInvalidos(alta("lavadero-centro", "no-es-un-correo", "clave-segura")))
        .containsExactly("adminEmail");
    assertThat(camposInvalidos(new CrearEmpleadoRequest("x", "clave-segura", "Luis", null)))
        .containsExactly("email");
  }

  @Test
  void elSlugSoloAdmiteMinusculasNumerosYGuiones() {
    assertThat(camposInvalidos(alta("Lavadero Centro", "duena@lavadero.com", "clave-segura")))
        .containsExactly("tenantSlug");
    assertThat(camposInvalidos(alta("ab", "duena@lavadero.com", "clave-segura")))
        .containsExactly("tenantSlug");
  }
}
