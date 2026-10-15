package com.lavadero.scheduling.infrastructure.persistence;

import java.math.BigDecimal;
import java.time.Instant;
import java.util.Collection;
import java.util.List;
import java.util.UUID;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

/**
 * Repositorio Spring Data. La consulta de solapamiento ({@code inicio < hasta AND fin > desde}, la
 * condición estándar para "estos dos rangos se cruzan") corre en la base de datos, no en memoria:
 * necesario para que la validación de disponibilidad escale con el volumen de reservas. Las
 * consultas del resumen de ventas son nativas (SQL directo, con JOIN a `servicio`) — ver el porqué
 * en docs/specs/003-dashboard-reportes.md. RLS aplica igual: es a nivel de conexión, no de la forma
 * de la query.
 */
interface ReservaJpaRepository extends JpaRepository<ReservaJpaEntity, UUID> {

  List<ReservaJpaEntity>
      findBySucursalIdAndEstadoInAndFechaHoraInicioLessThanAndFechaHoraFinGreaterThan(
          UUID sucursalId,
          Collection<String> estados,
          Instant fechaHoraInicioMenorQue,
          Instant fechaHoraFinMayorQue);

  List<ReservaJpaEntity>
      findBySucursalIdAndFechaHoraInicioGreaterThanEqualAndFechaHoraInicioLessThan(
          UUID sucursalId, Instant desde, Instant hasta);

  List<ReservaJpaEntity> findByClienteIdOrderByFechaHoraInicioDesc(UUID clienteId, Pageable pagina);

  List<ReservaJpaEntity>
      findByClienteIdAndFechaHoraInicioGreaterThanEqualOrderByFechaHoraInicioDesc(
          UUID clienteId, Instant desde, Pageable pagina);

  @Query(
      nativeQuery = true,
      value =
          "select coalesce(sum(precio), 0) as ingresos, count(*) as total, coalesce(min(moneda), 'COP') as moneda "
              + "from reserva "
              + "where estado = 'COMPLETADA' and fecha_hora_inicio >= :desde and fecha_hora_inicio < :hasta")
  TotalesProjection obtenerTotales(@Param("desde") Instant desde, @Param("hasta") Instant hasta);

  /** Igual que {@link #obtenerTotales} pero de una sola sucursal (alcance de ADMIN_SUCURSAL). */
  @Query(
      nativeQuery = true,
      value =
          "select coalesce(sum(precio), 0) as ingresos, count(*) as total, coalesce(min(moneda), 'COP') as moneda "
              + "from reserva "
              + "where estado = 'COMPLETADA' and sucursal_id = :sucursalId "
              + "and fecha_hora_inicio >= :desde and fecha_hora_inicio < :hasta")
  TotalesProjection obtenerTotalesDeSucursal(
      @Param("desde") Instant desde,
      @Param("hasta") Instant hasta,
      @Param("sucursalId") UUID sucursalId);

  @Query(
      nativeQuery = true,
      value =
          "select r.servicio_id as servicioId, s.nombre as nombre, count(*) as cantidad "
              + "from reserva r join servicio s on s.id = r.servicio_id "
              + "where r.estado = 'COMPLETADA' and r.sucursal_id = :sucursalId "
              + "and r.fecha_hora_inicio >= :desde and r.fecha_hora_inicio < :hasta "
              + "group by r.servicio_id, s.nombre "
              + "order by cantidad desc "
              + "limit 5")
  List<ServicioPopularProjection> obtenerServiciosMasPedidosDeSucursal(
      @Param("desde") Instant desde,
      @Param("hasta") Instant hasta,
      @Param("sucursalId") UUID sucursalId);

  @Query(
      nativeQuery = true,
      value =
          "select r.servicio_id as servicioId, s.nombre as nombre, count(*) as cantidad "
              + "from reserva r join servicio s on s.id = r.servicio_id "
              + "where r.estado = 'COMPLETADA' and r.fecha_hora_inicio >= :desde and r.fecha_hora_inicio < :hasta "
              + "group by r.servicio_id, s.nombre "
              + "order by cantidad desc "
              + "limit 5")
  List<ServicioPopularProjection> obtenerServiciosMasPedidos(
      @Param("desde") Instant desde, @Param("hasta") Instant hasta);

  interface TotalesProjection {
    BigDecimal getIngresos();

    Long getTotal();

    String getMoneda();
  }

  interface ServicioPopularProjection {
    UUID getServicioId();

    String getNombre();

    Long getCantidad();
  }
}
