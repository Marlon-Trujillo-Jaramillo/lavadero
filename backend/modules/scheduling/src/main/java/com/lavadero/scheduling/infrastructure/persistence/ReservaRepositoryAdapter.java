package com.lavadero.scheduling.infrastructure.persistence;

import com.lavadero.scheduling.domain.model.Reserva;
import com.lavadero.scheduling.domain.model.ReservaEstado;
import com.lavadero.scheduling.domain.model.ResumenVentas;
import com.lavadero.scheduling.domain.model.ServicioPopular;
import com.lavadero.scheduling.domain.repository.ReservaRepository;
import com.lavadero.shared.domain.Money;
import java.time.Instant;
import java.util.List;
import java.util.Optional;
import java.util.UUID;
import org.springframework.stereotype.Repository;
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

  ReservaRepositoryAdapter(ReservaJpaRepository jpaRepository) {
    this.jpaRepository = jpaRepository;
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

  @Override
  @Transactional(readOnly = true)
  public List<Reserva> findPorSucursalYRango(UUID sucursalId, Instant desde, Instant hasta) {
    return jpaRepository
        .findBySucursalIdAndFechaHoraInicioBetween(sucursalId, desde, hasta)
        .stream()
        .map(ReservaRepositoryAdapter::toDomain)
        .toList();
  }

  @Override
  @Transactional(readOnly = true)
  public List<Reserva> findPorCliente(UUID clienteId) {
    return jpaRepository.findByClienteId(clienteId).stream()
        .map(ReservaRepositoryAdapter::toDomain)
        .toList();
  }

  @Override
  @Transactional(readOnly = true)
  public ResumenVentas obtenerResumenVentas(Instant desde, Instant hasta) {
    var totales = jpaRepository.obtenerTotales(desde, hasta);
    var serviciosMasPedidos =
        jpaRepository.obtenerServiciosMasPedidos(desde, hasta).stream()
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
            reserva.getEstado().name());
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
        ReservaEstado.valueOf(entity.getEstado()));
  }
}
