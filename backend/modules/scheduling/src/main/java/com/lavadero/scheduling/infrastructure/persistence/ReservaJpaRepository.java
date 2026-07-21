package com.lavadero.scheduling.infrastructure.persistence;

import java.time.Instant;
import java.util.Collection;
import java.util.List;
import java.util.UUID;
import org.springframework.data.jpa.repository.JpaRepository;

/**
 * Repositorio Spring Data. La consulta de solapamiento ({@code inicio < hasta AND fin > desde}, la
 * condición estándar para "estos dos rangos se cruzan") corre en la base de datos, no en memoria:
 * necesario para que la validación de disponibilidad escale con el volumen de reservas.
 */
interface ReservaJpaRepository extends JpaRepository<ReservaJpaEntity, UUID> {

  List<ReservaJpaEntity>
      findBySucursalIdAndEstadoInAndFechaHoraInicioLessThanAndFechaHoraFinGreaterThan(
          UUID sucursalId,
          Collection<String> estados,
          Instant fechaHoraInicioMenorQue,
          Instant fechaHoraFinMayorQue);

  List<ReservaJpaEntity> findBySucursalIdAndFechaHoraInicioBetween(
      UUID sucursalId, Instant desde, Instant hasta);

  List<ReservaJpaEntity> findByClienteId(UUID clienteId);
}
