package com.lavadero.scheduling.infrastructure.persistence;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.Id;
import jakarta.persistence.Table;
import java.math.BigDecimal;
import java.time.Instant;
import java.util.UUID;
import org.hibernate.annotations.Filter;

/**
 * Entidad JPA de {@code Reserva}. {@code fechaHoraFin} se guarda calculada (denormalizada) al
 * momento de persistir, en vez de derivarla en cada lectura, para poder hacer la consulta de
 * solapamiento de horarios ({@code ReservaJpaRepository}) directamente en SQL — evita traer TODAS
 * las reservas de la sucursal a memoria para filtrar ahí, que no escala.
 *
 * <p>El {@code @FilterDef} vive UNA sola vez, en {@code SucursalJpaEntity} (tenant-management):
 * Hibernate rechaza (error de arranque) que dos entidades del mismo persistence unit declaren un
 * {@code @FilterDef} con el mismo nombre — aquí solo se referencia por nombre con {@code @Filter}.
 */
@Entity
@Table(name = "reserva")
@Filter(name = "tenantFilter", condition = "tenant_id = :tenantId")
public class ReservaJpaEntity {

  @Id private UUID id;

  @Column(name = "tenant_id", nullable = false)
  private UUID tenantId;

  @Column(name = "sucursal_id", nullable = false)
  private UUID sucursalId;

  @Column(name = "servicio_id", nullable = false)
  private UUID servicioId;

  @Column(name = "cliente_id", nullable = false)
  private UUID clienteId;

  @Column(name = "fecha_hora_inicio", nullable = false)
  private Instant fechaHoraInicio;

  @Column(name = "fecha_hora_fin", nullable = false)
  private Instant fechaHoraFin;

  @Column(name = "duracion_estimada_minutos", nullable = false)
  private int duracionEstimadaMinutos;

  @Column(nullable = false)
  private BigDecimal precio;

  @Column(nullable = false)
  private String moneda;

  @Column(nullable = false)
  private String estado;

  protected ReservaJpaEntity() {}

  public ReservaJpaEntity(
      UUID id,
      UUID tenantId,
      UUID sucursalId,
      UUID servicioId,
      UUID clienteId,
      Instant fechaHoraInicio,
      Instant fechaHoraFin,
      int duracionEstimadaMinutos,
      BigDecimal precio,
      String moneda,
      String estado) {
    this.id = id;
    this.tenantId = tenantId;
    this.sucursalId = sucursalId;
    this.servicioId = servicioId;
    this.clienteId = clienteId;
    this.fechaHoraInicio = fechaHoraInicio;
    this.fechaHoraFin = fechaHoraFin;
    this.duracionEstimadaMinutos = duracionEstimadaMinutos;
    this.precio = precio;
    this.moneda = moneda;
    this.estado = estado;
  }

  public UUID getId() {
    return id;
  }

  public UUID getTenantId() {
    return tenantId;
  }

  public UUID getSucursalId() {
    return sucursalId;
  }

  public UUID getServicioId() {
    return servicioId;
  }

  public UUID getClienteId() {
    return clienteId;
  }

  public Instant getFechaHoraInicio() {
    return fechaHoraInicio;
  }

  public Instant getFechaHoraFin() {
    return fechaHoraFin;
  }

  public int getDuracionEstimadaMinutos() {
    return duracionEstimadaMinutos;
  }

  public BigDecimal getPrecio() {
    return precio;
  }

  public String getMoneda() {
    return moneda;
  }

  public String getEstado() {
    return estado;
  }
}
