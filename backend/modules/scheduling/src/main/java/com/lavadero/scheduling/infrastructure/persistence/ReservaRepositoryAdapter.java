package com.lavadero.scheduling.infrastructure.persistence;

import com.lavadero.scheduling.domain.model.Placa;
import com.lavadero.scheduling.domain.model.Reserva;
import com.lavadero.scheduling.domain.model.ReservaEstado;
import com.lavadero.scheduling.domain.model.ResumenVentas;
import com.lavadero.scheduling.domain.model.ServicioPopular;
import com.lavadero.scheduling.domain.model.VehiculoReservado;
import com.lavadero.scheduling.domain.repository.ReservaRepository;
import com.lavadero.shared.domain.Money;
import java.time.Instant;
import java.util.List;
import java.util.Optional;
import java.util.UUID;
import org.springframework.data.domain.PageRequest;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.jdbc.core.RowCallbackHandler;
import org.springframework.stereotype.Repository;
import org.springframework.transaction.annotation.Propagation;
import org.springframework.transaction.annotation.Transactional;

/**
 * Adaptador de {@link ReservaRepository} — mismo patrón (`@Transactional` explícito) que
 * catalog/tenant-management.
 */
@Repository
class ReservaRepositoryAdapter implements ReservaRepository {

  private static final List<String> ESTADOS_ACTIVOS =
      List.of(ReservaEstado.PENDIENTE.name(), ReservaEstado.EN_PROGRESO.name());

  private final ReservaJpaRepository jpaRepository;
  private final JdbcTemplate jdbcTemplate;

  ReservaRepositoryAdapter(ReservaJpaRepository jpaRepository, JdbcTemplate jdbcTemplate) {
    this.jpaRepository = jpaRepository;
    this.jdbcTemplate = jdbcTemplate;
  }

  @Override
  @Transactional(readOnly = true)
  public Optional<Reserva> findById(UUID id) {
    return jpaRepository.findById(id).map(ReservaRepositoryAdapter::toDomain);
  }

  @Override
  @Transactional(readOnly = true)
  public List<Reserva> findActivasPorSucursalYRango(UUID sucursalId, Instant desde, Instant hasta) {
    return jpaRepository
        .findBySucursalIdAndEstadoInAndFechaHoraInicioLessThanAndFechaHoraFinGreaterThan(
            sucursalId, ESTADOS_ACTIVOS, hasta, desde)
        .stream()
        .map(ReservaRepositoryAdapter::toDomain)
        .toList();
  }

  /**
   * Advisory lock de transacción (se libera solo al commit/rollback). MANDATORY: fuera de una
   * transacción el lock se soltaría en el acto y no protegería nada.
   */
  @Override
  @Transactional(propagation = Propagation.MANDATORY)
  public void bloquearAgendaDeSucursal(UUID sucursalId) {
    long clave = sucursalId.getMostSignificantBits() ^ sucursalId.getLeastSignificantBits();
    jdbcTemplate.query("select pg_advisory_xact_lock(?)", (RowCallbackHandler) rs -> {}, clave);
  }

  @Override
  @Transactional(readOnly = true)
  public List<Reserva> findPorSucursalYRango(UUID sucursalId, Instant desde, Instant hasta) {
    return jpaRepository
        .findBySucursalIdAndFechaHoraInicioGreaterThanEqualAndFechaHoraInicioLessThan(
            sucursalId, desde, hasta)
        .stream()
        .map(ReservaRepositoryAdapter::toDomain)
        .toList();
  }

  @Override
  @Transactional(readOnly = true)
  public List<Reserva> findPorCliente(UUID clienteId, Instant desde, int limite) {
    PageRequest pagina = PageRequest.of(0, limite);
    var filas =
        desde == null
            ? jpaRepository.findByClienteIdOrderByFechaHoraInicioDesc(clienteId, pagina)
            : jpaRepository
                .findByClienteIdAndFechaHoraInicioGreaterThanEqualOrderByFechaHoraInicioDesc(
                    clienteId, desde, pagina);
    return filas.stream().map(ReservaRepositoryAdapter::toDomain).toList();
  }

  @Override
  @Transactional(readOnly = true)
  public ResumenVentas obtenerResumenVentas(Instant desde, Instant hasta, UUID sucursalId) {
    var totales =
        sucursalId == null
            ? jpaRepository.obtenerTotales(desde, hasta)
            : jpaRepository.obtenerTotalesDeSucursal(desde, hasta, sucursalId);
    var populares =
        sucursalId == null
            ? jpaRepository.obtenerServiciosMasPedidos(desde, hasta)
            : jpaRepository.obtenerServiciosMasPedidosDeSucursal(desde, hasta, sucursalId);
    var serviciosMasPedidos =
        populares.stream()
            .map(p -> new ServicioPopular(p.getServicioId(), p.getNombre(), p.getCantidad()))
            .toList();
    return new ResumenVentas(
        Money.de(totales.getIngresos(), totales.getMoneda()),
        totales.getTotal().intValue(),
        serviciosMasPedidos);
  }

  @Override
  @Transactional
  public Reserva save(Reserva reserva) {
    ReservaJpaEntity entity =
        new ReservaJpaEntity(
            reserva.getId(),
            reserva.getTenantId(),
            reserva.getSucursalId(),
            reserva.getServicioId(),
            reserva.getClienteId(),
            reserva.getFechaHoraInicio(),
            reserva.getFechaHoraFin(),
            reserva.getDuracionEstimadaMinutos(),
            reserva.getPrecio().monto(),
            reserva.getPrecio().moneda().getCurrencyCode(),
            reserva.getEstado().name(),
            reserva.getVehiculo().map(VehiculoReservado::vehiculoId).orElse(null),
            reserva.getVehiculo().map(v -> v.placa().valor()).orElse(null));
    jpaRepository.save(entity);
    return reserva;
  }

  private static Reserva toDomain(ReservaJpaEntity entity) {
    return new Reserva(
        entity.getId(),
        entity.getTenantId(),
        entity.getSucursalId(),
        entity.getServicioId(),
        entity.getClienteId(),
        entity.getFechaHoraInicio(),
        entity.getDuracionEstimadaMinutos(),
        Money.de(entity.getPrecio(), entity.getMoneda()),
        ReservaEstado.valueOf(entity.getEstado()),
        entity.getVehiculoId() == null
            ? null
            : new VehiculoReservado(entity.getVehiculoId(), new Placa(entity.getVehiculoPlaca())));
  }
}
