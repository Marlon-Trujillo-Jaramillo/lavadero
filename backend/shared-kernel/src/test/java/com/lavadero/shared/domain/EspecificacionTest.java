package com.lavadero.shared.domain;

import static org.assertj.core.api.Assertions.assertThat;

import org.junit.jupiter.api.Test;

class EspecificacionTest {

  private final Especificacion<Integer> esPar = n -> n % 2 == 0;
  private final Especificacion<Integer> esPositivo = n -> n > 0;

  @Test
  void and_exige_que_ambas_especificaciones_se_cumplan() {
    Especificacion<Integer> parYPositivo = esPar.and(esPositivo);

    assertThat(parYPositivo.isSatisfiedBy(4)).isTrue();
    assertThat(parYPositivo.isSatisfiedBy(-4)).isFalse();
    assertThat(parYPositivo.isSatisfiedBy(3)).isFalse();
  }

  @Test
  void or_exige_que_al_menos_una_se_cumpla() {
    Especificacion<Integer> parOPositivo = esPar.or(esPositivo);

    assertThat(parOPositivo.isSatisfiedBy(-4)).isTrue();
    assertThat(parOPositivo.isSatisfiedBy(3)).isTrue();
    assertThat(parOPositivo.isSatisfiedBy(-3)).isFalse();
  }

  @Test
  void not_invierte_el_resultado() {
    Especificacion<Integer> esImpar = esPar.not();

    assertThat(esImpar.isSatisfiedBy(3)).isTrue();
    assertThat(esImpar.isSatisfiedBy(4)).isFalse();
  }

  @Test
  void las_especificaciones_son_componibles_en_cadena() {
    Especificacion<Integer> compuesta = esPar.and(esPositivo).or(esPar.not());

    assertThat(compuesta.isSatisfiedBy(2)).isTrue(); // par y positivo
    assertThat(compuesta.isSatisfiedBy(3)).isTrue(); // impar
    assertThat(compuesta.isSatisfiedBy(-2)).isFalse(); // par pero no positivo, ni impar
  }
}
