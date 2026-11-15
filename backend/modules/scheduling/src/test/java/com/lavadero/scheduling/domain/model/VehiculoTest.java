package com.lavadero.scheduling.domain.model;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;

import java.util.UUID;
import org.junit.jupiter.api.Test;

class VehiculoTest {

  private final UUID cliente = UUID.randomUUID();

  @Test
  void laPlacaSeNormaliza() {
    assertThat(Placa.de(" abc-123 ").valor()).isEqualTo("ABC123");
    assertThat(Placa.de("abc12d").valor()).isEqualTo("ABC12D");
  }

  @Test
  void rechazaPlacasInvalidas() {
    assertThatThrownBy(() -> Placa.de("AB1")).isInstanceOf(IllegalArgumentException.class);
    assertThatThrownBy(() -> Placa.de("ABC/123")).isInstanceOf(IllegalArgumentException.class);
    assertThatThrownBy(() -> Placa.de(null)).isInstanceOf(IllegalArgumentException.class);
  }

  @Test
  void unVehiculoArchivadoNoSePuedeUsarEnUnaReserva() {
    Vehiculo v =
        Vehiculo.nuevo(
            UUID.randomUUID(), cliente, Placa.de("ABC123"), TipoVehiculo.AUTOMOVIL, " ", null);
    assertThat(v.getMarca()).isEmpty();
    assertThat(v.paraReserva().placa().valor()).isEqualTo("ABC123");

    v.archivar();

    assertThatThrownBy(v::paraReserva).isInstanceOf(IllegalStateException.class);
  }

  @Test
  void soloPerteneceASuCliente() {
    Vehiculo v =
        Vehiculo.nuevo(
            UUID.randomUUID(), cliente, Placa.de("ABC123"), TipoVehiculo.MOTO, "Yamaha", "Rojo");
    assertThat(v.perteneceA(cliente)).isTrue();
    assertThat(v.perteneceA(UUID.randomUUID())).isFalse();
  }
}
