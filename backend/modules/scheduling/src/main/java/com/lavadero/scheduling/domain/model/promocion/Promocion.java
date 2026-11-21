package com.lavadero.scheduling.domain.model.promocion;

import com.lavadero.shared.domain.AggregateRoot;
import com.lavadero.shared.domain.Money;
import java.time.Instant;
import java.time.LocalDate;
import java.time.LocalDateTime;
import java.time.ZoneId;
import java.util.Objects;
import java.util.Optional;
import java.util.UUID;

/**
 * Una promoción del lavadero: un cupón con código o un precio por horario. Desactivarla no la
 * borra: las reservas que la usaron la siguen referenciando y sus resultados se siguen viendo. Ver
 * docs/specs/011-promociones.md.
 */
public class Promocion extends AggregateRoot<UUID> {

  /**
   * Zona en la que se leen las franjas y la vigencia. Hoy todos los lavaderos están en Colombia
   * (cobran en COP con Wompi); cuando haya otro país, esto pasa a ser un dato del tenant.
   */
  public static final ZoneId ZONA_HORARIA = ZoneId.of("America/Bogota");

  static final int NOMBRE_MAX = 60;

  private final UUID tenantId;
  private final String nombre;
  private final TipoPromocion tipo;
  private final CodigoCupon codigo;
  private final Descuento descuento;
  private final FranjaHoraria franja;
  private final LocalDate vigenteDesde;
  private final LocalDate vigenteHasta;
  private final Integer usosMaximos;
  private final int usos;
  private boolean activa;
  private final Instant creadaEn;

  public Promocion(
      UUID id,
      UUID tenantId,
      String nombre,
      TipoPromocion tipo,
      CodigoCupon codigo,
      Descuento descuento,
      FranjaHoraria franja,
      LocalDate vigenteDesde,
      LocalDate vigenteHasta,
      Integer usosMaximos,
      int usos,
      boolean activa,
      Instant creadaEn) {
    super(id);
    this.tenantId = Objects.requireNonNull(tenantId, "tenantId no puede ser nulo");
    this.nombre = nombreValido(nombre);
    this.tipo = Objects.requireNonNull(tipo, "tipo no puede ser nulo");
    this.descuento = Objects.requireNonNull(descuento, "descuento no puede ser nulo");
    if ((tipo == TipoPromocion.CUPON) != (codigo != null)) {
      throw new IllegalArgumentException("Solo un cupón lleva código, y todo cupón lo necesita");
    }
    if ((tipo == TipoPromocion.HORARIO) != (franja != null)) {
      throw new IllegalArgumentException(
          "Solo un precio por horario lleva franja, y todo precio por horario la necesita");
    }
    this.codigo = codigo;
    this.franja = franja;
    this.vigenteDesde = Objects.requireNonNull(vigenteDesde, "vigenteDesde no puede ser nulo");
    this.vigenteHasta = Objects.requireNonNull(vigenteHasta, "vigenteHasta no puede ser nulo");
    if (vigenteHasta.isBefore(vigenteDesde)) {
      throw new IllegalArgumentException("La vigencia termina antes de empezar");
    }
    if (usosMaximos != null && usosMaximos < 1) {
      throw new IllegalArgumentException("El máximo de usos debe ser al menos 1");
    }
    this.usosMaximos = usosMaximos;
    this.usos = usos;
    this.activa = activa;
    this.creadaEn = Objects.requireNonNull(creadaEn, "creadaEn no puede ser nulo");
  }

  public static Promocion cupon(
      UUID tenantId,
      String nombre,
      CodigoCupon codigo,
      Descuento descuento,
      LocalDate vigenteDesde,
      LocalDate vigenteHasta,
      Integer usosMaximos,
      Instant ahora) {
    return new Promocion(
        UUID.randomUUID(),
        tenantId,
        nombre,
        TipoPromocion.CUPON,
        Objects.requireNonNull(codigo, "un cupón necesita código"),
        descuento,
        null,
        vigenteDesde,
        vigenteHasta,
        usosMaximos,
        0,
        true,
        ahora);
  }

  public static Promocion horario(
      UUID tenantId,
      String nombre,
      FranjaHoraria franja,
      Descuento descuento,
      LocalDate vigenteDesde,
      LocalDate vigenteHasta,
      Instant ahora) {
    return new Promocion(
        UUID.randomUUID(),
        tenantId,
        nombre,
        TipoPromocion.HORARIO,
        null,
        descuento,
        Objects.requireNonNull(franja, "un precio por horario necesita franja"),
        vigenteDesde,
        vigenteHasta,
        null,
        0,
        true,
        ahora);
  }

  /**
   * Por qué esta promoción no aplica a una reserva que empieza en {@code inicio}, o vacío si
   * aplica. El mensaje es para el cliente.
   */
  public Optional<String> motivoNoAplica(Instant inicio) {
    LocalDateTime local = LocalDateTime.ofInstant(inicio, ZONA_HORARIA);
    LocalDate dia = local.toLocalDate();
    if (!activa) {
      return Optional.of("La promoción '%s' ya no está activa".formatted(nombre));
    }
    if (dia.isBefore(vigenteDesde)) {
      return Optional.of("La promoción '%s' empieza a regir el %s".formatted(nombre, vigenteDesde));
    }
    if (dia.isAfter(vigenteHasta)) {
      return Optional.of("La promoción '%s' venció el %s".formatted(nombre, vigenteHasta));
    }
    if (agotada()) {
      return Optional.of("La promoción '%s' ya se agotó".formatted(nombre));
    }
    if (franja != null && !franja.contiene(local)) {
      return Optional.of("La promoción '%s' no aplica en ese horario".formatted(nombre));
    }
    return Optional.empty();
  }

  public boolean aplicaA(Instant inicio) {
    return motivoNoAplica(inicio).isEmpty();
  }

  public Money descuentoSobre(Money precioLista) {
    return descuento.calcular(precioLista);
  }

  public boolean agotada() {
    return usosMaximos != null && usos >= usosMaximos;
  }

  public void desactivar() {
    activa = false;
  }

  private static String nombreValido(String nombre) {
    Objects.requireNonNull(nombre, "nombre no puede ser nulo");
    String limpio = nombre.strip();
    if (limpio.isEmpty() || limpio.length() > NOMBRE_MAX) {
      throw new IllegalArgumentException(
          "El nombre de la promoción debe tener entre 1 y " + NOMBRE_MAX + " caracteres");
    }
    return limpio;
  }

  public UUID getTenantId() {
    return tenantId;
  }

  public String getNombre() {
    return nombre;
  }

  public TipoPromocion getTipo() {
    return tipo;
  }

  public Optional<CodigoCupon> getCodigo() {
    return Optional.ofNullable(codigo);
  }

  public Descuento getDescuento() {
    return descuento;
  }

  public Optional<FranjaHoraria> getFranja() {
    return Optional.ofNullable(franja);
  }

  public LocalDate getVigenteDesde() {
    return vigenteDesde;
  }

  public LocalDate getVigenteHasta() {
    return vigenteHasta;
  }

  public Optional<Integer> getUsosMaximos() {
    return Optional.ofNullable(usosMaximos);
  }

  public int getUsos() {
    return usos;
  }

  public boolean isActiva() {
    return activa;
  }

  public Instant getCreadaEn() {
    return creadaEn;
  }
}
