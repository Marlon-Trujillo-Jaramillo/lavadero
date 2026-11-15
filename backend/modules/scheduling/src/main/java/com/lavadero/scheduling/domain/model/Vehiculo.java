package com.lavadero.scheduling.domain.model;

import com.lavadero.shared.domain.AggregateRoot;
import java.time.Instant;
import java.util.Objects;
import java.util.Optional;
import java.util.UUID;

/**
 * Vehículo de un cliente dentro de un lavadero ("Mis vehículos"). Archivarlo no lo borra: las
 * reservas que lo usaron lo siguen referenciando (ver docs/specs/009-mis-vehiculos.md).
 */
public class Vehiculo extends AggregateRoot<UUID> {

  static final int MARCA_MAX = 40;
  static final int COLOR_MAX = 30;

  private final UUID tenantId;
  private final UUID clienteId;
  private final Placa placa;
  private final TipoVehiculo tipo;
  private final String marca;
  private final String color;
  private boolean activo;
  private final Instant creadoEn;

  public Vehiculo(
      UUID id,
      UUID tenantId,
      UUID clienteId,
      Placa placa,
      TipoVehiculo tipo,
      String marca,
      String color,
      boolean activo,
      Instant creadoEn) {
    super(id);
    this.tenantId = Objects.requireNonNull(tenantId, "tenantId no puede ser nulo");
    this.clienteId = Objects.requireNonNull(clienteId, "clienteId no puede ser nulo");
    this.placa = Objects.requireNonNull(placa, "placa no puede ser nula");
    this.tipo = Objects.requireNonNull(tipo, "tipo no puede ser nulo");
    this.marca = textoOpcional(marca, MARCA_MAX, "marca");
    this.color = textoOpcional(color, COLOR_MAX, "color");
    this.activo = activo;
    this.creadoEn = Objects.requireNonNull(creadoEn, "creadoEn no puede ser nulo");
  }

  public static Vehiculo nuevo(
      UUID tenantId, UUID clienteId, Placa placa, TipoVehiculo tipo, String marca, String color) {
    return new Vehiculo(
        UUID.randomUUID(), tenantId, clienteId, placa, tipo, marca, color, true, Instant.now());
  }

  /** Lo quita de "Mis vehículos" sin borrarlo: las reservas pasadas lo siguen referenciando. */
  public void archivar() {
    activo = false;
  }

  public boolean perteneceA(UUID otroClienteId) {
    return clienteId.equals(otroClienteId);
  }

  public VehiculoReservado paraReserva() {
    if (!activo) {
      throw new IllegalStateException("El vehículo %s está archivado".formatted(placa));
    }
    return new VehiculoReservado(getId(), placa);
  }

  private static String textoOpcional(String valor, int max, String campo) {
    if (valor == null || valor.isBlank()) {
      return null;
    }
    String limpio = valor.strip();
    if (limpio.length() > max) {
      throw new IllegalArgumentException("%s admite hasta %d caracteres".formatted(campo, max));
    }
    return limpio;
  }

  public UUID getTenantId() {
    return tenantId;
  }

  public UUID getClienteId() {
    return clienteId;
  }

  public Placa getPlaca() {
    return placa;
  }

  public TipoVehiculo getTipo() {
    return tipo;
  }

  public Optional<String> getMarca() {
    return Optional.ofNullable(marca);
  }

  public Optional<String> getColor() {
    return Optional.ofNullable(color);
  }

  public boolean isActivo() {
    return activo;
  }

  public Instant getCreadoEn() {
    return creadoEn;
  }
}
