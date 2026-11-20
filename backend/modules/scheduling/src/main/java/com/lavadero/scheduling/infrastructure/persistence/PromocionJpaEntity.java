package com.lavadero.scheduling.infrastructure.persistence;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.Id;
import jakarta.persistence.Table;
import java.math.BigDecimal;
import java.time.Instant;
import java.time.LocalDate;
import java.time.LocalTime;
import java.util.UUID;
import org.hibernate.annotations.Filter;

/**
 * El {@code @FilterDef} vive una sola vez en {@code SucursalJpaEntity}; aquí solo se referencia.
 * {@code usos} es {@code updatable = false}: guardar la promoción (p. ej. al desactivarla) nunca
 * pisa el contador, que solo cambia con los UPDATE atómicos del repositorio.
 */
@Entity
@Table(name = "promocion")
@Filter(name = "tenantFilter", condition = "tenant_id = :tenantId")
public class PromocionJpaEntity {

  @Id private UUID id;

  @Column(name = "tenant_id", nullable = false)
  private UUID tenantId;

  @Column(nullable = false)
  private String nombre;

  @Column(nullable = false)
  private String tipo;

  private String codigo;

  @Column(name = "tipo_descuento", nullable = false)
  private String tipoDescuento;

  @Column(name = "valor_descuento", nullable = false)
  private BigDecimal valorDescuento;

  private String moneda;

  @Column(name = "dias_semana")
  private Integer diasSemana;

  @Column(name = "hora_desde")
  private LocalTime horaDesde;

  @Column(name = "hora_hasta")
  private LocalTime horaHasta;

  @Column(name = "vigente_desde", nullable = false)
  private LocalDate vigenteDesde;

  @Column(name = "vigente_hasta", nullable = false)
  private LocalDate vigenteHasta;

  @Column(name = "usos_maximos")
  private Integer usosMaximos;

  @Column(nullable = false, updatable = false)
  private int usos;

  @Column(nullable = false)
  private boolean activa;

  @Column(name = "creada_en", nullable = false)
  private Instant creadaEn;

  protected PromocionJpaEntity() {}

  @SuppressWarnings("java:S107") // espejo de las columnas de la tabla
  PromocionJpaEntity(
      UUID id,
      UUID tenantId,
      String nombre,
      String tipo,
      String codigo,
      String tipoDescuento,
      BigDecimal valorDescuento,
      String moneda,
      Integer diasSemana,
      LocalTime horaDesde,
      LocalTime horaHasta,
      LocalDate vigenteDesde,
      LocalDate vigenteHasta,
      Integer usosMaximos,
      int usos,
      boolean activa,
      Instant creadaEn) {
    this.id = id;
    this.tenantId = tenantId;
    this.nombre = nombre;
    this.tipo = tipo;
    this.codigo = codigo;
    this.tipoDescuento = tipoDescuento;
    this.valorDescuento = valorDescuento;
    this.moneda = moneda;
    this.diasSemana = diasSemana;
    this.horaDesde = horaDesde;
    this.horaHasta = horaHasta;
    this.vigenteDesde = vigenteDesde;
    this.vigenteHasta = vigenteHasta;
    this.usosMaximos = usosMaximos;
    this.usos = usos;
    this.activa = activa;
    this.creadaEn = creadaEn;
  }

  UUID getId() {
    return id;
  }

  UUID getTenantId() {
    return tenantId;
  }

  String getNombre() {
    return nombre;
  }

  String getTipo() {
    return tipo;
  }

  String getCodigo() {
    return codigo;
  }

  String getTipoDescuento() {
    return tipoDescuento;
  }

  BigDecimal getValorDescuento() {
    return valorDescuento;
  }

  String getMoneda() {
    return moneda;
  }

  Integer getDiasSemana() {
    return diasSemana;
  }

  LocalTime getHoraDesde() {
    return horaDesde;
  }

  LocalTime getHoraHasta() {
    return horaHasta;
  }

  LocalDate getVigenteDesde() {
    return vigenteDesde;
  }

  LocalDate getVigenteHasta() {
    return vigenteHasta;
  }

  Integer getUsosMaximos() {
    return usosMaximos;
  }

  int getUsos() {
    return usos;
  }

  boolean isActiva() {
    return activa;
  }

  Instant getCreadaEn() {
    return creadaEn;
  }
}
